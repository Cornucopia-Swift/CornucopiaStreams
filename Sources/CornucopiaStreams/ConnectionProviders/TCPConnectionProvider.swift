//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
import Foundation

public extension Stream {

    /// Handling a TCP connection.
    class TCPConnection: Connection {

        public override func setup() {
            guard let hostname = url.host else {
                self.failWith(error: .invalidParameters)
                return
            }
            guard let port = url.port else {
                self.failWith(error: .invalidParameters)
                return
            }
            let (inputStream, outputStream) = Stream.CC_getStreamsToHost(with: hostname, port: port)
            guard let istream = inputStream, let ostream = outputStream else {
                self.failWith(error: .notFound)
                return
            }
            self.succeedWith(istream: istream, ostream: ostream)
        }
    }
}
