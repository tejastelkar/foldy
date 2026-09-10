import SwiftUI

@main
struct LidBendApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        MenuBarExtra("LidBend", systemImage: "macbook") {
            MenuBarContentView(model: model)
        }
        .menuBarExtraStyle(.window)

        Window("Fold Preview", id: "preview") {
            PreviewView()
        }
        .windowResizability(.contentSize)
    }
}
