//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
import CornucopiaCore
import Foundation

public extension Stream {

    /// Restore partial API compatibility with CornucopiaStreams 1.0
    class func CC_getStreamPair(to url: URL) async throws -> (InputStream, OutputStream) { try await Cornucopia.Streams.connect(url: url) }
}
