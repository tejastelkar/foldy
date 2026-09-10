import AppKit
import Combine
import CoreGraphics
import SwiftUI

struct OnboardingView: View {
    private enum Page: Int, CaseIterable {
        case welcome, hinge, permission, ready

        var icon: String {
            switch self {
            case .welcome: "sparkles.rectangle.stack.fill"
            case .hinge: "macbook"
            case .permission: "hand.raised.fill"
            case .ready: "checkmark.seal.fill"
            }
        }
    }

    @ObservedObject var settings: AppSettings
    let sensorAvailability: SensorAvailability
    let onComplete: () -> Void
    let onOpenSettings: () -> Void

    @State private var page = Page.welcome
    @State private var permissionGranted = CGPreflightScreenCaptureAccess()
    private let permissionTimer = Timer.publish(every: 1.2, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Color(nsColor: .windowBackgroundColor).ignoresSafeArea()

            VStack(spacing: 0) {
                pageIndicator
                Spacer(minLength: 20)
                pageContent
                    .id(page)
                    .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .opacity))
                Spacer(minLength: 22)
                controls
            }
            .padding(34)
        }
        .frame(width: 620, height: 520)
        .tint(FoldyTheme.blue)
        .onReceive(permissionTimer) { _ in
            guard page == .permission else { return }
            permissionGranted = CGPreflightScreenCaptureAccess()
        }
        .onReceive(NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didActivateApplicationNotification)) { _ in
            permissionGranted = CGPreflightScreenCaptureAccess()
        }
    }

    private var pageIndicator: some View {
        HStack(spacing: 7) {
            ForEach(Page.allCases, id: \.rawValue) { item in
                Capsule()
                    .fill(item.rawValue <= page.rawValue ? Color.accentColor : Color.secondary.opacity(0.2))
                    .frame(width: item == page ? 28 : 8, height: 6)
                    .animation(.snappy(duration: 0.28), value: page)
            }
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var pageContent: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle().fill(.quaternary).frame(width: 96, height: 96)
                Circle().stroke(Color.white.opacity(0.12), lineWidth: 1).frame(width: 96, height: 96)
                Image(systemName: page.icon)
                    .font(.system(size: 42, weight: .regular))
                    .foregroundStyle(Color.accentColor)
            }

            Text(title).font(.system(size: 30, weight: .bold, design: .rounded))
            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 470)

            if page == .hinge { hingeStatus }
            if page == .permission { permissionControls }
            if page == .ready {
                Label("Silk, Shade, and the new Frost glass effect are ready.", systemImage: "wand.and.stars")
                    .font(.callout.weight(.medium))
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: Capsule())
            }
        }
    }

    private var hingeStatus: some View {
        HStack(spacing: 9) {
            Circle().fill(sensorAvailable ? FoldyTheme.mint : Color.orange).frame(width: 9, height: 9)
            Text(sensorAvailable ? "Hinge sensor ready — no tilt test required" : sensorMessage)
                .font(.callout.weight(.medium))
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
    }

    private var permissionControls: some View {
        VStack(spacing: 10) {
            Label(permissionGranted ? "Screen access is ready" : "Screen access is not enabled yet",
                  systemImage: permissionGranted ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .foregroundStyle(permissionGranted ? FoldyTheme.mint : Color.orange)
                .font(.callout.weight(.semibold))

            HStack(spacing: 10) {
                if !permissionGranted {
                    Button("Request Access") { permissionGranted = CGRequestScreenCaptureAccess() }
                        .buttonStyle(.borderedProminent)
                }
                Button("Open System Settings") { PrivacySettingsDestination.screenRecording.open() }
                    .buttonStyle(.bordered)
            }
        }
    }

    private var controls: some View {
        HStack {
            Button("Back") { move(to: page.rawValue - 1) }
                .opacity(page == .welcome ? 0 : 1)
                .disabled(page == .welcome)
            Spacer()
            if page == .ready {
                Button("Open Foldy Settings", action: onOpenSettings)
                Button("Start Using Foldy", action: onComplete).buttonStyle(.borderedProminent)
            } else {
                Button("Continue") { move(to: page.rawValue + 1) }.buttonStyle(.borderedProminent)
            }
        }
    }

    private func move(to rawValue: Int) {
        guard let next = Page(rawValue: rawValue) else { return }
        withAnimation(.snappy(duration: 0.3)) { page = next }
    }

    private var sensorAvailable: Bool {
        if case .available = sensorAvailability { return true }
        return false
    }

    private var sensorMessage: String {
        if case .unavailable(let reason) = sensorAvailability { return reason }
        return "Checking your MacBook hinge sensor…"
    }

    private var title: String {
        switch page {
        case .welcome: "Your desktop, in motion"
        case .hinge: "Lower the lid naturally"
        case .permission: "Private screen access"
        case .ready: "Foldy is ready"
        }
    }

    private var message: String {
        switch page {
        case .welcome: "Foldy gives your desktop a smooth, spatial response as your MacBook display moves."
        case .hinge: "There is nothing to calibrate. Foldy reads the built-in hinge sensor and follows it automatically when the effect is enabled."
        case .permission: "macOS requires Screen & System Audio Recording access so Foldy can display your live desktop inside the animation. Frames remain in memory and are never saved or uploaded."
        case .ready: "Choose a style, enable Foldy from the menu bar, and lower the display. Preview lets you test everything without moving the lid."
        }
    }
}
