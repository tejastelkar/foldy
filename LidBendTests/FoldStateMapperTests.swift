import XCTest
@testable import LidBend

final class FoldStateMapperTests: XCTestCase {
    private let mapper = FoldStateMapper(openAngle: 110, closedAngle: 12, hysteresis: 3)

    func testAngleAboveOpenThresholdHidesEffect() {
        let state = mapper.state(for: 120, previousVisible: false)

        XCTAssertEqual(state.progress, 0, accuracy: 0.0001)
        XCTAssertFalse(state.isVisible)
    }

    func testMidpointAngleProducesHalfProgress() {
        let state = mapper.state(for: 61, previousVisible: false)

        XCTAssertEqual(state.progress, 0.5, accuracy: 0.0001)
        XCTAssertTrue(state.isVisible)
    }

    func testClosedThresholdProducesFullProgress() {
        let state = mapper.state(for: 12, previousVisible: true)

        XCTAssertEqual(state.progress, 1, accuracy: 0.0001)
        XCTAssertEqual(state.blurRadius, 12, accuracy: 0.0001)
    }

    func testNonFiniteAngleFailsSafeToHidden() {
        XCTAssertFalse(mapper.state(for: .nan, previousVisible: true).isVisible)
        XCTAssertFalse(mapper.state(for: .infinity, previousVisible: true).isVisible)
    }

    func testVisibleEffectUsesThreeDegreeExitHysteresis() {
        XCTAssertTrue(mapper.state(for: 112, previousVisible: true).isVisible)
        XCTAssertFalse(mapper.state(for: 114, previousVisible: true).isVisible)
    }

    func testCustomStartAngleChangesVisibilityThreshold() {
        let earlyMapper = FoldStateMapper(openAngle: 95, closedAngle: 12, hysteresis: 3)

        XCTAssertFalse(earlyMapper.state(for: 100, previousVisible: false).isVisible)
        XCTAssertTrue(earlyMapper.state(for: 90, previousVisible: false).isVisible)
    }
}
