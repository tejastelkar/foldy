import AppKit
import SwiftUI

@MainActor
final class AppWindowCoordinator {
    private let model: AppModel
    private let settings: AppSettings
    private var windows: [AppWindowKind: NSWindow] = [:]
    private var gate = WindowPresentationGate()

    init(model: AppModel, settings: AppSettings) {
        self.model = model
        self.settings = settings
    }

    func showOnboarding() {
        present(.onboarding, title: "Welcome to Foldy", size: CGSize(width: 620, height: 520), resizable: false) { [weak self] in
            guard let self else { return AnyView(EmptyView()) }
            return AnyView(OnboardingView(
                settings: settings,
                sensorAvailability: model.sensorAvailability,
                onComplete: { [weak self] in self?.completeOnboarding() },
                onOpenSettings: { [weak self] in self?.completeOnboarding(openSettings: true) }
            ))
        }
    }

    func showSettings() {
        present(.settings, title: "Foldy Settings", size: CGSize(width: 880, height: 660), resizable: true) { [weak self] in
            guard let self else { return AnyView(EmptyView()) }
            return AnyView(SettingsRootView(
                model: model,
                settings: settings,
                showOnboarding: { [weak self] in self?.showOnboarding() }
            ))
        }
    }

    func showPreview() {
        present(.preview, title: "Fold Preview", size: CGSize(width: 688, height: 500), resizable: false) { [weak self] in
            guard let self else { return AnyView(EmptyView()) }
            return AnyView(PreviewView(appearance: settings.appearance))
        }
    }

    private func completeOnboarding(openSettings: Bool = false) {
        settings.hasCompletedOnboarding = true
        windows[.onboarding]?.close()
        if openSettings { showSettings() }
    }

    private func present(
        _ kind: AppWindowKind,
        title: String,
        size: CGSize,
        resizable: Bool,
        content: () -> AnyView
    ) {
        if let existing = windows[kind] {
            bringForward(existing)
            return
        }

        guard gate.claim(kind) else { return }
        var style: NSWindow.StyleMask = [.titled, .closable, .miniaturizable]
        if resizable { style.insert(.resizable) }
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: style,
            backing: .buffered,
            defer: false
        )
        window.identifier = NSUserInterfaceItemIdentifier("Foldy.\(kind)")
        window.title = title
        window.titlebarAppearsTransparent = true
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: content())
        window.center()
        windows[kind] = window
        bringForward(window)
    }

    private func bringForward(_ window: NSWindow) {
        window.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
}
