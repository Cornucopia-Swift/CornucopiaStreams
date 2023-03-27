//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
#if canImport(CoreBluetooth)
import CoreBluetooth

public class BLECharacteristicInputStream: InputStream {

    fileprivate var incoming: [UInt8] = []
    public let characteristic: CBCharacteristic
    public let bridge: BLEBridge

    public override var streamStatus: Stream.Status { self.status }
    public override var delegate: StreamDelegate? {
        set { self.delega = newValue }
        get { self.delega }
    }
    private var status: Stream.Status = .notOpen
    private weak var delega: StreamDelegate? = nil
    private weak var runLoop: RunLoop?
    private var dummySource: CFRunLoopSource? = nil

    init(with characteristic: CBCharacteristic, bridge: BLEBridge) {
        self.characteristic = characteristic
        self.bridge = bridge
        super.init(data: Data())
        bridge.inputStream = self
    }

    public override func open() {
        self.status = .opening
        guard let peripheral = self.characteristic.service?.peripheral else {
            self.status = .error
            return
        }
        peripheral.setNotifyValue(true, for: self.characteristic)
        //NOTE: Open is asynchronous, the control flow will continue (eventually) in `bleSubscriptionCompleted`
    }

    public override func close() {
        self.status = .closed
        if let peripheral = self.characteristic.service?.peripheral {
            peripheral.setNotifyValue(false, for: self.characteristic)
        }
        self.reportDelegateEvent(.endEncountered)
    }

    public override func read(_ buffer: UnsafeMutablePointer<UInt8>, maxLength len: Int) -> Int {
        guard self.status == .open else { return -1 }
        let numberOfBytesToRead = min(self.incoming.count, len)
        guard numberOfBytesToRead > 0 else { return 0 }

        _ = self.incoming.withUnsafeBufferPointer { pointer in
            memcpy(buffer, pointer.baseAddress, numberOfBytesToRead)
        }
        self.incoming.removeFirst(numberOfBytesToRead)

        /*
        let range = 0..<numberOfBytesToRead
        self.incoming.copyBytes(to: buffer, from: range)
        _ = self.incoming.dropFirst(numberOfBytesToRead)
        //self.incoming = self.incoming.subdata(in: numberOfBytesToRead..<self.incoming.count)
        //self.incoming.removeFirst(numberOfBytesToRead) EXC_BREAKPOINT?
        */
        return numberOfBytesToRead
    }

    public override var hasBytesAvailable: Bool { self.status == .open && !self.incoming.isEmpty }

    public override func getBuffer(_ buffer: UnsafeMutablePointer<UnsafeMutablePointer<UInt8>?>, length len: UnsafeMutablePointer<Int>) -> Bool { false }
    public override func schedule(in aRunLoop: RunLoop, forMode mode: RunLoop.Mode) {
        self.dummySource = CFRunLoopSource.CC_dummy()
        aRunLoop.CC_addSource(self.dummySource!)
        self.runLoop = aRunLoop
    }
    public override func remove(from aRunLoop: RunLoop, forMode mode: RunLoop.Mode) {
        self.runLoop = nil
        aRunLoop.CC_removeSource(self.dummySource!)
        self.dummySource = nil
    }

#if DEBUG
    deinit {
        print("\(self) destroyed")
    }
#endif
}

internal extension BLECharacteristicInputStream {

    func bleSubscriptionCompleted(error: Error?) {
        guard error == nil else {
            self.status = .error
            self.reportDelegateEvent(.errorOccurred)
            return
        }
        self.status = .open
        self.reportDelegateEvent(.openCompleted)
        //FIXME: Should we try to read to find out whether there are already bytes lurking in the lowlevel buffer?
        //self.characteristic.service.peripheral.readValue(for: self.characteristic)
    }

    func bleReadCompleted(error: Error?) {
        guard error == nil else {
            self.reportDelegateEvent(.errorOccurred)
            return
        }

        let block = {
            guard let data = self.characteristic.value else { return }
            self.incoming += data
            self.reportDelegateEvent(.hasBytesAvailable)
        }
        // If the client did not schedule a ``RunLoop``, we just call it on the current calling context.
        guard let runloop = self.runLoop else {
            block()
            return
        }
        runloop.perform(block)
    }

    func bleDisconnected() {
        self.reportDelegateEvent(.endEncountered)
    }
}

private extension BLECharacteristicInputStream {

    func reportDelegateEvent(_ event: Stream.Event) {
        guard let runloop = self.runLoop else {
            self.delegate?.stream?(self, handle: event)
            return
        }
        runloop.perform {
            self.delegate?.stream?(self, handle: event)
        }
    }
}
#endif
