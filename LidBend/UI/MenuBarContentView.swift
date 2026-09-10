import AppKit
import SwiftUI

struct MenuBarContentView: View {
    @ObservedObject var model: AppModel
    @ObservedObject var settings: AppSettings
    @Environment(\.openWindow) private var openWindow
    @State private var launchAtLoginError: String?

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
                    set: {
                        settings.effectEnabled = $0
                        model.setEnabled($0)
                    }
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

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Start bending at")
                    Spacer()
                    Text("\(Int(settings.startAngle))°")
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                Slider(value: $settings.startAngle, in: 75...125, step: 1)
            }

            Toggle("Launch at login", isOn: Binding(
                get: { settings.launchAtLogin },
                set: { enabled in
                    do {
                        try LaunchAtLoginService().setEnabled(enabled)
                        settings.launchAtLogin = enabled
                        launchAtLoginError = nil
                    } catch {
                        launchAtLoginError = error.localizedDescription
                    }
                }
            ))

            if let launchAtLoginError {
                Text(launchAtLoginError)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Button("Setup & privacy…") {
                openWindow(id: "onboarding")
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
