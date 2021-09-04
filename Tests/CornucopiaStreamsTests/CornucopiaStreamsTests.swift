import XCTest
@testable import CornucopiaStreams

//FIXME: We need more tests, but end-to-end testing streams to external accessories and BLE devices is going to be non-trivial.
final class CornucopiaStreamsTests: XCTestCase, StreamDelegate {

    var didSend = false
    var didReceiveResult = false

    func testTCP() {

        print("thread: \(Thread.current)")
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

        #if !canImport(FoundationNetworking)
        // on Darwin-systems, the streams must be scheduled in a runloop, otherwise no transmission will occur
        inputs!.schedule(in: RunLoop.main, forMode: .common)
        outputs!.schedule(in: RunLoop.main, forMode: .common)
        #endif

        inputs!.delegate = self
        outputs!.delegate = self
        inputs!.open()
        outputs!.open()

        Thread.sleep(forTimeInterval: 1)

        while !self.didReceiveResult {
            RunLoop.main.run(until: Date() + 1)
        }
    }

    func stream(_ stream: Stream, handle event: Stream.Event) {
        print("stream \(stream): handle \(event)")

        if stream is OutputStream && event == .hasSpaceAvailable && !didSend {
            didSend = true
            (stream as! OutputStream).write("ATI\r", maxLength: 4)
        }

        if stream is InputStream && event == .hasBytesAvailable {
            let maxRead = 100
            var buffer = [UInt8](repeating: 0, count: maxRead)
            (stream as! InputStream).read(&buffer, maxLength: maxRead)
            var ms = ""
            for i in 0..<maxRead {
                let ch = Character(UnicodeScalar(buffer[i]))
                var string = String(ch)
                if string == "\r" { string = "\\r" }
                if string == "\n" { string = "\\n" }
                ms += string
            }
            print("Read '\(ms)'")
            if ms.hasPrefix("ELM327") {
                self.didReceiveResult = true
            }
        }
    }

    static var allTests = [
        ("TCP", testTCP),
    ]
}
