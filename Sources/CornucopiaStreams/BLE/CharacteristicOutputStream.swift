//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
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
        print("MTU reported as \(maxWriteForCharacteristic)")
        //NOTE: The return value of `maxWriteForCharacteristic(for: .writeWithResponse)` seems to be a bland, outright, LIE!
        //      A BLE sniff shows that although iOS and my peripheral negotiate an MTU of 247:
        //      peripheral.maximumWriteValueLength(for: .withResponse) = 512 <- WRONG
        //      peripheral.maximumWriteValueLength(for: .withoutResponse) = 244 <- CORRECT
        //      -- Reported on 2021.03.22 as FB9050731
        #if false
        maxWriteForCharacteristic = min(
            self.characteristic.service.peripheral.maximumWriteValueLength(for: .withResponse),
            self.characteristic.service.peripheral.maximumWriteValueLength(for: .withoutResponse)
            )
        #endif
        let bytesToWrite = min(maxWriteForCharacteristic, len)
        let data = Data(bytes: buffer, count: bytesToWrite)
        //FIXME: If we're writing without response, add a check here whether we can actually send before attempting to write
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
