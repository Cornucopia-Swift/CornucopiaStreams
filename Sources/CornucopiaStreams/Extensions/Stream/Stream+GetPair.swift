//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
import Foundation

public extension Stream {

    /// Possible stream connection errors
    enum PairError: Error {
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
    typealias ConnectionProvider = (URL, @escaping(Stream.PairResultHandler)) -> Stream.Connection

    /// Computes a pair of I/O streams to the specified `url` and delivers the result via the closure.
    static func CC_getStreamPair(to url: URL, timeout: TimeInterval = 0.0, then: @escaping(PairResultHandler)) {

        let scheme = url.scheme ?? "unknown"
        guard let provider = self.connectionProviders[scheme] else {
            let result: PairResult = .failure(.unknownScheme)
            then(result)
            return
        }
        let connection = provider(url, then)
        if timeout > 0 {
            connection.timer = {
                let t = DispatchSource.makeTimerSource(flags: DispatchSource.TimerFlags(), queue: DispatchQueue.main)
                t.schedule(deadline: .now() + timeout)
                t.setEventHandler { [weak connection] in
                    Stream.CC_pendingConnections.removeValue(forKey: url)
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

    /// Removes a connection from the list of acctive connections.
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

public extension Stream {

    /// An abstract connection class. Derive from this class, if you want to add a new connection provider.
    class Connection {

        let url: URL
        private let then: PairResultHandler
        fileprivate var timer: DispatchSourceTimer?

        public init(url: URL, then: @escaping(PairResultHandler)) {
            self.url = url
            self.then = then
        }
        public func setup() {
            fatalError("MUST be implementeded in your connection subclass")
        }
        public func cancel() {
            // SHOULD be implemented in the connection subclass
        }
        public final func failWith(error: PairError) {
            self.timer?.cancel(); self.timer = nil
            Stream.CC_pendingConnections.removeValue(forKey: self.url)
            let result = PairResult.failure(error)
            self.then(result)
        }
        public final func succeedWith(istream: InputStream, ostream: OutputStream) {
            self.timer?.cancel(); self.timer = nil
            istream.CC_url = self.url
            Stream.CC_pendingConnections.removeValue(forKey: self.url)
            Stream.CC_activeConnections[self.url] = self
            let result = PairResult.success((istream, ostream))
            self.then(result)
        }

        deinit {
            //print("deinit \(self)")
        }
    }
}

internal extension Stream {

    static var CC_pendingConnections: [URL: Connection] = [:]
    static var CC_activeConnections: [URL: Connection] = [:]

    static var connectionProviders: [String: Stream.ConnectionProvider] = [
        "tty": { TTYConnection(url: $0, then: $1) },
        "tcp": { TCPConnection(url: $0, then: $1) },
        "ea": { EAConnection(url: $0, then: $1) },
        "ble": { BLEConnection(url: $0, then: $1) },
    ]
}
