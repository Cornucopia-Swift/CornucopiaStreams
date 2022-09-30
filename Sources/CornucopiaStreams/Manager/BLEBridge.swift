//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
#if canImport(CoreBluetooth)
import CoreBluetooth
import os.log

fileprivate let log = OSLog(subsystem: "de.vanille.Cornucopia.Streams", category: "CharacteristicsStreamProvider")

/// Managing the input/output stream pair for a `CBPeripheral`.
public class BLEBridge: NSObject {

    let service: CBService?
    let channel: CBL2CAPChannel? = nil
    weak var inputStream: BLECharacteristicInputStream!
    weak var outputStream: BLECharacteristicOutputStream!

    public let peripheral: CBPeripheral
    public let manager: CBCentralManager

    /// Create the stream pair for the first applicable `CBCharacteristic` in the specified `CBService`.
    public init(forService service: CBService, manager: CBCentralManager) {
        self.service = service
        self.peripheral = service.peripheral! // fails when gone
        self.manager = manager
        super.init()
        peripheral.delegate = self
    }

    deinit {
#if DEBUG
        print("\(self) destroyed")
#endif
    }
}

extension BLEBridge: CBPeripheralDelegate {

    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        guard characteristic == self.inputStream.characteristic else { fatalError() }
        defer { self.inputStream.bleSubscriptionCompleted(error: error) }
        guard error == nil else {
            os_log("Could not updateNotificationStateForCharacteristic: %@", log: log, type: .error, error! as CVarArg)
            return
        }
        #if TRACE
        os_log("didUpdateNotificationStateForCharacteristic: %@", log: log, type: .debug, characteristic)
        #endif
    }

    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        guard characteristic == self.outputStream.characteristic else { fatalError() }
        guard error == nil else {
            os_log("Could not writeValueForCharacteristic: %@", log: log, type: .error, error! as CVarArg)
            return
        }
        #if TRACE
        os_log("didWriteValueForCharacteristic: %@", log: log, type: .debug, characteristic)
        #endif
        self.outputStream.bleWriteCompleted()
    }

    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard characteristic == self.inputStream.characteristic else { fatalError() }
        defer { self.inputStream.bleReadCompleted(error: error) }
        guard error == nil else {
            os_log("Could not updateValueForCharacteristic: %@", log: log, type: .error, error! as CVarArg)
            return
        }
        #if TRACE
        os_log("didUpdateValueForCharacteristic: %@", log: log, type: .debug, characteristic)
        #endif
    }

    public func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
        guard peripheral == self.peripheral else { fatalError() }
        #if TRACE
        os_log("periperalIsReadyToSendWriteWithoutResponse: %@", log: log, type: .debug, peripheral)
        #endif
        self.outputStream.bleWriteCompleted()
    }
}
#endif
