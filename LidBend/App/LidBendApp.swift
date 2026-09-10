import SwiftUI

@main
struct LidBendApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var model = AppModel()
    @StateObject private var settings = AppSettings()

    var body: some Scene {
        MenuBarExtra("LidBend", systemImage: "macbook") {
            MenuBarContentView(model: model, settings: settings)
        }
        .menuBarExtraStyle(.window)

        Window("Fold Preview", id: "preview") {
            PreviewView()
        }
        .windowResizability(.contentSize)

        Window("Welcome to LidBend", id: "onboarding") {
            OnboardingView(settings: settings)
        }
        .windowResizability(.contentSize)
    }
}
