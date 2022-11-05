//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
@_exported import CornucopiaCore
import Foundation

public extension Cornucopia {

    enum Streams {

        /// A bundle of an ``InputStream`` and an ``OutputStream``.
        public typealias StreamPair = (input: InputStream, output: OutputStream)

        /// Possible high level errors. Some connectors might throw additional errors.
        public enum Error: Swift.Error {
            /// Not implemented
            case notImplemented
            /// URL is invalid or lacking parameters.
            case invalidUrl
            /// The connection is already in progress.
            case connectionInProgress
            /// The connection has been cancelled.
            case connectionCancelled
            /// The scheme is not supported.
            case unsupportedScheme(String)
            /// Connection could not be established.
            case unableToConnect(String)
        }

        /// Connect to the specified ``URL``.
        public static func connect(url: URL) async throws -> StreamPair {
            try await Cornucopia.Streams.Broker.shared.connect(to: url)
        }
    }
}
