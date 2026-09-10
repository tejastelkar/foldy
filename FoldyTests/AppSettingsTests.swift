import XCTest
@testable import Foldy

@MainActor
final class AppSettingsTests: XCTestCase {
    func testFreshInstallUsesSafeDefaults() {
        let defaults = makeDefaults()
        let settings = AppSettings(defaults: defaults)

        XCTAssertFalse(settings.effectEnabled)
        XCTAssertEqual(settings.clearAngle, 135)
        XCTAssertEqual(settings.appearanceStyle, .silk)
        XCTAssertTrue(settings.followLid)
        XCTAssertEqual(settings.perspective, 1)
        XCTAssertEqual(settings.variableBlur, 0.65)
        XCTAssertEqual(settings.shadow, 0.55)
        XCTAssertTrue(settings.playOpeningSound)
        XCTAssertFalse(settings.launchAtLogin)
        XCTAssertFalse(settings.hasCompletedOnboarding)
    }

    func testChangedSettingsPersistAcrossInstances() {
        let defaults = makeDefaults()
        let first = AppSettings(defaults: defaults)
        first.clearAngle = 126
        first.perspective = 0.7
        first.appearanceStyle = .frost
        first.followLid = false
        first.hasCompletedOnboarding = true

        let second = AppSettings(defaults: defaults)
        XCTAssertEqual(second.clearAngle, 126)
        XCTAssertEqual(second.perspective, 0.7)
        XCTAssertEqual(second.appearanceStyle, .frost)
        XCTAssertFalse(second.followLid)
        XCTAssertTrue(second.hasCompletedOnboarding)
    }

    func testApplyingShadeWritesItsPresetValues() {
        let settings = AppSettings(defaults: makeDefaults())

        settings.apply(style: .shade)

        XCTAssertEqual(settings.appearanceStyle, .shade)
        XCTAssertEqual(settings.perspective, 1)
        XCTAssertEqual(settings.variableBlur, 0.28)
        XCTAssertEqual(settings.shadow, 0.9)
    }

    func testResetAppearanceRestoresSilkDefaults() {
        let settings = AppSettings(defaults: makeDefaults())
        settings.apply(style: .frost)
        settings.clearAngle = 100

        settings.resetAppearance()

        XCTAssertEqual(settings.appearanceStyle, .silk)
        XCTAssertEqual(settings.perspective, 1)
        XCTAssertEqual(settings.variableBlur, 0.65)
        XCTAssertEqual(settings.shadow, 0.55)
        XCTAssertEqual(settings.clearAngle, 135)
    }

    private func makeDefaults() -> UserDefaults {
        let suite = "FoldyTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }
}
