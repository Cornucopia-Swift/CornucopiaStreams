//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
import CornucopiaCore
#if canImport(CoreBluetooth)
import CoreBluetooth

fileprivate let logger = Cornucopia.Core.Logger()

/// Managing the input/output stream pair for a ``CBPeripheral``.
public final class BLEBridge: NSObject {

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

#if DEBUG
    deinit {
        logger.debug("\(self) destroyed")
    }
#endif
}

extension BLEBridge: CBPeripheralDelegate {

    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        guard let inputStream, characteristic == inputStream.characteristic else {
            logger.debug("Ignoring didUpdateNotificationStateFor for unexpected or released input stream")
            return
        }
        defer { inputStream.bleSubscriptionCompleted(error: error) }
        guard error == nil else {
            logger.debug("Could not updateNotificationStateForCharacteristic: \(error!)")
            return
        }
        logger.trace("didUpdateNotificationStateForCharacteristic: \(characteristic)")
    }

    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let outputStream, characteristic == outputStream.characteristic else {
            logger.debug("Ignoring didWriteValueFor for unexpected or released output stream")
            return
        }
        guard error == nil else {
            logger.debug("Could not writeValueForCharacteristic: \(error!)")
            return
        }
        logger.trace("didWriteValueForCharacteristic: \(characteristic)")
        outputStream.bleWriteCompleted()
    }

    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let inputStream, characteristic == inputStream.characteristic else {
            logger.debug("Ignoring didUpdateValueFor for unexpected or released input stream")
            return
        }
        defer { inputStream.bleReadCompleted(error: error) }
        guard error == nil else {
            logger.debug("Could not updateValueForCharacteristic: \(error!)")
            return
        }
        logger.trace("didUpdateValueForCharacteristic: \(characteristic)")
    }

    public func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
        guard peripheral == self.peripheral else {
            logger.debug("Ignoring ready-to-write callback from unexpected peripheral \(peripheral)")
            return
        }
        logger.trace("periperalIsReadyToSendWriteWithoutResponse: \(peripheral)")
        self.outputStream?.bleReadyToWriteWithoutResponse()
    }
}
#endif
