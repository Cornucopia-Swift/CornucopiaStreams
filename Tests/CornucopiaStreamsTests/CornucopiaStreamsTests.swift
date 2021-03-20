import XCTest
@testable import CornucopiaStreams

final class CornucopiaStreamsTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(CornucopiaStreams().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
