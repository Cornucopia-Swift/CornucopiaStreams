//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
import Foundation

extension Cornucopia.Streams {

    #if canImport(ObjectiveC)
    class BaseConnector: NSObject, Connector {

        let meta: Stream.Meta
        required init(url: URL) {
            self.meta = .init(url: url)
        }

        func connect() async throws -> Cornucopia.Streams.StreamPair { fatalError("implement this in your concrete subclass") }
        func cancel() {}
    }
    #else
    class BaseConnector: Connector {

        let meta: Stream.Meta
        required init(url: URL) {
            self.meta = .init(url: url)
        }

        func connect() async throws -> Cornucopia.Streams.StreamPair { fatalError("implement this in your concrete subclass") }
        func cancel() {}
    }
    #endif
}
