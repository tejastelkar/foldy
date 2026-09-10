import AppKit
import SwiftUI

struct MenuBarContentView: View {
    @ObservedObject var model: AppModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "macbook")
                    .font(.title2)
                    .foregroundStyle(.tint)

                VStack(alignment: .leading, spacing: 1) {
                    Text("LidBend")
                        .font(.headline)
                    Text("Make your desktop fold")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Toggle(
                "Enable lid effect",
                isOn: Binding(
                    get: { model.isEnabled },
                    set: { model.setEnabled($0) }
                )
            )

            Button("Preview effect…") {
                openWindow(id: "preview")
                NSApplication.shared.activate(ignoringOtherApps: true)
            }

            Divider()

            Button("Quit LidBend") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .padding(16)
        .frame(width: 280)
    }
}
