//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
#if canImport(CoreBluetooth)
import CoreBluetooth

public class L2CAPStreamProvider: BLEStreamProvider {

    public let peripheral: CBPeripheral
    public var theInputStream: InputStream { channel.inputStream }
    public var theOutputStream: OutputStream { channel.outputStream }

    let channel: CBL2CAPChannel

    init(forChannel channel: CBL2CAPChannel, peripheral: CBPeripheral) {
        self.peripheral = peripheral
        self.channel = channel
    }
}

#endif
