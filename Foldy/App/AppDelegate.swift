import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var launchWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("--settings-preview") {
            let settings = AppSettings()
            showWindow(
                title: "Foldy Settings",
                rootView: AnyView(SettingsRootView(model: AppModel(), settings: settings)),
                size: CGSize(width: 860, height: 650)
            )
        } else if arguments.contains("--preview") {
            showWindow(title: "Foldy Preview", rootView: AnyView(PreviewView()), size: CGSize(width: 688, height: 500))
        } else if !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") {
            let settings = AppSettings()
            showWindow(
                title: "Welcome to Foldy",
                rootView: AnyView(OnboardingView(settings: settings)),
                size: CGSize(width: 540, height: 430)
            )
        }
    }

    private func showWindow(title: String, rootView: AnyView, size: CGSize) {
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = title
        window.contentView = NSHostingView(rootView: rootView)
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
        launchWindow = window
    }
}
