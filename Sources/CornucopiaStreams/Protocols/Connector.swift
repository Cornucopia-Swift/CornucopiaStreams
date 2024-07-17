//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
import Foundation

extension Cornucopia.Streams {

    /// Describes a transport connector protocol.
    protocol Connector {

        /// Creates a connector for connecting to the specified ``URL``.
        init(url: URL)
        /// Connects and returns a stream pair.
        func connect() async throws -> Cornucopia.Streams.StreamPair
        /// Cancels this connection, if possible.
        func cancel()
    }
}
