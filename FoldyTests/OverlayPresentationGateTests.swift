import XCTest
@testable import Foldy

@MainActor
final class OverlayPresentationGateTests: XCTestCase {
    func testInvalidatedPresentationCannotCommitAndNextOneCanStart() {
        let gate = OverlayPresentationGate()

        let first = gate.begin()
        XCTAssertNotNil(first)
        XCTAssertNil(gate.begin())

        gate.invalidate()
        XCTAssertFalse(gate.finish(first!))

        let second = gate.begin()
        XCTAssertNotNil(second)
        XCTAssertTrue(gate.finish(second!))
        XCTAssertFalse(gate.isPresenting)
    }
}
