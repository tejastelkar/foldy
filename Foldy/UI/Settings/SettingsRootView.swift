import AppKit
import Combine
import CoreGraphics
import SwiftUI

struct SettingsRootView: View {
    private enum Destination: String, CaseIterable, Identifiable {
        case general = "General"
        case appearance = "Appearance"
        case support = "Support"
        case about = "About"

        var id: String { rawValue }
    }

    @ObservedObject var model: AppModel
    @ObservedObject var settings: AppSettings
    var showOnboarding: (() -> Void)?
    @State private var selection: Destination? = .appearance

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Section("Configuration") {
                    Label {
                        Text("General")
                    } icon: {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(.blue)
                    }
                    .tag(Destination.general)

                    Label {
                        Text("Appearance")
                    } icon: {
                        Image(systemName: "circle.lefthalf.filled")
                            .foregroundStyle(.purple)
                    }
                    .tag(Destination.appearance)
                }

                Section("Foldy") {
                    Label {
                        Text("Buy Me a Coffee")
                    } icon: {
                        Image(systemName: "cup.and.saucer.fill")
                            .foregroundStyle(.orange)
                    }
                    .tag(Destination.support)

                    Label {
                        Text("About")
                    } icon: {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(.gray)
                    }
                    .tag(Destination.about)
                }
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 190, ideal: 200, max: 230)
        } detail: {
            switch selection ?? .appearance {
            case .general: GeneralSettingsView(model: model, settings: settings, showOnboarding: showOnboarding)
            case .appearance: AppearanceSettingsView(model: model, settings: settings)
            case .support: SupportSettingsView()
            case .about: AboutSettingsView()
            }
        }
        .frame(minWidth: 840, minHeight: 620)
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
            Section("Hinge Kinetics") {
                Toggle("Enable Foldy", isOn: Binding(
                    get: { model.isEnabled },
                    set: {
                        settings.effectEnabled = $0
                        model.setEnabled($0)
                    }
                ))
                Text("Render physical depth and perspective when your MacBook lid moves.")
                    .font(.caption).foregroundStyle(.secondary)
            }

            Section("Startup & Sound") {
                Toggle("Launch Foldy at login", isOn: Binding(
                    get: { settings.launchAtLogin },
                    set: { enabled in updateLaunchAtLogin(enabled) }
                ))
                if let loginError { Text(loginError).font(.caption).foregroundStyle(.red) }

                Toggle("Play sound when desktop opens", isOn: $settings.playOpeningSound)
            }

            Section("Screen Recording & Privacy") {
                LabeledContent("Screen Access") {
                    Label(hasScreenAccess ? "Ready" : "Needs Access",
                          systemImage: hasScreenAccess ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundStyle(hasScreenAccess ? FoldyTheme.mint : Color.orange)
                }

                Button("Open System Settings") {
                    PrivacySettingsDestination.screenRecording.open()
                }

                if !hasScreenAccess {
                    Button("Request Screen Recording Access") {
                        _ = CGRequestScreenCaptureAccess()
                        PrivacySettingsDestination.screenRecording.open()
                    }
                    .buttonStyle(.borderedProminent)
                }

                if let showOnboarding {
                    Button("Show Setup Guide", action: showOnboarding)
                }
            }

            Section("Support Independent Development") {
                HStack(spacing: 12) {
                    Image(systemName: "cup.and.saucer.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(.orange)
                        .frame(width: 28, height: 28)
                        .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 7, style: .continuous))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Buy Me a Coffee")
                            .font(.body.weight(.medium))
                        Text("Support ongoing updates & Mac craftsmanship on Ko-fi")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button {
                        if let url = URL(string: "https://ko-fi.com/tejastelkar") {
                            NSWorkspace.shared.open(url)
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text("Support")
                            Image(systemName: "arrow.up.right")
                                .font(.caption2)
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
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
            VStack(alignment: .leading, spacing: 24) {
                // Interactive MacBook Display Preview
                MacBookPreview(state: previewState, appearance: settings.appearance)
                    .frame(maxWidth: 540).frame(height: 270).frame(maxWidth: .infinity)

                // Angle scrubber & Follow lid switch
                HStack(spacing: 12) {
                    Text("\(Int(displayedAngle.rounded()))°")
                        .font(.body.monospacedDigit().weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 44, alignment: .trailing)
                    Slider(value: $previewAngle, in: 12...150, step: 1)
                        .disabled(settings.followLid && model.currentAngle != nil)
                    Toggle("Follow lid", isOn: $settings.followLid)
                        .toggleStyle(.switch)
                }
                .padding(.horizontal, 4)

                // Material Profile Selector (Apple Appearance Style)
                VStack(alignment: .leading, spacing: 12) {
                    Text("Material Style")
                        .font(.headline.weight(.semibold))
                    HStack(spacing: 14) {
                        ForEach(FoldStyle.allCases) { style in
                            StyleCard(style: style, selected: settings.appearanceStyle == style) {
                                withAnimation(.snappy(duration: 0.22)) { settings.apply(style: style) }
                            }
                        }
                    }
                }

                // Optical Shaders Tuning Box
                VStack(spacing: 16) {
                    AppearanceSlider(icon: "cube.transparent", title: "Perspective", value: $settings.perspective)
                    AppearanceSlider(icon: "camera.aperture", title: "Variable Bokeh", value: $settings.variableBlur)
                    AppearanceSlider(icon: "sun.max", title: "Ridge Glint & Shadow", value: $settings.shadow)
                }
                .padding(18)
                .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                }

                // Fold Angle Exit
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Clear at \(Int(settings.clearAngle))°")
                            .font(.headline)
                        Text("The fold effect disappears smoothly once the lid opens past this angle.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Slider(value: $settings.clearAngle, in: 105...150, step: 1)
                        .frame(width: 170)
                }
                .padding(18)
                .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                }

                HStack {
                    Spacer()
                    Button("Reset to Defaults") {
                        settings.resetAppearance()
                    }
                    .controlSize(.small)
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
            // Display Lid with Apple aluminum bezel & notch
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(nsColor: .darkGray).opacity(0.85))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(0.18), lineWidth: 0.8)
                    }

                FoldMetalView(state: state, appearance: appearance)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .padding(8)

                // Camera Notch
                UnevenRoundedRectangle(bottomLeadingRadius: 5, bottomTrailingRadius: 5)
                    .fill(Color.black)
                    .frame(width: 64, height: 12)
                    .overlay {
                        Circle()
                            .fill(Color.white.opacity(0.18))
                            .frame(width: 3, height: 3)
                            .offset(y: -1)
                    }
            }
            .aspectRatio(16 / 10, contentMode: .fit)

            // Aluminum Hinge & Chassis Base
            ZStack(alignment: .top) {
                // Ground drop shadow
                Capsule()
                    .fill(Color.black.opacity(0.35))
                    .frame(height: 8)
                    .blur(radius: 6)
                    .offset(y: 4)

                // Anodized aluminum bottom lip
                UnevenRoundedRectangle(bottomLeadingRadius: 7, bottomTrailingRadius: 7)
                    .fill(LinearGradient(
                        colors: [Color(white: 0.42), Color(white: 0.32)],
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                    .frame(height: 11)
                    .overlay {
                        UnevenRoundedRectangle(bottomLeadingRadius: 7, bottomTrailingRadius: 7)
                            .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                    }

                // Thumb opener groove
                UnevenRoundedRectangle(bottomLeadingRadius: 3, bottomTrailingRadius: 3)
                    .fill(Color.black.opacity(0.4))
                    .frame(width: 68, height: 4)
            }
            .padding(.horizontal, -14)
        }
        .shadow(color: Color.black.opacity(0.32), radius: 22, y: 12)
    }
}

