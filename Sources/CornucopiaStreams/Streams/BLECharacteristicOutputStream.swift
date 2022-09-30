//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
#if canImport(CoreBluetooth)
import CoreBluetooth
import os.log

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

        //NOTE: We always prefer `.withResponse`, since the diagnostics for BLE WRITE_REQUEST are better.
        let writeType: CBCharacteristicWriteType = self.characteristic.properties.contains(.write) ? .withResponse : .withoutResponse
        if writeType != .withResponse && !didOutputWriteTypeWarning {
            os_log("Using BLE write type WITHOUT response (not recommended)", log: OSLog.default, type: .info)
            didOutputWriteTypeWarning = true
        }
        var maxWriteForCharacteristic = peripheral.maximumWriteValueLength(for: writeType)
        //NOTE: Some BLE 5.0 devices (yes, I'm looking to you, OBDLINK CX) calim to support Queued Writes (see BLE5.0 | Vol 3, Part F,  Section 3.4.6),
        //      which makes CoreBluetooth assume that we can use a pretty high MTU, such as 512. In this case the return values for
        //      peripheral.maximumWriteValueLength(for: .withResponse) ["BLE 5.0 MTU"] and
        //      peripheral.maximumWriteValueLength(for: .withoutResponse) ["BLE 4.x MTU"] differ. In reality though, they don't support
        //      queued writes and thus all attempts to write more than the BLE 4.x MTU leads to lost data.
        //      To be on the safe side, we _always_ have to take the lower value of both APIs. :-(
        #if !BLE_5_DEVICES_BEHAVE_CORRECTLY
        maxWriteForCharacteristic = min(
            peripheral.maximumWriteValueLength(for: .withResponse),
            peripheral.maximumWriteValueLength(for: .withoutResponse)
            )
        #endif
        let bytesToWrite = min(maxWriteForCharacteristic, len)
        let data = Data(bytes: buffer, count: bytesToWrite)
        //FIXME: If we're writing without response, we could add a check here to see whether we can actually send before attempting to write
        peripheral.writeValue(data, for: self.characteristic, type: writeType)
        return bytesToWrite
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
