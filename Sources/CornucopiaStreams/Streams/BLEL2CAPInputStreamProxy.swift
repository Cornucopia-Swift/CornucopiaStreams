//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
#if canImport(CoreBluetooth)
import CoreBluetooth

/// This is a ``ProxyInputStream`` for a BLE L2CAP connection.
/// Its solely purpose is to keep the connection alive by holding
/// references to the ``CBCentralManager``, the ``CBPeripheral``, and the ``CBL2CAPChannel``.
final class BLEL2CAPInputStreamProxy: ProxyInputStream {

    let manager: CBCentralManager
    let peripheral: CBPeripheral
    let channel: CBL2CAPChannel

    init?(manager: CBCentralManager, peripheral: CBPeripheral, channel: CBL2CAPChannel) {
        guard let inputStream = channel.inputStream else { return nil }
        self.manager = manager
        self.peripheral = peripheral
        self.channel = channel
        super.init(proxying: inputStream)
    }

#if DEBUG
    deinit {
        print("\(self) destroyed")
    }
#endif
}
#endif
