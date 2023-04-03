//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
#if canImport(IOBluetooth) && !targetEnvironment(macCatalyst)
import IOBluetooth

/// An ``InputStream`` that gets its data via Bluetooth RFCOMM.
public class RFCOMMChannelInputStream: InputStream {

    fileprivate var incoming = Data()
    public let bridge: RFCOMMBridge

    public override var streamStatus: Stream.Status { self.status }
    public override var delegate: StreamDelegate? {
        set { self.delega = newValue }
        get { self.delega }
    }
    private var status: Stream.Status = .notOpen
    private weak var delega: StreamDelegate? = nil
    private weak var runLoop: RunLoop?
    private var dummySource: CFRunLoopSource? = nil

    init(with bridge: RFCOMMBridge) {
        self.bridge = bridge
        super.init(data: Data())
        bridge.inputStream = self
    }

    public override func open() {
        self.status = .opening
        self.bridge.openChannel()
        //NOTE: Open is asynchronous, the control flow will continue (eventually) in `rfcommChannelOpenCompleted`
    }

    public override func close() {
        self.status = .closed
        self.bridge.closeChannel()
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

internal extension RFCOMMChannelInputStream {

    func rfcommChannelOpenComplete(result: IOReturn) {
        guard result == kIOReturnSuccess else {
            self.status = .error
            self.reportDelegateEvent(.errorOccurred)
            return
        }
        self.status = .open
        self.reportDelegateEvent(.openCompleted)
    }

    func rfcommChannelIncomingData(_ data: Data) {
        self.incoming.append(data)
        self.reportDelegateEvent(.hasBytesAvailable)
    }

    func rfcommChannelClosed() {
        self.reportDelegateEvent(.endEncountered)
    }
}

private extension RFCOMMChannelInputStream {

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