private struct StyleCard: View {
    let style: FoldStyle
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(cardSurface)

                    Image(systemName: icon)
                        .font(.system(size: 26, weight: .regular))
                        .foregroundStyle(selected ? Color.accentColor : .primary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    if selected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 15))
                            .foregroundStyle(Color.accentColor)
                            .padding(7)
                    }
                }
                .frame(height: 72)
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(selected ? Color.accentColor : Color.primary.opacity(0.08), lineWidth: selected ? 2 : 1)
                }

                VStack(spacing: 2) {
                    Text(style.displayName)
                        .font(.subheadline.weight(selected ? .semibold : .medium))
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }

    private var icon: String {
        switch style {
        case .silk: "sparkles"
        case .shade: "circle.lefthalf.filled"
        case .frost: "camera.filters"
        }
    }

    private var subtitle: String {
        switch style {
        case .silk: "Soft lens defocus"
        case .shade: "Physical shadow"
        case .frost: "Liquid glass sheen"
        }
    }

    private var cardSurface: some ShapeStyle {
        if selected {
            return AnyShapeStyle(Color.accentColor.opacity(0.12))
        }
        return AnyShapeStyle(Color(nsColor: .controlBackgroundColor))
    }
}

private struct AppearanceSlider: View {
    let icon: String
    let title: String
    @Binding var value: Double

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .frame(width: 16)
            Text(title).frame(width: 130, alignment: .leading)
            Slider(value: $value, in: 0...1)
            Text(value, format: .percent.precision(.fractionLength(0)))
                .monospacedDigit().foregroundStyle(.secondary).frame(width: 44, alignment: .trailing)
        }
    }
}

