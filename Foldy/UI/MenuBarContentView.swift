import AppKit
import SwiftUI

struct MenuBarContentView: View {
    @ObservedObject var model: AppModel
    @ObservedObject var settings: AppSettings
    let showPreview: () -> Void
    let showSettings: () -> Void

    @State private var hasScreenAccess = CGPreflightScreenCaptureAccess()

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(spacing: 11) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(.quaternary)
                        .overlay {
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
                        }
                    Image(systemName: "macbook.gen2")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(.primary)
                }
                .frame(width: 34, height: 34)

                VStack(alignment: .leading, spacing: 1) {
                    Text("Foldy")
                        .font(.headline.weight(.semibold))
                    Text(statusSubtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            HStack {
                Text("Enable Foldy")
                    .font(.body)
                Spacer()
                Toggle("", isOn: Binding(
                    get: { model.isEnabled },
                    set: {
                        configureModel()
                        settings.effectEnabled = $0
                        model.setEnabled($0)
                    }
                ))
                .toggleStyle(.switch)
                .labelsHidden()
            }

            HStack(spacing: 6) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 6, height: 6)
                if let angle = model.currentAngle {
                    Text("Lid angle:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(Int(angle.rounded()))°")
                        .font(.caption.monospacedDigit().weight(.medium))
                        .foregroundStyle(.primary)
                } else {
                    Text(compatibilityText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if !hasScreenAccess {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .font(.caption)
                    Text("Screen recording access needed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Button("Request Access") {
                    _ = CGRequestScreenCaptureAccess()
                    PrivacySettingsDestination.screenRecording.open()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }

            if let error = model.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider()

            Button("Preview Effect…") {
                showPreview()
            }
            .buttonStyle(.plain)
            .padding(.vertical, 2)

            Button("Settings…") {
                showSettings()
            }
            .buttonStyle(.plain)
            .padding(.vertical, 2)
            .keyboardShortcut(",")

            Divider()

            Button("Quit Foldy") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .padding(.vertical, 2)
            .keyboardShortcut("q")
        }
        .padding(14)
        .frame(width: 260)
        .onAppear {
            configureModel()
            hasScreenAccess = CGPreflightScreenCaptureAccess()
        }
    }

    private var statusSubtitle: String {
        if model.isEnabled {
            return "Active"
        }
        return "Inactive"
    }

    private var statusColor: Color {
        if !hasScreenAccess { return .orange }
        if model.isEnabled { return FoldyTheme.mint }
        return .secondary.opacity(0.6)
    }

    private var compatibilityText: String {
        switch model.sensorAvailability {
        case .unknown: "Checking lid sensor…"
        case .available: "Hinge sensor ready"
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
