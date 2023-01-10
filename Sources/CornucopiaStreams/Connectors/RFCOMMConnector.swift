//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
#if canImport(IOBluetooth) && !targetEnvironment(macCatalyst)
import CornucopiaCore
import IOBluetooth
import Foundation

fileprivate let logger = Cornucopia.Core.Logger()

extension Cornucopia.Streams {

    /// A connector for MFi-program compliant devices external accessories.
    class RFCOMMConnector: BaseConnector {

        static let forbiddenCharsetAddress = CharacterSet(charactersIn: "0123456789ABCDEF-:").inverted
        static let numberOfCharactersForAddress = 17

        typealias ConnectionContinuation = CheckedContinuation<StreamPair, Swift.Error>
        var continuation: ConnectionContinuation? = nil
        var device: IOBluetoothDevice? = nil
        var channelID: BluetoothRFCOMMChannelID = 0

        /// Connect
        override func connect() async throws -> StreamPair {

            let url = self.meta.url
            guard let host = url.host?.uppercased() else { throw Error.invalidUrl }
            guard host.count == Self.numberOfCharactersForAddress, host.rangeOfCharacter(from: Self.forbiddenCharsetAddress) == nil else { throw Error.invalidUrl }
            guard let device = IOBluetoothDevice(addressString: host) else { throw Error.unableToConnect("\(host) not found") }
            if let port = url.port { self.channelID = BluetoothRFCOMMChannelID(port) }

            let sppServiceUUID = IOBluetoothSDPUUID.uuid32(kBluetoothSDPUUID16ServiceClassSerialPort.rawValue)
            guard let sppServiceRecord = device.getServiceRecord(for: sppServiceUUID) else { throw Error.unableToConnect("\(host) does not provide RFCOMM") }
            guard sppServiceRecord.getRFCOMMChannelID(&channelID) == kIOReturnSuccess else { throw Error.unableToConnect("\(host) does not have an RFCOMM channel id") }

            let bridge = RFCOMMBridge(forDevice: device, channelID: channelID)
            let inputStream = RFCOMMChannelInputStream(with: bridge)
            let outputStream = RFCOMMChannelOutputStream(with: bridge)
            return (inputStream, outputStream)
        }

#if DEBUG
        deinit {
            print("\(self) destroyed")
        }
#endif
    }
}
#endif
