import AppKit
import CoreGraphics
import SwiftUI

struct OnboardingView: View {
    @ObservedObject var settings: AppSettings
    @State private var page = 0
    @State private var permissionGranted = CGPreflightScreenCaptureAccess()

    var body: some View {
        VStack(spacing: 22) {
            Image(systemName: page == 0 ? "macbook" : page == 1 ? "rectangle.inset.filled.and.person.filled" : "sparkles")
                .font(.system(size: 52, weight: .light))
                .foregroundStyle(.tint)

            Text(title)
                .font(.largeTitle.bold())

            Text(message)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 430)

            if page == 1 {
                Button(permissionGranted ? "Permission granted" : "Allow Screen Recording") {
                    permissionGranted = CGRequestScreenCaptureAccess()
                }
                .buttonStyle(.borderedProminent)
                .disabled(permissionGranted)

                Button("Open Privacy Settings") {
                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!)
                }
                .buttonStyle(.link)
            }

            HStack {
                if page > 0 {
                    Button("Back") { page -= 1 }
                }
                Spacer()
                Button(page == 2 ? "Done" : "Continue") {
                    if page == 2 {
                        settings.hasCompletedOnboarding = true
                        NSApplication.shared.keyWindow?.close()
                    } else {
                        page += 1
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(36)
        .frame(width: 540, height: 430)
    }

    private var title: String {
        ["Your desktop, physically alive", "One private permission", "Ready to bend"][page]
    }

    private var message: String {
        [
            "Foldy reads your MacBook hinge and makes the desktop tilt, blur, and settle as you lower the lid.",
            "Screen Recording lets Foldy render the desktop into the fold effect. Frames stay in memory, are never saved, and never leave your Mac.",
            "Turn on the effect from the menu bar. Use Preview whenever you want to test it without moving the lid."
        ][page]
    }
}
