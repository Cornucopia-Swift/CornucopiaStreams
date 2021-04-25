//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
import Foundation

public extension Stream {

    /// Handling a TTY connection.
    class TTYConnection: Connection {

        public override func setup() {
            guard FileManager.default.fileExists(atPath: self.url.path) else {
                self.failWith(error: .notFound)
                return
            }
            let path = self.url.path
            let inputStream = InputStream.init(fileAtPath: path)
            let outputStream = OutputStream.init(toFileAtPath: path, append: false)
            guard let istream = inputStream, let ostream = outputStream else {
                self.failWith(error: .unableToConnect)
                return
            }
            self.succeedWith(istream: istream, ostream: ostream)
        }
    }
}
