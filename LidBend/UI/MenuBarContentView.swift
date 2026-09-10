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

            HStack {
                Circle()
                    .fill(model.isEnabled ? Color.green : Color.secondary)
                    .frame(width: 7, height: 7)
                Text(model.currentAngle.map { "Live angle: \(Int($0.rounded()))°" } ?? compatibilityText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let error = model.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }

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

    private var compatibilityText: String {
        switch model.sensorAvailability {
        case .unknown:
            "Checking lid sensor…"
        case .available:
            "Lid sensor ready"
        case .unavailable(let reason):
            reason
        }
    }
}
