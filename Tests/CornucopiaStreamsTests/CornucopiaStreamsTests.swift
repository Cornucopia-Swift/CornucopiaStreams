import XCTest
@testable import CornucopiaStreams

//FIXME: We need more tests, but end-to-end testing streams to external accessories and BLE devices is going to be non-trivial.
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
