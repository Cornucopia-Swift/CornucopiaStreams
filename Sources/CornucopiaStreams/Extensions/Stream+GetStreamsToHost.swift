//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
import Foundation
import CoreFoundation

/// It's possible to use the low level socket helper unconditionally (instead of Darwin's getStreamsToHost), just
/// change this to 'true //' here and below.
#if canImport(FoundationNetworking)
import CSocketHelper
#endif

public extension Stream {

    /// Create an input/output stream pair bound to the specified TCP host.
    class func CC_getStreamsToHost(with name: String, port: Int) -> (InputStream?, OutputStream?) {

        var inputStream: InputStream?
        var outputStream: OutputStream?
        #if canImport(FoundationNetworking)
        let fileDescriptor = csocket_connect(name.cString(using: .utf8), Int32(port), 1000)
        if fileDescriptor >= 0 {
            let fih = FileHandle(fileDescriptor: fileDescriptor, closeOnDealloc: true)
            let foh = FileHandle(fileDescriptor: fileDescriptor, closeOnDealloc: false)
            inputStream = FileHandleInputStream(fileHandle: fih)
            outputStream = FileHandleOutputStream(fileHandle: foh)
        }
        #else
        Self.getStreamsToHost(withName: name, port: port, inputStream: &inputStream, outputStream: &outputStream)
        #endif
        return (inputStream, outputStream)
    }
}
