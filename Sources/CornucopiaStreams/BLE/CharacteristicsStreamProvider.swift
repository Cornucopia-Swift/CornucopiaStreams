//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
import CoreBluetooth

public class CharacteristicsStreamProvider: NSObject, CBPeripheralDelegate {

    let peripheral: CBPeripheral
    let service: CBService
    public let inputStream: CharacteristicInputStream!
    public let outputStream: CharacteristicOutputStream!

    public init(forService service: CBService) {
        self.service = service
        self.peripheral = service.peripheral

        let readCharacteristic = service.characteristics?.first { $0.properties.contains(.notify) || $0.properties.contains(.indicate) }
        let writeCharacteristic = service.characteristics?.first { $0.properties.contains(.write) || $0.properties.contains(.writeWithoutResponse) }

        guard let input = readCharacteristic else { fatalError("NOTIFY characteristic not found in \(service)") }
        guard let output = writeCharacteristic else { fatalError("WRITE characteristic not found in \(service)") }

        self.inputStream = CharacteristicInputStream(with: input)
        self.outputStream = CharacteristicOutputStream(with: output)

        self.inputStream.CC_name = readCharacteristic?.service.peripheral.name

        super.init()

        peripheral.delegate = self
    }

    deinit {
        self.inputStream.bleDisconnected()
        self.outputStream.bleDisconnected()
    }

    //MARK: - <CBPeripheralDelegate>

    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        print("didWriteValue for \(characteristic)")
        guard characteristic == self.outputStream.characteristic else { fatalError() }
        self.outputStream.bleWriteCompleted()
    }

    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        print("didUpdateValue for \(characteristic)")
        guard characteristic == self.inputStream.characteristic else { fatalError() }
        self.inputStream.bleReadCompleted()
    }

    public func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
        print("didWriteWithoutResponse for \(peripheral)")
        guard peripheral == self.peripheral else { fatalError() }
        self.outputStream.bleWriteCompleted()
    }
}
