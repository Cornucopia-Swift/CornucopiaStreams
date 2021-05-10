//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
#if canImport(CoreBluetooth)
import CoreBluetooth
import os.log

fileprivate var log = OSLog(subsystem: "dev.cornucopia.CornucopiaStreams", category: "BLEAccessoryManager")

public class BLEAccessoryManager: NSObject {

    public typealias FindServiceResult = Result<CharacteristicsStreamProvider, Stream.PairError>
    public typealias FindServiceResultHandler = (FindServiceResult) -> ()

    public static let shared: BLEAccessoryManager = BLEAccessoryManager()

    let manager: CBCentralManager!
    var pendingConnections: [CBUUID: FindServiceResultHandler] = [:]
    var pendingPeripherals: [UUID: CBPeripheral] = [:]
    var activeSessions: [UUID: CharacteristicsStreamProvider] = [:]

    override private init() {

        self.manager = CBCentralManager()
        super.init()

        self.manager.delegate = self
    }

    public func findService(with uuid: CBUUID, then: @escaping(FindServiceResultHandler)) {

        guard case .poweredOn = self.manager.state else {
            self.pendingConnections[uuid] = then
            return
        }
        self.startScanning()
    }

    public func cancelFind(with uuid: CBUUID) {

        self.pendingConnections.removeValue(forKey: uuid)
        guard self.pendingConnections.isEmpty else { return }
        self.stopScanning()
    }
}

private extension BLEAccessoryManager {

    func startScanning() {
        let serviceUUIDs: [CBUUID] = self.pendingConnections.keys.map { $0 as CBUUID }
        let connectedPeripherals = self.manager.retrieveConnectedPeripherals(withServices: serviceUUIDs)
        connectedPeripherals.forEach {
            self.centralManager(self.manager, didDiscover: $0, advertisementData: [:], rssi: $0.rssi ?? 0.42)
        }
        self.manager.scanForPeripherals(withServices: serviceUUIDs, options: nil)
    }

    func stopScanning() {
        self.manager.stopScan()
    }
}

extension BLEAccessoryManager: CBCentralManagerDelegate {

    public func centralManagerDidUpdateState(_ central: CBCentralManager) {

        guard case .poweredOn = central.state else { return }
        guard !self.pendingConnections.isEmpty else { return }
        self.startScanning()
    }

    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        self.pendingPeripherals[peripheral.identifier] = peripheral
        peripheral.delegate = self
        central.connect(peripheral, options: nil)
    }
}

extension BLEAccessoryManager: CBPeripheralDelegate {

    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        let serviceUUIDs: [CBUUID] = self.pendingConnections.keys.map { $0 as CBUUID }
        peripheral.discoverServices(serviceUUIDs)
    }

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil else {
            self.pendingPeripherals.removeValue(forKey: peripheral.identifier)
            return
        }
        peripheral.services?.forEach {
            peripheral.discoverCharacteristics(nil, for: $0)
        }
    }

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil else {
            self.pendingPeripherals.removeValue(forKey: peripheral.identifier)
            return
        }

        let rc = service.characteristics?.first { $0.properties.contains(.notify) || $0.properties.contains(.indicate) }
        let wc = service.characteristics?.first { $0.properties.contains(.write) || $0.properties.contains(.writeWithoutResponse) }
        guard rc != nil, wc != nil else {
            return
        }

        self.pendingPeripherals.removeValue(forKey: peripheral.identifier)
        let streamProvider = CharacteristicsStreamProvider(forService: service)
        self.activeSessions[peripheral.identifier] = streamProvider

        guard let handler = self.pendingConnections.removeValue(forKey: service.uuid) else {
            os_log("Did discover characteristics for service %@, but there is no pending connection for this UUID anymore.", service.uuid.description)
            return
        }
        let result = FindServiceResult.success(streamProvider)
        handler(result)

        if self.pendingConnections.isEmpty {
            self.manager.stopScan()
        }
    }

    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        guard let streamProvider = self.activeSessions[peripheral.identifier] else { return }
        self.activeSessions.removeValue(forKey: peripheral.identifier)
    }
}
#endif
