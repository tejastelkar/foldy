import XCTest
@testable import LidBend

@MainActor
final class AppModelTests: XCTestCase {
    func testSetEnabledChangesPublishedState() {
        let model = AppModel()

        XCTAssertFalse(model.isEnabled)
        model.setEnabled(true)
        XCTAssertTrue(model.isEnabled)
    }
}
