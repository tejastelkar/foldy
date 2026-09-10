import SwiftUI

@main
struct FoldyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var model = AppModel()
    @StateObject private var settings = AppSettings()

    var body: some Scene {
        MenuBarExtra("Foldy", systemImage: "macbook") {
            MenuBarContentView(model: model, settings: settings)
        }
        .menuBarExtraStyle(.window)

        Window("Fold Preview", id: "preview") {
            PreviewView(appearance: settings.appearance)
        }
        .windowResizability(.contentSize)

        Window("Foldy Settings", id: "settings") {
            SettingsRootView(model: model, settings: settings)
        }
        .defaultSize(width: 860, height: 650)

        Window("Welcome to Foldy", id: "onboarding") {
            OnboardingView(settings: settings)
        }
        .windowResizability(.contentSize)
    }
}
