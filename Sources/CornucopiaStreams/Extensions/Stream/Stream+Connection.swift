//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
import Foundation

extension Stream {
    /// An abstract connection class. Derive from this class, if you want to add a new connection provider.
    public class Connection {

        let url: URL
        let meta: Meta
        let continuation: PairContinuation
        var timer: DispatchSourceTimer?

        public init(url: URL, continuation: PairContinuation) {
            self.url = url
            self.meta = Meta(url: url)
            self.continuation = continuation
        }

        public func setup() {
            fatalError("MUST be implemented in your connection subclass")
        }

        public func cancel() { }

        public final func failWith(error: PairError) {
            self.timer?.cancel(); self.timer = nil
            Stream.CC_pendingConnections.removeValue(forKey: self.url)
            self.continuation.resume(throwing: error)
        }

        public final func succeedWith(istream: InputStream, ostream: OutputStream) {
            self.timer?.cancel(); self.timer = nil
            istream.CC_storeMeta(self.meta)
            ostream.CC_storeMeta(self.meta)
            Stream.CC_pendingConnections.removeValue(forKey: self.url)
            Stream.CC_activeConnections[self.url] = self
            self.continuation.resume(returning: (istream, ostream))
        }

        deinit {
            print("DEINIT \(self)")
        }
    }
}

internal extension Stream {

    static var CC_pendingConnections: [URL: Connection] = [:]
    static var CC_activeConnections: [URL: Connection] = [:]

    static var connectionProviders: [String: Stream.ConnectionProvider] = {
        var providers: [String: Stream.ConnectionProvider] = [
            "tty": { TTYConnection(url: $0, continuation: $1) },
            "tcp": { TCPConnection(url: $0, continuation: $1) },
        ]
#if canImport(ExternalAccessory)
        providers["ea"] = { EAConnection(url: $0, continuation: $1) }
#endif
#if canImport(CoreBluetooth)
        providers["ble"] = { BLEConnection(url: $0, continuation: $1) }
#endif
        return providers
    }()
}
