//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
#if canImport(CoreBluetooth)
import Foundation
import CoreBluetooth

public extension Stream {

    /// Handling a connection to a Bluetooth Low Energy peripheral.
    class BLEConnection: Connection {

        static let forbiddenCharsetCBUUID4 = CharacterSet(charactersIn: "0123456789ABCDEF").inverted
        static let forbiddenCharsetCBUUID6 = CharacterSet(charactersIn: "0123456789ABCDEF-").inverted
        static let numberOfCharactersForPeerUUID = 36

        var accessoryManager: BLEAccessoryManager?
        var uuid: CBUUID!
        var peer: UUID?

        public override func setup() {

            guard let service = self.url.host?.uppercased() else { return self.failWith(error: .invalidParameters) }
            if self.url.path.count == Self.numberOfCharactersForPeerUUID + 1 {
                let uuidString = String(self.url.path.dropFirst())
                guard let peer = UUID(uuidString: uuidString) else { return self.failWith(error: .invalidParameters) }
                self.peer = peer
            }

            switch service.count {
                case 4:
                    guard service.rangeOfCharacter(from: Self.forbiddenCharsetCBUUID4) == nil else { return self.failWith(error: .invalidParameters) }
                    uuid = CBUUID(string: service)
                case 6, 36:
                    guard service.rangeOfCharacter(from: Self.forbiddenCharsetCBUUID6) == nil else { return self.failWith(error: .invalidParameters) }
                    uuid = CBUUID(string: service)
                default:
                    return self.failWith(error: .invalidParameters)
            }

            self.accessoryManager = BLEAccessoryManager(uuid: self.uuid, peer: self.peer) { result in
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
            self.accessoryManager?.cancel()
        }
    }
}
#endif
