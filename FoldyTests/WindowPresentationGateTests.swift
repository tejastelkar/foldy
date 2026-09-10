import XCTest
@testable import Foldy

final class WindowPresentationGateTests: XCTestCase {
    func testEachWindowKindCanOnlyBeCreatedOnce() {
        var gate = WindowPresentationGate()

        XCTAssertTrue(gate.claim(.onboarding))
        XCTAssertFalse(gate.claim(.onboarding))
        XCTAssertTrue(gate.claim(.settings))
        XCTAssertFalse(gate.claim(.settings))
    }

    func testReleasingAWindowAllowsItToBeRecreated() {
        var gate = WindowPresentationGate()
        XCTAssertTrue(gate.claim(.preview))

        gate.release(.preview)

        XCTAssertTrue(gate.claim(.preview))
    }
}
