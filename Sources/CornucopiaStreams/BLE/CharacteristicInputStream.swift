//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
#if canImport(CoreBluetooth)
import CoreBluetooth

public class CharacteristicInputStream: InputStream {

    fileprivate var incoming = Data()
    public let characteristic: CBCharacteristic

    public override var streamStatus: Stream.Status { self.status }
    public override var delegate: StreamDelegate? {
        set { self.delega = newValue }
        get { self.delega }
    }
    private var status: Stream.Status = .notOpen
    private var delega: StreamDelegate? = nil
    private weak var runLoop: RunLoop?

    init(with characteristic: CBCharacteristic) {
        self.characteristic = characteristic
        super.init(data: Data())
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
        let range = 0..<numberOfBytesToRead
        self.incoming.copyBytes(to: buffer, from: range)
        self.incoming = self.incoming.subdata(in: numberOfBytesToRead..<self.incoming.count)
        //self.incoming.removeFirst(numberOfBytesToRead) EXC_BREAKPOINT?
        return numberOfBytesToRead
    }

    public override var hasBytesAvailable: Bool { self.status == .open && !self.incoming.isEmpty }

    public override func getBuffer(_ buffer: UnsafeMutablePointer<UnsafeMutablePointer<UInt8>?>, length len: UnsafeMutablePointer<Int>) -> Bool { false }
    public override func schedule(in aRunLoop: RunLoop, forMode mode: RunLoop.Mode) { self.runLoop = aRunLoop }
    public override func remove(from aRunLoop: RunLoop, forMode mode: RunLoop.Mode) { self.runLoop = nil }
}

internal extension CharacteristicInputStream {

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
        guard let data = self.characteristic.value else { return }
        self.incoming.append(data)
        self.reportDelegateEvent(.hasBytesAvailable)
    }

    func bleDisconnected() {
        self.reportDelegateEvent(.hasBytesAvailable)
        self.reportDelegateEvent(.endEncountered)
    }
}

private extension CharacteristicInputStream {

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
