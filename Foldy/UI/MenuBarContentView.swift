import AppKit
import SwiftUI

struct MenuBarContentView: View {
    @ObservedObject var model: AppModel
    @ObservedObject var settings: AppSettings
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "macbook")
                    .font(.title2)
                    .foregroundStyle(.tint)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Foldy").font(.headline)
                    Text("Make your desktop fold").font(.caption).foregroundStyle(.secondary)
                }
            }

            Toggle("Enable Foldy", isOn: Binding(
                get: { model.isEnabled },
                set: {
                    configureModel()
                    settings.effectEnabled = $0
                    model.setEnabled($0)
                }
            ))

            HStack {
                Circle()
                    .fill(model.isEnabled ? Color.green : Color.secondary)
                    .frame(width: 7, height: 7)
                Text(model.currentAngle.map { "Live angle: \(Int($0.rounded()))°" } ?? compatibilityText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let error = model.errorMessage {
                Text(error).font(.caption).foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button("Preview Effect…") {
                openWindow(id: "preview")
                NSApplication.shared.activate(ignoringOtherApps: true)
            }

            Button("Settings…") {
                openWindow(id: "settings")
                NSApplication.shared.activate(ignoringOtherApps: true)
            }
            .keyboardShortcut(",")

            Divider()
            Button("Quit Foldy") { NSApplication.shared.terminate(nil) }
                .keyboardShortcut("q")
        }
        .padding(16)
        .frame(width: 280)
        .onAppear(perform: configureModel)
    }

    private var compatibilityText: String {
        switch model.sensorAvailability {
        case .unknown: "Checking lid sensor…"
        case .available: "Lid sensor ready"
        case .unavailable(let reason): reason
        }
    }

    private func configureModel() {
        model.configure(
            clearAngle: settings.clearAngle,
            appearance: settings.appearance,
            playOpeningSound: settings.playOpeningSound
        )
    }
}
