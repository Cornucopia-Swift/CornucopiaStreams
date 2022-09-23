//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
import Foundation

public extension Stream {

    /// Handling a TTY connection.
    class TTYConnection: Connection {

        private var fd: Int32? = nil

        public override func setup() {
            guard FileManager.default.fileExists(atPath: self.url.path) else {
                self.failWith(error: .notFound)
                return
            }
            let path = self.url.path

            /// If a port is specified, we interpret this as the desired baudrate.
            if let port = self.url.port {

                let fd = Foundation.open(self.url.path, O_RDWR | O_NONBLOCK)
                guard fd >= 0 else {
                    print("Can't open \(self.url.path): \(String(cString: strerror(errno)))")
                    self.failWith(error: .unableToConnect)
                    return
                }
                // macOS resets the baudrate when the filedescriptor closes, hence we need to carry it around until the connection ends.
                self.fd = fd
                var settings = termios()
                if 0 == cfsetspeed(&settings, speed_t(port)) {
                    _ = tcsetattr(fd, TCSANOW, &settings)
                }
            }

            let inputStream = InputStream.init(fileAtPath: path)
            let outputStream = OutputStream.init(toFileAtPath: path, append: false)
            guard let istream = inputStream, let ostream = outputStream else {
                self.failWith(error: .unableToConnect)
                return
            }
            self.succeedWith(istream: istream, ostream: ostream)
        }

        public override func cancel() {
            if let fd = self.fd { Foundation.close(fd) }
        }
    }
}
