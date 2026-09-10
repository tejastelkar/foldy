import SwiftUI

@main
struct FoldyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("Foldy", systemImage: "macbook") {
            MenuBarContentView(
                model: appDelegate.model,
                settings: appDelegate.settings,
                showPreview: { appDelegate.windows.showPreview() },
                showSettings: { appDelegate.windows.showSettings() }
            )
        }
        .menuBarExtraStyle(.window)
    }
}
