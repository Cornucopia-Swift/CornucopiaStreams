import XCTest
@testable import CornucopiaStreams
import Foundation // Added for Pipe

// Mock StreamDelegate to capture events
fileprivate class MockStreamDelegate: NSObject, StreamDelegate {
    var receivedEvents: [Stream.Event] = []
    var expectations: [UInt: XCTestExpectation] = [:] // Use UInt (rawValue) as key

    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        print("Delegate received event: \(eventCode) (rawValue: \(eventCode.rawValue))")
        receivedEvents.append(eventCode)
        expectations[eventCode.rawValue]?.fulfill() // Use rawValue
    }

    func expect(_ event: Stream.Event, description: String) {
        expectations[event.rawValue] = XCTestExpectation(description: description) // Use rawValue
    }

    func clear() {
        receivedEvents.removeAll()
        expectations.removeAll()
    }
}

fileprivate final class FileHandleInputStreamTests: XCTestCase {

    var pipe: Pipe!
    var inputStream: FileHandleInputStream!
    var mockDelegate: MockStreamDelegate!
    let runLoop = RunLoop.current // Use current thread's run loop
    let testData = "Hello, Stream!".data(using: .utf8)!
    let timeout: TimeInterval = 2.0 // Timeout for expectations

    override func setUpWithError() throws {
        try super.setUpWithError()
        pipe = Pipe()
        // IMPORTANT: Use the READING end for the InputStream
        inputStream = FileHandleInputStream(fileHandle: pipe.fileHandleForReading)
        mockDelegate = MockStreamDelegate()
        inputStream.delegate = mockDelegate

        // Schedule on the current run loop for testing
        inputStream.schedule(in: runLoop, forMode: .default)
        print("Stream scheduled on RunLoop")
    }

    override func tearDownWithError() throws {
        print("Tearing down...")
        if inputStream.streamStatus != .closed {
             inputStream.close()
        }
        inputStream.remove(from: runLoop, forMode: .default)
        // Close the writing end if it's still open (reading end closed by inputStream.close())
        try? pipe.fileHandleForWriting.close()

        inputStream = nil
        pipe = nil
        mockDelegate = nil
        try super.tearDownWithError()
        print("Teardown complete.")
    }

    func testOpen() throws {
        mockDelegate.expect(.openCompleted, description: "Expect .openCompleted event")

        XCTAssertEqual(inputStream.streamStatus, .notOpen, "Initial status should be .notOpen")
        inputStream.open()
        XCTAssertEqual(inputStream.streamStatus, .open, "Status should be .open after open()")

        // Use rawValue for lookup
        wait(for: [mockDelegate.expectations[Stream.Event.openCompleted.rawValue]!], timeout: timeout)
        XCTAssertTrue(mockDelegate.receivedEvents.contains(.openCompleted), "Delegate should receive .openCompleted")
    }

    func testRead() throws {
        let bufferSize = 1024
        var buffer = [UInt8](repeating: 0, count: bufferSize)

        mockDelegate.expect(.openCompleted, description: "Expect .openCompleted")
        mockDelegate.expect(.hasBytesAvailable, description: "Expect .hasBytesAvailable")

        inputStream.open()
        // Give the async block in open() a chance to schedule/run
        runLoop.run(mode: .default, before: Date(timeIntervalSinceNow: 0.01))
        // Use rawValue for lookup
        wait(for: [mockDelegate.expectations[Stream.Event.openCompleted.rawValue]!], timeout: timeout)
        XCTAssertEqual(inputStream.streamStatus, .open)

        // Write data to the pipe's writing end
        try pipe.fileHandleForWriting.write(contentsOf: testData)
        print("Data written to pipe")

        // Wait for the .hasBytesAvailable event using standard wait
        // Use rawValue for lookup
        let hasBytesAvailableExpectation = mockDelegate.expectations[Stream.Event.hasBytesAvailable.rawValue]!
        wait(for: [hasBytesAvailableExpectation], timeout: timeout)

        XCTAssertTrue(mockDelegate.receivedEvents.contains(.hasBytesAvailable), "Delegate should receive .hasBytesAvailable")
        XCTAssertTrue(inputStream.hasBytesAvailable, "Stream should report bytes available")

        // Read the data
        let bytesRead = inputStream.read(&buffer, maxLength: bufferSize)

        XCTAssertEqual(bytesRead, testData.count, "Number of bytes read should match data size")
        let readData = Data(bytes: buffer, count: bytesRead)
        XCTAssertEqual(readData, testData, "Read data should match written data")
        XCTAssertFalse(inputStream.hasBytesAvailable, "Stream should report no bytes available after read")
    }

    func testEndEncountered() throws {
        let bufferSize = 1024
        var buffer = [UInt8](repeating: 0, count: bufferSize)

        mockDelegate.expect(.openCompleted, description: "Expect .openCompleted")
        mockDelegate.expect(.hasBytesAvailable, description: "Expect .hasBytesAvailable")
        mockDelegate.expect(.endEncountered, description: "Expect .endEncountered")

        inputStream.open()
        // Give the async block in open() a chance to schedule/run
        runLoop.run(mode: .default, before: Date(timeIntervalSinceNow: 0.01))
        // Use rawValue for lookup
        wait(for: [mockDelegate.expectations[Stream.Event.openCompleted.rawValue]!], timeout: timeout)
        XCTAssertEqual(inputStream.streamStatus, .open)

        // Write data then immediately close the writing end
        try pipe.fileHandleForWriting.write(contentsOf: testData)
        try pipe.fileHandleForWriting.close()
        print("Data written and pipe closed")

        // Wait for hasBytesAvailable using standard wait
        // Use rawValue for lookup
        let hasBytesAvailableExpectation = mockDelegate.expectations[Stream.Event.hasBytesAvailable.rawValue]!
        wait(for: [hasBytesAvailableExpectation], timeout: timeout)
        XCTAssertTrue(mockDelegate.receivedEvents.contains(.hasBytesAvailable))

        // Read the data
        let bytesRead = inputStream.read(&buffer, maxLength: bufferSize)
        XCTAssertEqual(bytesRead, testData.count)

        // Wait for endEncountered using standard wait
        // Use rawValue for lookup
        let endEncounteredExpectation = mockDelegate.expectations[Stream.Event.endEncountered.rawValue]!
        // The read operation might trigger the notification that leads to endEncountered.
        // Sometimes the notification and delegate call happen slightly after the read returns.
        // Calling read again *might* be necessary if the first didn't trigger it, but often just waiting is enough.
        // If the first read didn't trigger the event, the second read returning 0 will.
        let firstReadResult = inputStream.read(&buffer, maxLength: bufferSize)
        if firstReadResult != 0 {
             print("WARN: Read after expected EOF returned \(firstReadResult) bytes, expected 0.")
        }
        wait(for: [endEncounteredExpectation], timeout: timeout)

        XCTAssertTrue(mockDelegate.receivedEvents.contains(.endEncountered), "Delegate should receive .endEncountered")

        // Subsequent read should return 0
        let finalRead = inputStream.read(&buffer, maxLength: bufferSize)
        XCTAssertEqual(finalRead, 0, "Read after end should return 0")
    }

    func testClose() throws {
        mockDelegate.expect(.openCompleted, description: "Expect .openCompleted")
        // Note: Closing does not generate a delegate event by default in Foundation.Stream

        inputStream.open()
        // Use rawValue for lookup
        wait(for: [mockDelegate.expectations[Stream.Event.openCompleted.rawValue]!], timeout: timeout)
        XCTAssertEqual(inputStream.streamStatus, .open)

        inputStream.close()
        XCTAssertEqual(inputStream.streamStatus, .closed, "Status should be .closed after close()")

        // Verify reading after close fails
        var buffer = [UInt8](repeating: 0, count: 10)
        let bytesRead = inputStream.read(&buffer, maxLength: 10)
        XCTAssertEqual(bytesRead, 0, "Read after close should return 0") // Or -1 depending on implementation, 0 seems standard for InputStream
    }

}

