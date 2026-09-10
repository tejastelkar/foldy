import Combine
import Foundation

@MainActor
final class AppSettings: ObservableObject {
    private enum Key {
        static let effectEnabled = "effectEnabled"
        static let clearAngle = "clearAngle"
        static let legacyStartAngle = "startAngle"
        static let appearanceStyle = "appearanceStyle"
        static let followLid = "followLid"
        static let perspective = "perspective"
        static let variableBlur = "variableBlur"
        static let shadow = "shadow"
        static let playOpeningSound = "playOpeningSound"
        static let launchAtLogin = "launchAtLogin"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
    }

    private let defaults: UserDefaults

    @Published var effectEnabled: Bool { didSet { defaults.set(effectEnabled, forKey: Key.effectEnabled) } }
    @Published var clearAngle: Double { didSet { defaults.set(clearAngle, forKey: Key.clearAngle) } }
    @Published var appearanceStyle: FoldStyle { didSet { defaults.set(appearanceStyle.rawValue, forKey: Key.appearanceStyle) } }
    @Published var followLid: Bool { didSet { defaults.set(followLid, forKey: Key.followLid) } }
    @Published var perspective: Double { didSet { defaults.set(perspective, forKey: Key.perspective) } }
    @Published var variableBlur: Double { didSet { defaults.set(variableBlur, forKey: Key.variableBlur) } }
    @Published var shadow: Double { didSet { defaults.set(shadow, forKey: Key.shadow) } }
    @Published var playOpeningSound: Bool { didSet { defaults.set(playOpeningSound, forKey: Key.playOpeningSound) } }
    @Published var launchAtLogin: Bool { didSet { defaults.set(launchAtLogin, forKey: Key.launchAtLogin) } }
    @Published var hasCompletedOnboarding: Bool { didSet { defaults.set(hasCompletedOnboarding, forKey: Key.hasCompletedOnboarding) } }

    var appearance: FoldAppearance {
        FoldAppearance(
            style: appearanceStyle,
            perspective: perspective,
            variableBlur: variableBlur,
            shadow: shadow
        )
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        effectEnabled = defaults.bool(forKey: Key.effectEnabled)
        clearAngle = defaults.object(forKey: Key.clearAngle) as? Double
            ?? defaults.object(forKey: Key.legacyStartAngle) as? Double
            ?? 135
        appearanceStyle = FoldStyle(rawValue: defaults.string(forKey: Key.appearanceStyle) ?? "") ?? .silk
        followLid = defaults.object(forKey: Key.followLid) as? Bool ?? true
        perspective = defaults.object(forKey: Key.perspective) as? Double ?? FoldAppearance.silk.perspective
        variableBlur = defaults.object(forKey: Key.variableBlur) as? Double ?? FoldAppearance.silk.variableBlur
        shadow = defaults.object(forKey: Key.shadow) as? Double ?? FoldAppearance.silk.shadow
        playOpeningSound = defaults.object(forKey: Key.playOpeningSound) as? Bool ?? true
        launchAtLogin = defaults.bool(forKey: Key.launchAtLogin)
        hasCompletedOnboarding = defaults.bool(forKey: Key.hasCompletedOnboarding)
    }

    func apply(style: FoldStyle) {
        let preset = style.preset
        appearanceStyle = preset.style
        perspective = preset.perspective
        variableBlur = preset.variableBlur
        shadow = preset.shadow
    }

    func resetAppearance() {
        clearAngle = 135
        followLid = true
        apply(style: .silk)
    }
}
