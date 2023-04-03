//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
import CornucopiaCore
import Foundation

public extension Cornucopia.Streams {

    final actor Broker {

        public static var shared: Broker = .init()

        /// Pending connection objects
        internal private(set) var pending: [URL: any Connector]

        private init() {
            self.pending = [:]
        }

        /// Attempt a connection to the specified `url`. Returns a pair of streams, if successful.
        public func connect(to url: URL) async throws -> StreamPair {

            guard !self.pending.keys.contains(url) else { throw Error.connectionInProgress }
            guard let scheme = url.scheme else { throw Error.invalidUrl }
            let connector: any Connector
            switch scheme {

#if canImport(ExternalAccessory)
                case "ea":
                    connector = EAConnector(url: url)
#endif
#if canImport(CoreBluetooth)
                case "ble":
                    connector = BLEConnector(url: url)
#endif
                case "tty":
                    connector = TTYConnector(url: url)
                case "tcp":
                    connector = TCPConnector(url: url)
#if canImport(IOBluetooth) && !targetEnvironment(macCatalyst)
                case "rfcomm":
                    connector = RFCOMMConnector(url: url)
#endif
                default:
                    throw Error.unsupportedScheme(scheme)
            }
            self.pending[url] = connector
            defer {
                self.pending[url] = nil
            }
            return try await withTaskCancellationHandler(operation: {
                try await connector.connect()
            }, onCancel: {
                connector.cancel()
            })
        }
    }
}
