//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
import CornucopiaCore
import Foundation

extension Cornucopia.Streams {

    /// A connector for TCP.
    class TCPConnector: BaseConnector {

        override func connect() async throws -> Cornucopia.Streams.StreamPair {

            let url = self.meta.url
            guard let host = url.host, !host.isEmpty else { throw Error.invalidUrl }
            guard let port = url.port, port > 0 else { throw Error.invalidUrl }
            let (inputStream, outputStream) = Stream.CC_getStreamsToHost(with: host, port: port)
            guard let istream = inputStream, let ostream = outputStream else {
                throw Error.unableToConnect("Can't connect via TCP to \(host):\(port)")
            }
            return (istream, ostream)
        }

#if DEBUG
        deinit {
            print("\(self) destroyed")
        }
#endif
    }
}
