import XCTest
@testable import CornucopiaStreams

extension XCTest {

    func XCTAssertThrowsError<T: Sendable>(_ expression: @autoclosure () async throws -> T, _ message: @autoclosure () -> String = "", file: StaticString = #filePath, line: UInt = #line, _ errorHandler: (_ error: Error) -> Void = { _ in }) async {
        do {
            _ = try await expression()
            XCTFail(message(), file: file, line: line)
        } catch {
            errorHandler(error)
        }
    }
}

final class AsyncTests: XCTestCase {

    static var cancelled: Bool = false

    func testCancellation() async {

        let t = Task.detached {
            print("so it begins")
            await self.XCTAssertThrowsError(try await Stream.CC_getStreamPair(to: URL(string: "ea://something.notexisting.to.hang.forever")!))
            print("cancelled")
            Self.cancelled = true
        }

        Thread.sleep(forTimeInterval: 3)
        t.cancel()
        Thread.sleep(forTimeInterval: 1)
        XCTAssertTrue(Self.cancelled)
    }
}

