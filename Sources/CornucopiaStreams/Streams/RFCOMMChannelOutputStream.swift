//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
import CornucopiaCore
#if canImport(IOBluetooth) && !targetEnvironment(macCatalyst)
import IOBluetooth

fileprivate let logger = Cornucopia.Core.Logger()

/// An `OutputStream` bridging to an RFCOMM channel.
public class RFCOMMChannelOutputStream: OutputStream {

    public let bridge: RFCOMMBridge

    public override var streamStatus: Stream.Status { self.status }
    public override var delegate: StreamDelegate? {
        set { self.delega = newValue }
        get { self.delega }
    }

    private var status: Stream.Status = .notOpen
    private weak var delega: StreamDelegate? = nil
    private weak var runLoop: RunLoop?
    private var pendingData: Data? = nil

    init(with bridge: RFCOMMBridge) {
        self.bridge = bridge
        super.init(toMemory: ())
        bridge.outputStream = self
    }

    /// Open the stream.
    public override func open() {
        self.status = .opening
        self.status = .open
        self.reportDelegateEvent(.openCompleted)
        self.reportDelegateEvent(.hasSpaceAvailable)
    }

    /// Write to the stream.
    public override func write(_ buffer: UnsafePointer<UInt8>, maxLength len: Int) -> Int {
        guard self.status == .open else { return -1 }
        guard self.pendingData == nil else { return -1 }
        return self.bridge.write(buffer, maxLength: len)
    }

    /// Close the stream.
    public override func close() {
        self.status = .closed
        self.reportDelegateEvent(.endEncountered)
    }

    public override var hasSpaceAvailable: Bool { self.status == .open }
    public override func schedule(in aRunLoop: RunLoop, forMode mode: RunLoop.Mode) { self.runLoop = aRunLoop }
    public override func remove(from aRunLoop: RunLoop, forMode mode: RunLoop.Mode) { self.runLoop = nil }

#if DEBUG
    deinit {
        print("\(self) destroyed")
    }
#endif
}

internal extension RFCOMMChannelOutputStream {

    func rfcommWriteCompleted() {
        self.reportDelegateEvent(.hasSpaceAvailable)
    }

    func rfcommChannelClosed() {
        self.reportDelegateEvent(.endEncountered)
    }
}

private extension RFCOMMChannelOutputStream {

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
