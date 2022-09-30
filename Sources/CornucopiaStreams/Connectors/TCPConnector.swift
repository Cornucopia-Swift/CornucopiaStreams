//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
import Foundation

extension Cornucopia.Streams {

    /// A connector for TCP.
    class TCPConnector: Connector {

        func connect(to url: URL) async throws -> Cornucopia.Streams.StreamPair {

            guard let host = url.host, !host.isEmpty else { throw Error.invalidUrl }
            guard let port = url.port, port > 0 else { throw Error.invalidUrl }
            let (inputStream, outputStream) = Stream.CC_getStreamsToHost(with: host, port: port)
            guard let istream = inputStream, let ostream = outputStream else {
                throw Error.unableToConnect("Can't connect via TCP to \(host):\(port)")
            }
            return (istream, ostream)
        }

        func cancel() {
            // Nothing to do, since connect works synchronously.
        }

#if DEBUG
        deinit {
            print("\(self) destroyed")
        }
#endif
    }
}
