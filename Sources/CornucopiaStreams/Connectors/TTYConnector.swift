//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
import CornucopiaCore
import Foundation

extension Cornucopia.Streams {

    /// A connector for (pseudo)-TTYs and (USB) serial ports.
    class TTYConnector: BaseConnector {

        override func connect() async throws -> Cornucopia.Streams.StreamPair {

            let url = self.meta.url
            guard !url.path.isEmpty, FileManager.default.fileExists(atPath: url.path) else { throw Error.invalidUrl }
            guard let inputStream = TTYInputStreamProxy(forReadingAtPath: url.path, bitrate: url.port) else { throw Error.unableToConnect("Can't open \(url.path) for reading") }
            guard let outputStream = OutputStream(toFileAtPath: url.path, append: false) else { throw Error.unableToConnect("Can't open \(url.path) for writing") }
            return (inputStream, outputStream)
        }

#if DEBUG
        deinit {
            print("\(self) destroyed")
        }
#endif
    }
}
