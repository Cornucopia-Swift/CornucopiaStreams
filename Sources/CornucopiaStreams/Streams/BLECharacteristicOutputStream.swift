//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
import CornucopiaCore
#if canImport(CoreBluetooth)
import CoreBluetooth

fileprivate let logger = Cornucopia.Core.Logger()

/// An `OutputStream` bridging to a BLE characteristic.
public class BLECharacteristicOutputStream: OutputStream {

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
    private var didOutputWriteTypeWarning: Bool = false
    private var pendingData: Data? = nil

    init(with characteristic: CBCharacteristic, bridge: BLEBridge) {
        self.characteristic = characteristic
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
        guard let peripheral = self.characteristic.service?.peripheral else { return -1 }
        guard self.pendingData == nil else { return -1 }
        // So here's the deal with our preference to .withoutResponse:
        // While iOS correctly reports the "native" MTU when questing the
        // `peripheral.maximumWriteValueLength(for: .withoutResponse)`,
        // it unconditionally(!) returns 512 as the MTU for
        // `peripheral.maximumWriteValueLength(for: .withResponse)`, which is
        // the maximum allowed MTU as per the spec. However, for this to work
        // the device needs to support Queued Writes (see BLE5.0 | Vol 3, Part F,  Section 3.4.6),
        // which not all BLE 5 devices do (Yes I'm looking at you OBDLink CX).
        // If you try to use this MTU on a device that does not supported Queued Writes, you
        // will encounter bytes being dropped and transfers stalling.
        let writeType: CBCharacteristicWriteType = self.characteristic.properties.contains(.writeWithoutResponse) ? .withoutResponse : .withResponse
        if writeType == .withResponse && !didOutputWriteTypeWarning {
            logger.info("Using BLE write type .withResponse (not recommended)")
            didOutputWriteTypeWarning = true
        }
        let maxWriteForCharacteristic = peripheral.maximumWriteValueLength(for: writeType)
        let bytesToWrite = min(maxWriteForCharacteristic, len)
        let data = Data(bytes: buffer, count: bytesToWrite)

        switch writeType {
            case .withResponse:
                peripheral.writeValue(data, for: self.characteristic, type: writeType)
                return bytesToWrite

            case .withoutResponse:
                if peripheral.canSendWriteWithoutResponse {
                    peripheral.writeValue(data, for: self.characteristic, type: writeType)
                    return bytesToWrite
                } else {
                    logger.trace("Can not send yet… queuing for later")
                    self.pendingData = data
                    return bytesToWrite
                }

            @unknown default:
                fatalError("Unexpected write type \(writeType)")
        }
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

internal extension BLECharacteristicOutputStream {

    func bleReadyToWriteWithoutResponse() {
        guard let data = self.pendingData else {
            self.reportDelegateEvent(.hasSpaceAvailable)
            return
        }
        guard let peripheral = self.characteristic.service?.peripheral else {
            logger.debug("Got BLE readyToWriteWithoutResponse, but peripheral is already gone")
            return
        }
        defer { self.pendingData = nil }
        peripheral.writeValue(data, for: self.characteristic, type: .withoutResponse)
    }

    func bleWriteCompleted() {
        self.reportDelegateEvent(.hasSpaceAvailable)
    }

    func bleDisconnected() {
        self.reportDelegateEvent(.endEncountered)
    }
}

private extension BLECharacteristicOutputStream {

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
