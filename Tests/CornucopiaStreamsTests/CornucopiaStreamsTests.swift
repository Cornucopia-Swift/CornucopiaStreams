import XCTest
@testable import CornucopiaStreams

//FIXME: We need more tests, but end-to-end testing streams to external accessories and BLE devices is going to be non-trivial.
final class CornucopiaStreamsTests: XCTestCase, StreamDelegate {

    var didSend = false

    func testTCP() {


        let lock = NSLock()
        lock.lock()
        let url = URL(string: "tcp://192.168.0.10:35000")!
        var inputs: InputStream? = nil
        var outputs: OutputStream? = nil
        Stream.CC_getStreamPair(to: url) { result in
            guard case let .success(streams) = result else { fatalError() }
            lock.unlock()
            inputs = streams.0
            outputs = streams.1
        }
        lock.lock()

        inputs!.delegate = self
        outputs!.delegate = self
        inputs!.open()
        outputs!.open()

        Thread.sleep(forTimeInterval: 1)
        RunLoop.main.run()
    }

    func stream(_ stream: Stream, handle event: Stream.Event) {
        print("stream \(stream): handle \(event)")

        if stream is OutputStream && event == .hasSpaceAvailable && !didSend {
            didSend = true
            (stream as! OutputStream).write("ATI\r", maxLength: 4)
        }

        if stream is InputStream && event == .hasBytesAvailable {
            var buffer = [UInt8](repeating: 0, count: 10)
            (stream as! InputStream).read(&buffer, maxLength: 10)
            let ch = Character(UnicodeScalar(buffer[0]))
            var string = String(ch)
            if string == "\r" { string = "\\r" }
            if string == "\n" { string = "\\n" }
            print("Read '\(string)'")
        }
    }

    static var allTests = [
        ("TCP", testTCP),
    ]
}
