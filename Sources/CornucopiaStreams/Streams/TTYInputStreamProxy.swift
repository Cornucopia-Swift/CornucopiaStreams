//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
import Foundation

/// An InputStream that configures the device's bitrate after open(2).
class TTYInputStreamProxy: ProxyInputStream {

    private let path: String
    private let bitrate: Int?
    private var fd: Int32? = nil

    init?(forReadingAtPath path: String, bitrate: Int? = nil) {
        guard let inputStream = InputStream(fileAtPath: path) else { return nil }
        self.bitrate = bitrate
        self.path = path
        super.init(proxying: inputStream)
    }

    override func open() {
        guard let bitrate = self.bitrate else { return }
        let fd = Foundation.open(self.path, O_RDWR | O_NONBLOCK)
        guard fd >= 0 else {
#if DEBUG
            //FIXME: Should we just continue here or inject a stream error?
            print("Can't open \(self.path): \(String(cString: strerror(errno)))")
#endif
            return
        }
        // macOS resets the baudrate when the filedescriptor closes, hence we need to carry it around until the connection ends.
        self.fd = fd
        var settings = termios()
        _ = tcgetattr(fd, &settings)
        if 0 == cfsetspeed(&settings, speed_t(bitrate)) {
            _ = tcsetattr(fd, TCSAFLUSH, &settings)
        }

        super.open()
    }

    override func close() {
        super.close()

        guard let fd = self.fd else { return }
        Foundation.close(fd)
    }

#if DEBUG
    deinit {
        print("\(self) destroyed")
    }
#endif
}
