//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
#if canImport(CoreBluetooth)
import CoreBluetooth
import os.log

fileprivate let log = OSLog(subsystem: "de.vanille.Cornucopia.Streams", category: "CharacteristicsStreamProvider")

/// Managing the input/output stream pair for a `CBPeripheral`.
public class CharacteristicsStreamProvider: NSObject, BLEStreamProvider, CBPeripheralDelegate {

    let service: CBService?
    let channel: CBL2CAPChannel? = nil
    let inputStream: CharacteristicInputStream!
    let outputStream: CharacteristicOutputStream!

    public let peripheral: CBPeripheral
    public var theInputStream: InputStream { self.inputStream as InputStream }
    public var theOutputStream: OutputStream { self.outputStream as OutputStream }

    /// Create the stream pair for the first applicable `CBCharacteristic` in the specified `CBService`.
    public init(forService service: CBService) {
        self.service = service
        self.peripheral = service.peripheral! // fails when gone

        let readCharacteristic = service.characteristics?.first { $0.properties.contains(.notify) || $0.properties.contains(.indicate) }
        let writeCharacteristic = service.characteristics?.first { $0.properties.contains(.write) || $0.properties.contains(.writeWithoutResponse) }

        guard let input = readCharacteristic else { fatalError("NOTIFY characteristic not found in \(service)") }
        guard let output = writeCharacteristic else { fatalError("WRITE characteristic not found in \(service)") }

        self.inputStream = CharacteristicInputStream(with: input)
        self.outputStream = CharacteristicOutputStream(with: output)

        super.init()

        peripheral.delegate = self
    }

    deinit {
        self.inputStream.bleDisconnected()
        self.outputStream.bleDisconnected()
    }

    //MARK: - <CBPeripheralDelegate>

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
