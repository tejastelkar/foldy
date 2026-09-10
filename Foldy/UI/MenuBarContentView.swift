import AppKit
import SwiftUI

struct MenuBarContentView: View {
    @ObservedObject var model: AppModel
    @ObservedObject var settings: AppSettings
    let showPreview: () -> Void
    let showSettings: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(FoldyTheme.duoGradient)
                    Image(systemName: "macbook")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .frame(width: 38, height: 38)
                .shadow(color: FoldyTheme.blue.opacity(0.28), radius: 10, y: 5)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Foldy").font(.headline.weight(.semibold))
                    Text("Desktop motion, beautifully tuned").font(.caption).foregroundStyle(.secondary)
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
                    .fill(model.isEnabled ? FoldyTheme.mint : Color.secondary)
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
                showPreview()
            }

            Button("Settings…") {
                showSettings()
            }
            .keyboardShortcut(",")

            Divider()
            Button("Quit Foldy") { NSApplication.shared.terminate(nil) }
                .keyboardShortcut("q")
        }
        .padding(16)
        .frame(width: 280)
        .tint(FoldyTheme.blue)
        .background(FoldyTheme.duoGradient.opacity(0.055))
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
