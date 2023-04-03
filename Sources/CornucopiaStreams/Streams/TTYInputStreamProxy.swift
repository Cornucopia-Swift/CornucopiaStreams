//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
import Foundation

/// An InputStream that configures the device's bitrate after open(2).
final class TTYInputStreamProxy: ProxyInputStream {

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
            print("Can't open \(self.path): \(String(cString: strerror(errno)))")
#endif
            self.reportDelegateEvent(.errorOccurred)
            return
        }
        // macOS resets the baudrate when the filedescriptor closes, hence we need to carry it around until the connection ends.
        self.fd = fd
        var settings = termios()
        _ = tcgetattr(fd, &settings)
        var retry = 3
        // Do the bitrate dance.
        while retry > 0 && !(settings.c_ispeed == bitrate && settings.c_ospeed == bitrate) {
            _ = cfsetspeed(&settings, speed_t(bitrate))
            _ = tcsetattr(fd, TCSAFLUSH, &settings)
            usleep(100000)
            _ = tcsetattr(fd, TCSANOW, &settings)
            _ = cfsetspeed(&settings, speed_t(bitrate))
            _ = tcgetattr(fd, &settings)
            retry -= 1
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
