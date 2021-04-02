//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
#if canImport(FoundationNetworking)
import Foundation
import CoreFoundation

/**
 NOTE: getStreamsToHost(withName hostname: String, port: Int, inputStream: AutoreleasingUnsafeMutablePointer<InputStream?>?, outputStream: AutoreleasingUnsafeMutablePointer<OutputStream?>?)
       is not implemented for non-apple platforms due to some obscure ongoing discussion with regards to the use of `AutoreleasingUnsafeMutablePointer`.
       This extension replicates this very useful API – possible at the expense of leaking memory or what not.
 */
public extension Stream {

    /// Creates and returns by reference an NSInputStream object and NSOutputStream object for a socket connection with a given host on a given port.
    class func getStreamsToHost(withName hostname: String, port: Int, inputStream: AutoreleasingUnsafeMutablePointer<InputStream?>?, outputStream: AutoreleasingUnsafeMutablePointer<OutputStream?>?) {

        var pReadStream: UnsafeMutablePointer<Unmanaged<CFReadStream>?> = UnsafeMutablePointer.allocate(capacity: 1)
        var pWriteStream: UnsafeMutablePointer<Unmanaged<CFWriteStream>?> = UnsafeMutablePointer.allocate(capacity: 1)
        CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault, hostname as CFString, UInt32(port), pReadStream, pWriteStream)
        guard let pInputStream = inputStream else { fatalError("inputStream needs to be non-NULL") }
        guard let pOutputStream = outputStream else { fatalError("outputStream needs to be non-NULL") }
        pInputStream.pointee = pReadStream.pointee?.takeRetainedValue()
        pOutputStream.pointee = pWriteStream.pointee?.takeRetainedValue()
    }
}
#endif
