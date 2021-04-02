//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
import Foundation
import CoreFoundation

public extension Stream {

    class func CC_getStreamsToHost(with name: String, port: Int) -> (InputStream?, OutputStream?) {

        #if canImport(FoundationNetworking)
        fatalError("I'm sorry, this is not yet implemented on Linux")
        #else
        var inputStream: InputStream?
        var outputStream: OutputStream?
        Self.getStreamsToHost(withName: name, port: port, inputStream: &inputStream, outputStream: &outputStream)
        return (inputStream, outputStream)
        #endif
    }
}
