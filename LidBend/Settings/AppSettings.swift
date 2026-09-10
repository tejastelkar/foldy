import Combine
import Foundation

@MainActor
final class AppSettings: ObservableObject {
    private enum Key {
        static let effectEnabled = "effectEnabled"
        static let startAngle = "startAngle"
        static let intensity = "intensity"
        static let launchAtLogin = "launchAtLogin"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
    }

    private let defaults: UserDefaults

    @Published var effectEnabled: Bool { didSet { defaults.set(effectEnabled, forKey: Key.effectEnabled) } }
    @Published var startAngle: Double { didSet { defaults.set(startAngle, forKey: Key.startAngle) } }
    @Published var intensity: Double { didSet { defaults.set(intensity, forKey: Key.intensity) } }
    @Published var launchAtLogin: Bool { didSet { defaults.set(launchAtLogin, forKey: Key.launchAtLogin) } }
    @Published var hasCompletedOnboarding: Bool { didSet { defaults.set(hasCompletedOnboarding, forKey: Key.hasCompletedOnboarding) } }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        effectEnabled = defaults.bool(forKey: Key.effectEnabled)
        startAngle = defaults.object(forKey: Key.startAngle) as? Double ?? 110
        intensity = defaults.object(forKey: Key.intensity) as? Double ?? 1
        launchAtLogin = defaults.bool(forKey: Key.launchAtLogin)
        hasCompletedOnboarding = defaults.bool(forKey: Key.hasCompletedOnboarding)
    }
}
