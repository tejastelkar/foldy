import AppKit
import Combine
import CoreGraphics
import SwiftUI

struct SettingsRootView: View {
    private enum Destination: String, CaseIterable, Identifiable {
        case general = "General"
        case appearance = "Appearance"
        case about = "About"

        var id: String { rawValue }
        var icon: String {
            switch self {
            case .general: "gearshape.fill"
            case .appearance: "circle.lefthalf.filled"
            case .about: "info.circle.fill"
            }
        }
    }

    @ObservedObject var model: AppModel
    @ObservedObject var settings: AppSettings
    var showOnboarding: (() -> Void)?
    @State private var selection: Destination? = .appearance

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Label("General", systemImage: Destination.general.icon).tag(Destination.general)
                Section("Settings") {
                    Label("Appearance", systemImage: Destination.appearance.icon).tag(Destination.appearance)
                }
                Section("Foldy") {
                    Label("About", systemImage: Destination.about.icon).tag(Destination.about)
                }
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 180, ideal: 190, max: 220)
        } detail: {
            switch selection ?? .appearance {
            case .general: GeneralSettingsView(model: model, settings: settings, showOnboarding: showOnboarding)
            case .appearance: AppearanceSettingsView(model: model, settings: settings)
            case .about: AboutSettingsView()
            }
        }
        .frame(minWidth: 820, minHeight: 610)
        .tint(FoldyTheme.blue)
        .onAppear(perform: syncModel)
        .onChange(of: settings.appearance) { _, _ in syncModel() }
        .onChange(of: settings.clearAngle) { _, _ in syncModel() }
        .onChange(of: settings.playOpeningSound) { _, _ in syncModel() }
    }

    private func syncModel() {
        model.configure(clearAngle: settings.clearAngle, appearance: settings.appearance, playOpeningSound: settings.playOpeningSound)
    }
}

private struct GeneralSettingsView: View {
    @ObservedObject var model: AppModel
    @ObservedObject var settings: AppSettings
    let showOnboarding: (() -> Void)?
    @State private var loginError: String?
    @State private var hasScreenAccess = CGPreflightScreenCaptureAccess()

    var body: some View {
        Form {
            Section {
                Toggle("Enable Foldy", isOn: Binding(
                    get: { model.isEnabled },
                    set: {
                        settings.effectEnabled = $0
                        model.setEnabled($0)
                    }
                ))
                Text("Fold the live desktop when your MacBook lid moves.")
                    .font(.caption).foregroundStyle(.secondary)
            }

            Section("Startup") {
                Toggle("Launch Foldy at login", isOn: Binding(
                    get: { settings.launchAtLogin },
                    set: { enabled in updateLaunchAtLogin(enabled) }
                ))
                if let loginError { Text(loginError).font(.caption).foregroundStyle(.red) }
            }

            Section("Sound") {
                Toggle("Play a sound when the desktop opens", isOn: $settings.playOpeningSound)
            }

            Section("Setup & Privacy") {
                LabeledContent("Screen access") {
                    Label(hasScreenAccess ? "Ready" : "Needs access",
                          systemImage: hasScreenAccess ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                        .foregroundStyle(hasScreenAccess ? FoldyTheme.mint : Color.orange)
                }
                Button("Open Screen Recording Settings") {
                    PrivacySettingsDestination.screenRecording.open()
                }
                if let showOnboarding {
                    Button("Show Setup Guide", action: showOnboarding)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("General")
        .onReceive(NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didActivateApplicationNotification)) { _ in
            hasScreenAccess = CGPreflightScreenCaptureAccess()
        }
    }

    private func updateLaunchAtLogin(_ enabled: Bool) {
        do {
            try LaunchAtLoginService().setEnabled(enabled)
            settings.launchAtLogin = enabled
            loginError = nil
        } catch {
            loginError = error.localizedDescription
        }
    }
}

private struct AppearanceSettingsView: View {
    @ObservedObject var model: AppModel
    @ObservedObject var settings: AppSettings
    @State private var previewAngle = 92.0

    private var displayedAngle: Double {
        if settings.followLid, let angle = model.currentAngle { angle } else { previewAngle }
    }

    private var previewState: FoldState {
        FoldStateMapper(openAngle: settings.clearAngle, closedAngle: 12, hysteresis: 3)
            .state(for: displayedAngle, previousVisible: displayedAngle < settings.clearAngle + 3)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Label("Appearance", systemImage: "circle.lefthalf.filled")
                    .font(.title2.weight(.semibold))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, FoldyTheme.blue)

                MacBookPreview(state: previewState, appearance: settings.appearance)
                    .frame(maxWidth: 520).frame(height: 260).frame(maxWidth: .infinity)

                HStack(spacing: 12) {
                    Text("\(Int(displayedAngle.rounded()))°")
                        .monospacedDigit().foregroundStyle(.secondary)
                        .frame(width: 42, alignment: .trailing)
                    Slider(value: $previewAngle, in: 12...150, step: 1)
                        .disabled(settings.followLid && model.currentAngle != nil)
                    Toggle("Follow lid", isOn: $settings.followLid).toggleStyle(.switch)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Style").font(.headline)
                    HStack(spacing: 14) {
                        ForEach(FoldStyle.allCases) { style in
                            StyleCard(style: style, selected: settings.appearanceStyle == style) {
                                withAnimation(.easeOut(duration: 0.2)) { settings.apply(style: style) }
                            }
                        }
                    }
                }

                VStack(spacing: 14) {
                    AppearanceSlider(title: "Perspective", value: $settings.perspective)
                    AppearanceSlider(title: "Variable blur", value: $settings.variableBlur)
                    AppearanceSlider(title: "Shadow", value: $settings.shadow)
                }
                .padding(16)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(FoldyTheme.cyan.opacity(0.16), lineWidth: 1)
                }

                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Clear at \(Int(settings.clearAngle))°").font(.headline)
                        Text("The effect disappears once the lid opens past this angle.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Slider(value: $settings.clearAngle, in: 105...150, step: 1).frame(width: 180)
                }

                HStack {
                    Spacer()
                    Button("Reset Appearance") { settings.resetAppearance() }
                }
            }
            .padding(28)
        }
        .navigationTitle("Appearance")
    }
}

