//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
#if canImport(ExternalAccessory)
import ExternalAccessory.EASession

public enum AccessoryError: Error {
    case noAccessoriesPresent
    case accessoryNotFound(String)
    case sessionSetupError
}

public extension EASession {

    static func CC_establishToFirstSupportedDevice(supportingProtocol: String? = nil) throws -> (EASession) {

        let connectedAccessories = EAAccessoryManager.shared().connectedAccessories
        guard !connectedAccessories.isEmpty else { throw AccessoryError.noAccessoriesPresent }

        let proto = supportingProtocol ?? {
            guard let array: [String] = Bundle.main.object(forInfoDictionaryKey: "UISupportedExternalAccessoryProtocols") as? [String] else { fatalError("Info.plist: UISupportedExternalAccessoryProtocols not present") }
            guard let string = array.first else { fatalError("Info.plist: UISupportedExternalAccessoryProtocols is present, but empty") }
            return string
        }()

        print("Looking for protocol \(proto)...")

        let connectedAccessory = connectedAccessories.first { $0.protocolStrings.contains(proto) }
        guard connectedAccessory != nil else { throw AccessoryError.accessoryNotFound(proto) }

        guard let session = Self.init(accessory: connectedAccessory!, forProtocol: proto) else { throw AccessoryError.sessionSetupError }
        return session
    }

}
#endif
