import XCTest
@testable import CornucopiaStreams

final class CornucopiaStreamsTests: XCTestCase, StreamDelegate {

    func testTCP() {

        let lock = NSLock()
        lock.lock()
        let url = URL(string: "tcp://www.google.de:80")!
        Stream.CC_getStreamPair(to: url) { result in
            guard case .success(let (inputStream, outputStream)) = result else { fatalError() }
            inputStream.delegate = self
            outputStream.delegate = self
            lock.unlock()
        }
        lock.lock()
    }

    static var allTests = [
        ("TCP", testTCP),
    ]
}