private struct SupportSettingsView: View {
    @State private var hovered = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                colors: [Color.orange, Color.red.opacity(0.85)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 72, height: 72)
                            .shadow(color: Color.orange.opacity(0.35), radius: 12, y: 6)

                        Image(systemName: "cup.and.saucer.fill")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundStyle(.white)
                    }

                    Text("Buy Me a Coffee")
                        .font(.title.bold())

                    Text("Foldy is an independent, ad-free Mac utility handcrafted with deep respect for macOS craftsmanship.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 460)
                }
                .padding(.top, 16)

                // Feature Highlights Card
                VStack(alignment: .leading, spacing: 14) {
                    SupportFeatureRow(
                        icon: "sparkles",
                        iconColor: .purple,
                        title: "Fuel Continuous Improvements",
                        description: "Your support funds new spatial shaders, multi-monitor features, and performance tuning."
                    )

                    Divider()

                    SupportFeatureRow(
                        icon: "lock.shield.fill",
                        iconColor: .green,
                        title: "100% Private & On-Device",
                        description: "Zero telemetry, zero user tracking, and no external servers. Frames never leave your Mac."
                    )

                    Divider()

                    SupportFeatureRow(
                        icon: "laptopcomputer",
                        iconColor: .blue,
                        title: "Native Apple Technologies",
                        description: "Engineered specifically for macOS with Metal 3D shaders, ScreenCaptureKit, and Force Touch haptics."
                    )
                }
                .padding(18)
                .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                }
                .frame(maxWidth: 480)

                // CTA Button
                VStack(spacing: 10) {
                    Button {
                        if let url = URL(string: "https://ko-fi.com/tejastelkar") {
                            NSWorkspace.shared.open(url)
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "cup.and.saucer.fill")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Buy Me a Coffee on Ko-fi")
                                .font(.body.weight(.semibold))
                            Image(systemName: "arrow.up.right")
                                .font(.caption.weight(.bold))
                        }
                        .padding(.horizontal, 22)
                        .padding(.vertical, 10)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                    .controlSize(.large)
                    .scaleEffect(hovered ? 1.02 : 1.0)
                    .animation(.snappy(duration: 0.2), value: hovered)
                    .onHover { isHovered in hovered = isHovered }

                    Text("https://ko-fi.com/tejastelkar")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .padding(.top, 8)
            }
            .padding(28)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Support Foldy")
    }
}

private struct SupportFeatureRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(iconColor)
                .frame(width: 32, height: 32)
                .background(iconColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body.weight(.medium))
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct AboutSettingsView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(nsImage: NSApplication.shared.applicationIconImage)
                    .resizable()
                    .frame(width: 96, height: 96)
                    .shadow(color: Color.black.opacity(0.2), radius: 10, y: 5)

                VStack(spacing: 4) {
                    Text("Foldy")
                        .font(.title.bold())
                    Text("Version 1.0 (Build 1)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Desktop depth & hinge kinetics for macOS")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Privacy & Architecture Chips
                HStack(spacing: 8) {
                    Label("Private by Design", systemImage: "shield.checkered")
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.quaternary, in: Capsule())

                    Label("Metal Accelerated", systemImage: "sparkles")
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.quaternary, in: Capsule())
                }

                Divider()
                    .frame(maxWidth: 360)
                    .padding(.vertical, 4)

                // Ko-fi Support Banner
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "cup.and.saucer.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(.orange)
                            .frame(width: 36, height: 36)
                            .background(Color.orange.opacity(0.15), in: RoundedRectangle(cornerRadius: 9, style: .continuous))

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Enjoying Foldy?")
                                .font(.headline)
                            Text("Consider buying me a coffee on Ko-fi to support continuous updates.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Button {
                            if let url = URL(string: "https://ko-fi.com/tejastelkar") {
                                NSWorkspace.shared.open(url)
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text("Support")
                                Image(systemName: "arrow.up.right")
                                    .font(.caption2)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.orange)
                        .controlSize(.small)
                    }
                }
                .padding(16)
                .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                }
                .frame(maxWidth: 440)

                Text("Frames stay on your Mac in memory and are never written to disk or transmitted.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 360)
            }
            .padding(28)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("About Foldy")
    }
}
