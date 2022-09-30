//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
import Foundation

/// Describes a transport connector protocol.
protocol _CornucopiaTransportConnector {

    /// Creates a connector for connecting to the specified ``URL``.
    init(url: URL)
    /// Connects and returns a stream pair.
    func connect() async throws -> Cornucopia.Streams.StreamPair
    /// Cancels this connection, if possible.
    func cancel()
}

extension Cornucopia.Streams { typealias Connector = _CornucopiaTransportConnector }
