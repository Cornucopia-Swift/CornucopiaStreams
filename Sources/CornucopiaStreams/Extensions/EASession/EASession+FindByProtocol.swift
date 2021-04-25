//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
#if canImport(ExternalAccessory)
import ExternalAccessory.EASession

public enum AccessoryError: Error {
    /// There are no accessories connected at this time.
    case noAccessoriesPresent
    /// None of the connected accessories support the desired protocol.
    case accessoryNotFound(String)
    /// The stream session could not be established.
    case sessionSetupError
}

public extension EASession {

    /// Establish a connection to the first external accessory that supports the given `supportingProtocol`.
    /// If you don't specify the desired protocol, the bundle's `UISupportedExternalAccessoryProtocols`
    /// is consulted. The first protocol string we find in this array is being used. If your application bundle
    /// supports multiple external accessory protocols, you will need to explicitly specify the protocol to use.
    static func CC_establishToFirstSupportedDevice(supportingProtocol: String? = nil) throws -> (EASession) {

        let connectedAccessories = EAAccessoryManager.shared().connectedAccessories
        guard !connectedAccessories.isEmpty else { throw AccessoryError.noAccessoriesPresent }

        let proto = supportingProtocol ?? {
            guard let array: [String] = Bundle.main.object(forInfoDictionaryKey: "UISupportedExternalAccessoryProtocols") as? [String] else { fatalError("Info.plist: UISupportedExternalAccessoryProtocols not present") }
            guard let string = array.first else { fatalError("Info.plist: UISupportedExternalAccessoryProtocols is present, but empty") }
            return string
        }()

        let connectedAccessory = connectedAccessories.first { $0.protocolStrings.contains(proto) }
        guard connectedAccessory != nil else { throw AccessoryError.accessoryNotFound(proto) }

        guard let session = Self.init(accessory: connectedAccessory!, forProtocol: proto) else { throw AccessoryError.sessionSetupError }
        return session
    }
}
#endif
