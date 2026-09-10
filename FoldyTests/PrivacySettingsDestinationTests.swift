import XCTest
@testable import Foldy

final class PrivacySettingsDestinationTests: XCTestCase {
    func testScreenRecordingDestinationTargetsTheCorrectPrivacyPane() {
        XCTAssertEqual(
            PrivacySettingsDestination.screenRecording.url.absoluteString,
            "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
        )
    }
}
