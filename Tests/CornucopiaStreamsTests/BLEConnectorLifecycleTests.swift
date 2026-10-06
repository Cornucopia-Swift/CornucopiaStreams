// Cornucopia – (C) Dr. Lauer Information Technology
#if canImport(CoreBluetooth)
import Foundation
import XCTest
@testable import CornucopiaStreams

final class BLEConnectorLifecycleTests: XCTestCase {
    @MainActor
    func testCancelBeforeConnectIsIdempotentAndRejectsSetup() async throws {
        let url = try XCTUnwrap(URL(string: "ble://DEAD"))
        let connector = Cornucopia.Streams.BLEConnector(url: url)
        connector.cancel()
        connector.cancel()
        XCTAssertNil(connector.manager)
        do {
            _ = try await connector.connect(timeout: 1)
            XCTFail("A cancelled connector must not start Bluetooth")
        } catch Cornucopia.Streams.Error.connectionCancelled {
            XCTAssertNil(connector.manager)
        }
        connector.cancel()
    }
}
#endif
