import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let model = AppModel()
    let settings = AppSettings()
    lazy var windows = AppWindowCoordinator(model: model, settings: settings)

    func applicationDidFinishLaunching(_ notification: Notification) {
        model.configure(
            clearAngle: settings.clearAngle,
            appearance: settings.appearance,
            playOpeningSound: settings.playOpeningSound
        )

        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("--settings-preview") {
            windows.showSettings()
        } else if arguments.contains("--preview") {
            windows.showPreview()
        } else if !settings.hasCompletedOnboarding {
            windows.showOnboarding()
        } else if settings.effectEnabled {
            model.setEnabled(true)
        }
    }
}
