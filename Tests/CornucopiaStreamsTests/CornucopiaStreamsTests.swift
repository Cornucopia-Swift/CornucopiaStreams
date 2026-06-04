import Foundation
import XCTest
@testable import CornucopiaStreams

final class ConnectorCancellationTests: XCTestCase {

    func testTCPConnectorCancellation() async throws {
        let url = try XCTUnwrap(URL(string: "tcp://192.0.2.1:65000"))
        try await expectCancellation(
            for: url,
            connectorName: "TCPConnector",
            warmupNanoseconds: 4_000_000_000,
            timeoutNanoseconds: 5_000_000_000
        )
    }

    #if canImport(ExternalAccessory)
    func testEAConnectorCancellation() async throws {
        let url = try XCTUnwrap(URL(string: "ea://com.example.protocol"))
        try await expectCancellation(for: url, connectorName: "EAConnector") { error in
            guard case AccessoryError.protocolNotInPlist = error else { return nil }
            return "Test bundle has no UISupportedExternalAccessoryProtocols entry"
        }
    }
    #endif

    #if canImport(CoreBluetooth)
    @MainActor
    func testBLEConnectorCancellation() async throws {
        let url = try XCTUnwrap(URL(string: "ble://DEAD"))
        try await expectCancellation(for: url, connectorName: "BLEConnector", warmupNanoseconds: 200_000_000, timeoutNanoseconds: 2_000_000_000)
    }
    #endif

    #if canImport(IOBluetooth) && !targetEnvironment(macCatalyst)
    func testRFCOMMConnectorCancellation() async throws {
        let url = try XCTUnwrap(URL(string: "rfcomm://00-11-22-33-44-55:1"))
        try await expectCancellation(for: url, connectorName: "RFCOMMConnector") { error in
            guard let streamsError = error as? Cornucopia.Streams.Error, case .unableToConnect = streamsError else { return nil }
            return "Bluetooth environment rejected the connection before cancellation could take effect"
        }
    }
    #endif

}

final class TTYConnectorTests: XCTestCase {

    func testTTYConnectorOpensTemporaryStreamPair() async throws {
        let path = FileManager.default.temporaryDirectory
            .appendingPathComponent("cornucopia-streams-tty-\(UUID().uuidString)")
        FileManager.default.createFile(atPath: path.path, contents: Data())
        defer { try? FileManager.default.removeItem(at: path) }

        let urlString = "tty://\(path.path)"
        let url = try XCTUnwrap(URL(string: urlString))
        let pair = try await Cornucopia.Streams.Broker.shared.connect(to: url)

        pair.input.open()
        pair.output.open()
        XCTAssertEqual(pair.input.streamStatus, .open)
        XCTAssertEqual(pair.output.streamStatus, .open)

        pair.input.close()
        pair.output.close()
    }

    func testTTYConnectorOpensConfiguredSerialDevice() async throws {
        let environment = ProcessInfo.processInfo.environment
        guard let path = environment["CORNUCOPIA_STREAMS_TEST_TTY_PATH"], !path.isEmpty else {
            throw XCTSkip("Set CORNUCOPIA_STREAMS_TEST_TTY_PATH to run the hardware TTY integration test")
        }
        guard FileManager.default.fileExists(atPath: path) else {
            throw XCTSkip("Configured TTY device does not exist: \(path)")
        }

        let urlString: String
        if let bitrate = environment["CORNUCOPIA_STREAMS_TEST_TTY_BITRATE"], !bitrate.isEmpty {
            urlString = "tty://localhost:\(bitrate)\(path)"
        } else {
            urlString = "tty://\(path)"
        }
        let url = try XCTUnwrap(URL(string: urlString))
        let pair = try await Cornucopia.Streams.Broker.shared.connect(to: url)

        pair.input.open()
        pair.output.open()
        XCTAssertEqual(pair.input.streamStatus, .open)
        XCTAssertEqual(pair.output.streamStatus, .open)

        pair.input.close()
        pair.output.close()
    }
}

// MARK: - Cancellation Test Helpers

private enum CancellationObservationResult {
    case completedSuccessfully
    case failed(Error)
}

private struct CancellationTimeoutError: Error {}

private func expectCancellation(
    for url: URL,
    connectorName: String,
    warmupNanoseconds: UInt64 = 50_000_000,
    timeoutNanoseconds: UInt64 = 200_000_000,
    file: StaticString = #filePath,
    line: UInt = #line,
    environmentSkipReason: (Error) -> String? = { _ in nil }
) async throws {

    let broker = Cornucopia.Streams.Broker.shared
    let task = Task {
        try await broker.connect(to: url)
    }
    defer { task.cancel() }

    await Task.yield()
    if warmupNanoseconds > 0 {
        try? await Task.sleep(nanoseconds: warmupNanoseconds)
    }

    task.cancel()

    let observation = await observeCancellation(of: task, timeoutNanoseconds: timeoutNanoseconds)

    switch observation {
        case .completedSuccessfully:
            XCTFail("\(connectorName) connection unexpectedly succeeded (cancellation had no effect)", file: file, line: line)

        case .failed(let error):
            // Some connectors fail fast on machines lacking the required hardware or entitlements;
            // there is nothing to cancel then, so we skip rather than report a bogus failure.
            if let reason = environmentSkipReason(error) {
                throw XCTSkip("\(connectorName): \(reason)", file: file, line: line)
            }
            if let streamsError = error as? Cornucopia.Streams.Error {
                if case .connectionCancelled = streamsError {
                    // Expected outcome; the connector reported proper cancellation.
                } else {
                    XCTFail("\(connectorName) should report connectionCancelled when cancelled (received \(streamsError))", file: file, line: line)
                }
            } else if error is CancellationError {
                // Accept the generic cancellation error that Swift can throw for cooperative tasks.
            } else if error is CancellationTimeoutError {
                XCTFail("\(connectorName) did not finish after cancellation request", file: file, line: line)
            } else {
                XCTFail("\(connectorName) threw unexpected error \(error)", file: file, line: line)
            }
    }
}

private func observeCancellation<Success>(
    of task: Task<Success, Error>,
    timeoutNanoseconds: UInt64
) async -> CancellationObservationResult {

    await withTaskCancellationHandler {
        await withTaskGroup(of: CancellationObservationResult.self, returning: CancellationObservationResult.self) { group in
            group.addTask {
                do {
                    _ = try await task.value
                    return .completedSuccessfully
                } catch {
                    return .failed(error)
                }
            }
            group.addTask {
                try? await Task.sleep(nanoseconds: timeoutNanoseconds)
                return .failed(CancellationTimeoutError())
            }
            guard let first = await group.next() else {
                return .failed(CancellationTimeoutError())
            }
            group.cancelAll()
            return first
        }
    } onCancel: {
        task.cancel()
    }
}
