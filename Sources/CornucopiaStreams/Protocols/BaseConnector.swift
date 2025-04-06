//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
import CornucopiaCore
import Foundation

private let logger = Cornucopia.Core.Logger()

extension Cornucopia.Streams {

    /// A connector is responsible for establishing a connection to a remote service.
    #if canImport(ObjectiveC)
    class BaseConnector: NSObject, Connector {

        let meta: Stream.Meta
        required init(url: URL) {
            self.meta = .init(url: url)
        }

        func connect() async throws -> Cornucopia.Streams.StreamPair { fatalError("implement this in your concrete subclass") }
        func cancel() {
            logger.debug("Cancel is NOT implemented in concrete subclass")
        }
    }
    #else
    class BaseConnector: Connector {

        let meta: Stream.Meta
        required init(url: URL) {
            self.meta = .init(url: url)
        }

        func connect() async throws -> Cornucopia.Streams.StreamPair { fatalError("implement this in your concrete subclass") }
        func cancel() {
            logger.debug("Cancel is NOT implemented in concrete connector subclass")
        }
    }
    #endif
}
