//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
import Foundation

/// Describes a transport connector protocol.
protocol _CornucopiaTransportConnector {

    /// Opens the connection to the specified ``URL``.
    func connect(to url: URL) async throws -> Cornucopia.Streams.StreamPair
    /// Cancels this connection, if possible.
    func cancel()
}

extension Cornucopia.Streams { typealias Connector = _CornucopiaTransportConnector }
