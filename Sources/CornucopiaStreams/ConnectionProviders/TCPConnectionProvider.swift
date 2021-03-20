//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
import Foundation

public extension Stream {

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
            var inputStream: InputStream?
            var outputStream: OutputStream?
            Stream.getStreamsToHost(withName: hostname, port: port, inputStream: &inputStream, outputStream: &outputStream)
            guard let istream = inputStream, let ostream = outputStream else {
                self.failWith(error: .notFound)
                return
            }
            self.succeedWith(istream: istream, ostream: ostream)
        }
    }
}
