import XCTest
@testable import LidBend

@MainActor
final class AppSettingsTests: XCTestCase {
    func testFreshInstallUsesSafeDefaults() {
        let defaults = makeDefaults()
        let settings = AppSettings(defaults: defaults)

        XCTAssertFalse(settings.effectEnabled)
        XCTAssertEqual(settings.startAngle, 110)
        XCTAssertEqual(settings.intensity, 1)
        XCTAssertFalse(settings.launchAtLogin)
        XCTAssertFalse(settings.hasCompletedOnboarding)
    }

    func testChangedSettingsPersistAcrossInstances() {
        let defaults = makeDefaults()
        let first = AppSettings(defaults: defaults)
        first.startAngle = 96
        first.intensity = 0.7
        first.hasCompletedOnboarding = true

        let second = AppSettings(defaults: defaults)
        XCTAssertEqual(second.startAngle, 96)
        XCTAssertEqual(second.intensity, 0.7)
        XCTAssertTrue(second.hasCompletedOnboarding)
    }

    private func makeDefaults() -> UserDefaults {
        let suite = "LidBendTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }
}
