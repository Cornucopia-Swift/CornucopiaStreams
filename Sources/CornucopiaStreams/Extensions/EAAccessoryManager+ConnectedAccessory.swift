//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
#if canImport(ExternalAccessory)
import ExternalAccessory.EAAccessoryManager

@frozen public enum AccessoryError: Error {
    /// UISupportedExternalAccessoryProtocols in plist not found or empty.
    case protocolNotInPlist
}

extension EAAccessoryManager {

    private static let UISupportedExternalAccessoryProtocols: String = "UISupportedExternalAccessoryProtocols"

    /// Establish a connection to the first external accessory that supports the given `supportingProtocol`.
    func CC_connectedAccessoryForProtocol(_ proto: String) throws -> EAAccessory? {

        guard let array: [String] = Bundle.main.object(forInfoDictionaryKey: Self.UISupportedExternalAccessoryProtocols) as? [String] else { throw AccessoryError.protocolNotInPlist }
        guard array.contains(proto) else { throw AccessoryError.protocolNotInPlist }
        return self.connectedAccessories.first { $0.protocolStrings.contains(proto) }
    }
}
#endif
