//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
#if canImport(CoreBluetooth)
import CoreBluetooth

public class CharacteristicOutputStream: OutputStream {

    public let characteristic: CBCharacteristic
    public override var streamStatus: Stream.Status { self.status }
    public override var delegate: StreamDelegate? {
        set { self.delega = newValue }
        get { self.delega }
    }

    private var status: Stream.Status = .notOpen
    private var delega: StreamDelegate? = nil

    init(with characteristic: CBCharacteristic) {

        self.characteristic = characteristic
        super.init(toMemory: ())
    }

    public override func open() {
        self.status = .opening
        self.status = .open
        self.delegate?.stream?(self, handle: .openCompleted)
        self.delegate?.stream?(self, handle: .hasSpaceAvailable)
    }

    public override func write(_ buffer: UnsafePointer<UInt8>, maxLength len: Int) -> Int {
        guard self.status == .open else { return -1 }

        //NOTE: We always prefer `.withResponse`, since the diagnostics for BLE WRITE_REQUEST are better.
        let writeType: CBCharacteristicWriteType = self.characteristic.properties.contains(.write) ? .withResponse : .withoutResponse
        if writeType != .withResponse {
            print("Caution: Using write type WITHOUT response. This is NOT recommended.")
        }
        var maxWriteForCharacteristic = self.characteristic.service.peripheral.maximumWriteValueLength(for: writeType)
        //NOTE: Some BLE 5.0 devices (yes, I'm looking to you, OBDLINK CX) calim to support Queued Writes (see BLE5.0 | Vol 3, Part F,  Section 3.4.6),
        //      which makes CoreBluetooth assume that we can use a pretty high MTU, such as 512. In this case the return values for
        //      peripheral.maximumWriteValueLength(for: .withResponse) ["BLE 5.0 MTU"] and
        //      peripheral.maximumWriteValueLength(for: .withoutResponse) ["BLE 4.x MTU"] differ. In reality though, they don't support
        //      queued writes and thus all attempts to write more than the BLE 4.x MTU leads to lost data.
        //      To be on the safe side, we _always_ have to take the lower value of both APIs. :-(
        #if !BLE_5_DEVICES_BEHAVE_CORRECTLY
        maxWriteForCharacteristic = min(
            self.characteristic.service.peripheral.maximumWriteValueLength(for: .withResponse),
            self.characteristic.service.peripheral.maximumWriteValueLength(for: .withoutResponse)
            )
        #endif
        let bytesToWrite = min(maxWriteForCharacteristic, len)
        let data = Data(bytes: buffer, count: bytesToWrite)
        //FIXME: If we're writing without response, we could add a check here to see whether we can actually send before attempting to write
        self.characteristic.service.peripheral.writeValue(data, for: self.characteristic, type: writeType)
        return bytesToWrite
    }

    public override func close() {
        self.status = .closed
        self.delegate?.stream?(self, handle: .endEncountered)
    }

    public override var hasSpaceAvailable: Bool { self.status == .open }
    public override func schedule(in aRunLoop: RunLoop, forMode mode: RunLoop.Mode) { }
    public override func remove(from aRunLoop: RunLoop, forMode mode: RunLoop.Mode) { }
}

internal extension CharacteristicOutputStream {

    func bleWriteCompleted() {
        self.delegate?.stream?(self, handle: .hasSpaceAvailable)
    }

    func bleDisconnected() {
        self.delegate?.stream?(self, handle: .endEncountered)
    }
}
#endif