private struct MacBookPreview: View {
    let state: FoldState
    let appearance: FoldAppearance

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 18, style: .continuous).fill(.black)
                FoldMetalView(state: state, appearance: appearance)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous)).padding(9)
                UnevenRoundedRectangle(bottomLeadingRadius: 7, bottomTrailingRadius: 7)
                    .fill(.black).frame(width: 78, height: 15)
            }
            .aspectRatio(16 / 10, contentMode: .fit)

            ZStack(alignment: .top) {
                Capsule().fill(.black.opacity(0.28)).frame(height: 8).blur(radius: 5).offset(y: 4)
                UnevenRoundedRectangle(bottomLeadingRadius: 8, bottomTrailingRadius: 8)
                    .fill(.gray.opacity(0.52)).frame(height: 13)
                Capsule().fill(.black.opacity(0.28)).frame(width: 74, height: 5)
            }
            .padding(.horizontal, -18)
        }
        .shadow(color: .black.opacity(0.24), radius: 18, y: 10)
    }
}

private struct StyleCard: View {
    let style: FoldStyle
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous).fill(background)
                    Image(systemName: icon)
                        .font(.system(size: 30, weight: .light)).foregroundStyle(.white.opacity(0.88))
                }
                .frame(height: 78)
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(selected ? FoldyTheme.blue : .white.opacity(0.1), lineWidth: selected ? 3 : 1)
                }

                HStack(spacing: 5) {
                    Text(style.displayName)
                    if selected { Image(systemName: "checkmark.circle.fill").foregroundStyle(FoldyTheme.blue) }
                }
                .font(.callout.weight(.medium))
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }

    private var icon: String {
        switch style { case .silk: "wave.3.right"; case .shade: "circle.lefthalf.filled"; case .frost: "snowflake" }
    }

    private var background: LinearGradient {
        switch style {
        case .silk: LinearGradient(colors: [FoldyTheme.blue, FoldyTheme.indigo], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .shade: LinearGradient(colors: [.gray.opacity(0.9), .black], startPoint: .top, endPoint: .bottom)
        case .frost: LinearGradient(colors: [FoldyTheme.cyan.opacity(0.82), FoldyTheme.blue.opacity(0.55), .white.opacity(0.9)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

private struct AppearanceSlider: View {
    let title: String
    @Binding var value: Double

    var body: some View {
        HStack {
            Text(title).frame(width: 110, alignment: .leading)
            Slider(value: $value, in: 0...1)
            Text(value, format: .percent.precision(.fractionLength(0)))
                .monospacedDigit().foregroundStyle(.secondary).frame(width: 48, alignment: .trailing)
        }
    }
}

private struct AboutSettingsView: View {
    var body: some View {
        VStack(spacing: 14) {
            Image(nsImage: NSApplication.shared.applicationIconImage)
                .resizable().frame(width: 112, height: 112)
            Text("Foldy").font(.largeTitle.bold())
            Text("Make your desktop fold.").font(.title3).foregroundStyle(.secondary)
            Text("Version 1.0")
            Text("Private by design. Frames stay on your Mac and are never saved.")
                .font(.callout).foregroundStyle(.secondary).multilineTextAlignment(.center)
                .frame(maxWidth: 360)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("About")
    }
}
