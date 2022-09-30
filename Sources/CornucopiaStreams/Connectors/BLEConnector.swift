//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
#if canImport(CoreBluetooth)
import CornucopiaCore
import CoreBluetooth
import OSLog
import Foundation

fileprivate let log = OSLog(subsystem: "BLEConnection", category: "ConnectionHandling")

extension Cornucopia.Streams {

    /// A connector for Bluetooth Low Energy devices.
    class BLEConnector: BaseConnector {

        static let forbiddenCharsetCBUUID4 = CharacterSet(charactersIn: "0123456789ABCDEF").inverted
        static let forbiddenCharsetCBUUID6 = CharacterSet(charactersIn: "0123456789ABCDEF-").inverted
        static let numberOfCharactersForPeerUUID = 36

        typealias ConnectionContinuation = CheckedContinuation<StreamPair, Swift.Error>
        var continuation: ConnectionContinuation? = nil

        var service: CBUUID!
        var peer: UUID? = nil
        var psm: CBL2CAPPSM? = nil

        var manager: CBCentralManager!
        var peripherals: [UUID: CBPeripheral] = [:]
        var peripheral: CBPeripheral? = nil

        override func connect() async throws -> Cornucopia.Streams.StreamPair {

            let url = self.meta.url
            guard let serviceUUID = url.host?.uppercased() else { throw Error.invalidUrl }
            if url.path.count == Self.numberOfCharactersForPeerUUID + 1 {
                let uuidString = String(url.path.dropFirst())
                guard let peer = UUID(uuidString: uuidString) else { throw Error.invalidUrl }
                self.peer = peer
            }

            switch serviceUUID.count {
                case 4:
                    guard serviceUUID.rangeOfCharacter(from: Self.forbiddenCharsetCBUUID4) == nil else { throw Error.invalidUrl }
                    self.service = CBUUID(string: serviceUUID)
                case 6, 36:
                    guard serviceUUID.rangeOfCharacter(from: Self.forbiddenCharsetCBUUID6) == nil else { throw Error.invalidUrl }
                    self.service = CBUUID(string: serviceUUID)
                default:
                    throw Error.invalidUrl
            }
            if let port = url.port {
                self.psm = CBL2CAPPSM(port)
            }
            return try await withCheckedThrowingContinuation { c in
                self.continuation = c
                self.manager = CBCentralManager()
                self.manager.delegate = self
            }
        }
#if DEBUG
        deinit {
            print("\(self) destroyed")
        }
#endif
    }
}
#endif

extension Cornucopia.Streams.BLEConnector: CBCentralManagerDelegate {

    func centralManagerDidUpdateState(_ central: CBCentralManager) {

        guard case .poweredOn = central.state else { return }

        let connectedPeripherals = self.manager.retrieveConnectedPeripherals(withServices: [self.service])
        connectedPeripherals.forEach {
            self.centralManager(central, didDiscover: $0, advertisementData: [:], rssi: $0.rssi ?? 0.42)
        }
        central.scanForPeripherals(withServices: [self.service], options: nil)
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        self.peripherals[peripheral.identifier] = peripheral
        central.connect(peripheral, options: nil)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        if let peer = self.peer, peripheral.identifier != peer { return }
        peripheral.delegate = self
        peripheral.discoverServices([self.service])
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        guard error == nil else {
            self.peripherals.removeValue(forKey: peripheral.identifier)
            return
        }
    }
}

extension Cornucopia.Streams.BLEConnector: CBPeripheralDelegate {

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil else {
            self.peripherals.removeValue(forKey: peripheral.identifier)
            return
        }

        if let psm = self.psm {
            peripheral.openL2CAPChannel(psm)
        } else {
            peripheral.services?.forEach {
                peripheral.discoverCharacteristics(nil, for: $0)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil else {
            self.peripherals.removeValue(forKey: peripheral.identifier)
            return
        }
        guard let rc = service.characteristics?.first(where: { $0.properties.contains(.notify) || $0.properties.contains(.indicate) }) else {
            if service == peripheral.services?.last {
                self.peripherals.removeValue(forKey: peripheral.identifier)
            }
            return
        }
        guard let wc = service.characteristics?.first(where: { $0.properties.contains(.write) || $0.properties.contains(.writeWithoutResponse) }) else {
            if service == peripheral.services?.last {
                self.peripherals.removeValue(forKey: peripheral.identifier)
            }
            return
        }
        self.manager.stopScan()
        self.peripherals.removeAll()
        self.peripheral = peripheral

        guard let continuation = self.continuation else {
            os_log("Ignoring successful didDiscoverCharacteristics open without continuation", log: log)
            return
        }

        let bridge = BLEBridge(forService: service, manager: self.manager)
        let inputStream = BLECharacteristicInputStream(with: rc, bridge: bridge)
        let outputStream = BLECharacteristicOutputStream(with: wc, bridge: bridge)
        self.installMetaData(for: peripheral, inputStream: inputStream, outputStream: outputStream)
        continuation.resume(returning: (inputStream, outputStream))
        self.continuation = nil
    }

    func peripheral(_ peripheral: CBPeripheral, didOpen channel: CBL2CAPChannel?, error: Error?) {
        guard error == nil else {
            self.peripherals.removeValue(forKey: peripheral.identifier)
            return
        }
        guard let channel = channel else {
            self.peripherals.removeValue(forKey: peripheral.identifier)
            return
        }
        guard let continuation = self.continuation else {
            os_log("Ignoring successful L2CAP channel open without continuation", log: log)
            return
        }
        guard let inputStream = channel.inputStream else {
            continuation.resume(throwing: Cornucopia.Streams.Error.unableToConnect("L2CAP Channel opened, but input stream is nil"))
            self.continuation = nil
            return
        }
        guard let outputStream = channel.outputStream else {
            continuation.resume(throwing: Cornucopia.Streams.Error.unableToConnect("L2CAP Channel opened, but output stream is nil"))
            self.continuation = nil
            return
        }
        self.manager.stopScan()
        self.peripherals.removeAll()
        self.peripheral = peripheral

        self.installMetaData(for: peripheral, inputStream: inputStream, outputStream: outputStream)
        continuation.resume(returning: (inputStream, outputStream))
        self.continuation = nil
    }
}

private extension Cornucopia.Streams.BLEConnector {

    func installMetaData(for peripheral: CBPeripheral, inputStream: InputStream, outputStream: OutputStream) {
        self.meta.name = peripheral.name ?? peripheral.identifier.uuidString
        inputStream.CC_storeMeta(self.meta)
        outputStream.CC_storeMeta(self.meta)
    }
}
