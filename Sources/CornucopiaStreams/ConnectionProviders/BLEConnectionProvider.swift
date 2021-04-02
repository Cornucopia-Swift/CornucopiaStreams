//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
#if canImport(CoreBluetooth)
import Foundation
import CoreBluetooth

public extension Stream {

    class BLEConnection: Connection {

        static let forbiddenCharsetCBUUID4 = CharacterSet(charactersIn: "0123456789ABCDEF").inverted
        static let forbiddenCharsetCBUUID6 = CharacterSet(charactersIn: "0123456789ABCDEF-").inverted

        var uuid: CBUUID!
        weak var peripheral: CBPeripheral?

        public override func setup() {

            guard let service = self.url.host else {
                self.failWith(error: .invalidParameters)
                return
            }
            switch service.count {
                case 4:
                    guard service.rangeOfCharacter(from: Self.forbiddenCharsetCBUUID4) == nil else {
                        self.failWith(error: .invalidParameters)
                        return
                    }
                    uuid = CBUUID(string: service)
                case 6:
                    guard service.rangeOfCharacter(from: Self.forbiddenCharsetCBUUID6) == nil else {
                        self.failWith(error: .invalidParameters)
                        return
                    }
                    uuid = CBUUID(string: service)
                default:
                    self.failWith(error: .invalidParameters)
            }

            BLEAccessoryManager.shared.findService(with: self.uuid) { result in
                switch result {
                    case .success(let streams):
                        self.meta.name = streams.peripheral.name ?? ""
                        self.succeedWith(istream: streams.inputStream, ostream: streams.outputStream)
                    case .failure(let error):
                        self.failWith(error: error)
                }
            }
        }

        public override func cancel() {
            BLEAccessoryManager.shared.cancelFind(with: self.uuid)
        }

    }
}
#endif
