//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
#if canImport(CoreBluetooth)
import CoreBluetooth
import os.log

fileprivate var log = OSLog(subsystem: "dev.cornucopia.CornucopiaStreams", category: "BLEAccessoryManager")

public class BLEAccessoryManager: NSObject {

    public typealias FindServiceResult = Result<BLEStreamProvider, Stream.PairError>
    public typealias FindServiceResultHandler = (FindServiceResult) -> ()

    let manager: CBCentralManager!
    let desiredService: CBUUID
    let desiredDevice: UUID?
    let l2capPSM: CBL2CAPPSM?
    var resultHandler: FindServiceResultHandler?
    var pendingPeripherals: [UUID: CBPeripheral] = [:]
    var peripheral: CBPeripheral? = nil
    var activeSession: BLEStreamProvider? = nil

    public init(uuid: CBUUID, peer: UUID? = nil, psm: CBL2CAPPSM? = nil, then: @escaping(FindServiceResultHandler)) {

        self.desiredService = uuid
        self.desiredDevice = peer
        self.l2capPSM = psm
        self.resultHandler = then
        self.manager = CBCentralManager()
        super.init()
        self.manager.delegate = self
    }

    public func cancel() {

        self.manager.stopScan()
        self.resultHandler = nil
        self.activeSession = nil
    }
}

extension BLEAccessoryManager: CBCentralManagerDelegate {

    public func centralManagerDidUpdateState(_ central: CBCentralManager) {

        guard case .poweredOn = central.state else { return }

        let connectedPeripherals = self.manager.retrieveConnectedPeripherals(withServices: [self.desiredService])
        connectedPeripherals.forEach {
            self.centralManager(self.manager, didDiscover: $0, advertisementData: [:], rssi: $0.rssi ?? 0.42)
        }
        self.manager.scanForPeripherals(withServices: [self.desiredService], options: nil)
    }

    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        self.pendingPeripherals[peripheral.identifier] = peripheral
        peripheral.delegate = self
        central.connect(peripheral, options: nil)
    }
}

extension BLEAccessoryManager: CBPeripheralDelegate {

    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        if let desiredDevice = self.desiredDevice, peripheral.identifier != desiredDevice { return }
        peripheral.discoverServices([self.desiredService])
    }

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil else {
            self.pendingPeripherals.removeValue(forKey: peripheral.identifier)
            return
        }

        if let l2capPSM = self.l2capPSM {
            peripheral.openL2CAPChannel(l2capPSM)
        } else {
            peripheral.services?.forEach {
                peripheral.discoverCharacteristics(nil, for: $0)
            }
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

        self.manager.stopScan()
        self.peripheral = peripheral
        self.pendingPeripherals.removeValue(forKey: peripheral.identifier)
        let streamProvider = CharacteristicsStreamProvider(forService: service)
        self.activeSession = streamProvider
        let result = FindServiceResult.success(streamProvider)
        self.resultHandler?(result)
    }

    public func peripheral(_ peripheral: CBPeripheral, didOpen channel: CBL2CAPChannel?, error: Error?) {

        self.manager.stopScan()
        self.pendingPeripherals.removeValue(forKey: peripheral.identifier)

        guard error == nil else {
            let result = FindServiceResult.failure(.unableToOpenChannel)
            self.resultHandler?(result)
            return
        }

        self.peripheral = peripheral
        let streamProvider = L2CAPStreamProvider(forChannel: channel!, peripheral: peripheral)
        self.activeSession = streamProvider
        let result = FindServiceResult.success(streamProvider)
        self.resultHandler?(result)
    }

    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        guard self.peripheral == peripheral else { return }
        self.activeSession = nil
    }
}
#endif