// MARK: - FileHandleOutputStream Tests

fileprivate final class FileHandleOutputStreamTests: XCTestCase {

    var pipe: Pipe!
    var outputStream: FileHandleOutputStream!
    var mockDelegate: MockStreamDelegate!
    let runLoop = RunLoop.current // Needed for delegate callbacks via perform
    let testData = "Hello, Output!".data(using: .utf8)!
    let timeout: TimeInterval = 2.0 // Timeout for expectations

    override func setUpWithError() throws {
        try super.setUpWithError()
        pipe = Pipe()
        // IMPORTANT: Use the WRITING end for the OutputStream
        outputStream = FileHandleOutputStream(fileHandle: pipe.fileHandleForWriting)
        mockDelegate = MockStreamDelegate()
        outputStream.delegate = mockDelegate
        // No scheduling needed as per OutputStream implementation
        print("OutputStream Setup Complete")
    }

    override func tearDownWithError() throws {
        print("OutputStream Tearing down...")
        if outputStream.streamStatus != .closed {
             outputStream.close() // This closes fileHandleForWriting
        }
        // Ensure the reading end is also closed if not already
        try? pipe.fileHandleForReading.close()

        outputStream = nil
        pipe = nil
        mockDelegate = nil
        try super.tearDownWithError()
        print("OutputStream Teardown complete.")
    }

    func testOpen() throws {
        mockDelegate.expect(.openCompleted, description: "Expect .openCompleted event")
        mockDelegate.expect(.hasSpaceAvailable, description: "Expect .hasSpaceAvailable event after open")

        XCTAssertEqual(outputStream.streamStatus, .notOpen, "Initial status should be .notOpen")
        outputStream.open()
        XCTAssertEqual(outputStream.streamStatus, .open, "Status should be .open after open()")

        // Wait for delegate events (sent via RunLoop.perform)
        wait(for: [mockDelegate.expectations[Stream.Event.openCompleted.rawValue]!,
                   mockDelegate.expectations[Stream.Event.hasSpaceAvailable.rawValue]!],
             timeout: timeout)

        XCTAssertTrue(mockDelegate.receivedEvents.contains(.openCompleted), "Delegate should receive .openCompleted")
        XCTAssertTrue(mockDelegate.receivedEvents.contains(.hasSpaceAvailable), "Delegate should receive .hasSpaceAvailable after open")
    }

    func testWrite() throws {
        mockDelegate.expect(.openCompleted, description: "Expect .openCompleted")
        mockDelegate.expect(.hasSpaceAvailable, description: "Expect .hasSpaceAvailable after open")

        outputStream.open()
        wait(for: [mockDelegate.expectations[Stream.Event.openCompleted.rawValue]!,
                   mockDelegate.expectations[Stream.Event.hasSpaceAvailable.rawValue]!],
             timeout: timeout)
        XCTAssertEqual(outputStream.streamStatus, .open)

        // Write data to the stream
        var dataBytes = [UInt8](testData)
        let bytesWritten = outputStream.write(&dataBytes, maxLength: dataBytes.count)
        XCTAssertEqual(bytesWritten, testData.count, "Should write all bytes")

        // Check specifically the *last* event, as open also sends one.
        // RunLoop needs a chance to process the event posted by write()
        // A minimal spin allows the delegate callback to occur.
        RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0.1))
        XCTAssertEqual(mockDelegate.receivedEvents.last, .hasSpaceAvailable, "Delegate should receive .hasSpaceAvailable after write")

        // IMPORTANT: Close the writing handle to signal EOF to the reading handle
        outputStream.close() // Or try? pipe.fileHandleForWriting.close()
        XCTAssertEqual(outputStream.streamStatus, .closed)

        // Read from the reading end of the pipe to verify
        let readData = try pipe.fileHandleForReading.readToEnd()
        XCTAssertNotNil(readData, "Should be able to read data from the pipe")
        XCTAssertEqual(readData, testData, "Read data should match written data")
    }

    func testClose() throws {
        mockDelegate.expect(.openCompleted, description: "Expect .openCompleted")
        mockDelegate.expect(.hasSpaceAvailable, description: "Expect .hasSpaceAvailable after open")

        outputStream.open()
        wait(for: [mockDelegate.expectations[Stream.Event.openCompleted.rawValue]!,
                   mockDelegate.expectations[Stream.Event.hasSpaceAvailable.rawValue]!],
             timeout: timeout)
        XCTAssertEqual(outputStream.streamStatus, .open)

        outputStream.close()
        XCTAssertEqual(outputStream.streamStatus, .closed, "Status should be .closed after close()")

        // Verify writing after close fails
        var dataBytes = [UInt8](testData)
        let bytesWritten = outputStream.write(&dataBytes, maxLength: dataBytes.count)
        XCTAssertLessThanOrEqual(bytesWritten, 0, "Write after close should return 0 or negative error code")
    }

}

 // Keep the original example test or remove if not needed
 final class CornucopiaStreamsTests: XCTestCase {
     func testExample() throws {
         // This is an example of a functional test case.
         // Use XCTAssert and related functions to verify your tests produce the correct
         // results.
         XCTAssertEqual(true, true)
     }
 }
