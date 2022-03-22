//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
import Foundation

public extension Stream {

    /// Stream connection errors.
    @frozen enum PairError: Error {
        case cancelled
        case invalidParameters
        case notFound
        case timeout
        case unknownScheme
        case unableToConnect
    }

    typealias Pair = (InputStream, OutputStream)
    typealias PairProvider = (URL, @escaping(PairResultHandler)) -> ()
    typealias PairResult = Result<Pair, PairError>
    typealias PairResultHandler = (PairResult) -> ()
    typealias PairContinuation = CheckedContinuation<Pair, Swift.Error>
    typealias ConnectionProvider = (URL, PairContinuation) -> Stream.Connection

    /// Returns the supported schemes on this platform.
    static func CC_supportedSchemes() -> Set<String> {
        Set(self.connectionProviders.keys)
    }

    /// Computes a pair of I/O streams to the specified `url` and returns the result async.
    static func CC_getStreamPair(to url: URL, timeout: TimeInterval = 0.0) async throws -> Pair {

        let scheme = url.scheme ?? "unknown"
        guard let provider = self.connectionProviders[scheme] else { throw PairError.unknownScheme }

        return try await withTaskCancellationHandler(handler: {
            guard let connection = self.CC_pendingConnections[url] else {
                print("Connection for \(url) no longer pending, can't cancel.")
                return
            }
            connection.cancel()
            connection.failWith(error: .cancelled)
        }) {
            return try await withCheckedThrowingContinuation { (continuation: PairContinuation) in
                let connection = provider(url, continuation)
                if timeout > 0 {
                    connection.timer = {
                        let t = DispatchSource.makeTimerSource(flags: DispatchSource.TimerFlags(), queue: DispatchQueue.main)
                        t.schedule(deadline: .now() + timeout)
                        t.setEventHandler { [weak connection] in
                            connection?.cancel()
                            connection?.failWith(error: .timeout)
                        }
                        t.resume()
                        return t
                    }()
                }
                self.CC_pendingConnections[url] = connection
                connection.setup()
            }
        }
    }

    /// Removes a connection from the list of active connections.
    static func CC_disposeConnection(to url: URL) {
        self.CC_activeConnections.removeValue(forKey: url)
    }

    /// Registers a custom connection provider.
    /// Only one connection provider can be registered for a given scheme.
    /// Note that you can replace the builtin providers, if you want.
    static func CC_registerConnectionProvider(forScheme scheme: String, provider: @escaping(ConnectionProvider)) {
        self.connectionProviders[scheme] = provider
    }
}

