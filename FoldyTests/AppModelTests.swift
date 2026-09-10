import XCTest
@testable import Foldy

@MainActor
final class AppModelTests: XCTestCase {
    func testSetEnabledChangesPublishedState() {
        let model = AppModel()

        XCTAssertFalse(model.isEnabled)
        model.setEnabled(true)
        XCTAssertTrue(model.isEnabled)
    }

    func testAppearanceConfigurationReachesOverlay() {
        let overlay = RecordingOverlay()
        let model = AppModel(sensor: PreviewAngleProvider(), overlay: overlay)

        model.configure(clearAngle: 135, appearance: .frost, playOpeningSound: false)

        XCTAssertEqual(overlay.appearance, .frost)
    }
}

@MainActor
private final class RecordingOverlay: OverlayCoordinating {
    var isVisible = false
    var appearance: FoldAppearance = .silk

    func update(appearance: FoldAppearance) {
        self.appearance = appearance
    }

    func apply(_ state: FoldState) async throws {
        isVisible = state.isVisible
    }

    func dismissAll() async {
        isVisible = false
    }
}
