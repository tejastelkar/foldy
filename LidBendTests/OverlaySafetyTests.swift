import XCTest
@testable import LidBend

final class OverlaySafetyTests: XCTestCase {
    func testValidClosingAngleRequestsVisibleOverlay() {
        var controller = EffectSafetyController()

        let state = controller.ingest(angle: 60, at: 10)

        XCTAssertTrue(state.isVisible)
        XCTAssertGreaterThan(state.progress, 0.5)
    }

    func testStaleVisibleEffectIsDismissedAfterDeadline() {
        var controller = EffectSafetyController(staleAfter: 0.75)
        _ = controller.ingest(angle: 60, at: 10)

        XCTAssertNil(controller.tick(at: 10.75))
        XCTAssertEqual(controller.tick(at: 10.751), .hidden)
        XCTAssertEqual(controller.currentState, .hidden)
    }

    func testInvalidReadingImmediatelyDismissesEffect() {
        var controller = EffectSafetyController()
        _ = controller.ingest(angle: 60, at: 10)

        XCTAssertEqual(controller.ingest(angle: .nan, at: 10.1), .hidden)
    }

    func testStopAlwaysReturnsHiddenState() {
        var controller = EffectSafetyController()
        _ = controller.ingest(angle: 60, at: 10)

        XCTAssertEqual(controller.stop(), .hidden)
    }
}
