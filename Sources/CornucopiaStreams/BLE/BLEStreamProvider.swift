//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
#if canImport(CoreBluetooth)
import CoreBluetooth

public protocol BLEStreamProvider {

    var peripheral: CBPeripheral { get }
    var theInputStream: InputStream { get }
    var theOutputStream: OutputStream { get }
}

#endif
