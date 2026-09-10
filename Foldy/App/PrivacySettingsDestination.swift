import AppKit
import Foundation

enum PrivacySettingsDestination {
    case screenRecording

    var url: URL {
        switch self {
        case .screenRecording:
            URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!
        }
    }

    @discardableResult
    func open() -> Bool {
        if NSWorkspace.shared.open(url) {
            return true
        }

        NSWorkspace.shared.openApplication(
            at: URL(fileURLWithPath: "/System/Applications/System Settings.app"),
            configuration: NSWorkspace.OpenConfiguration()
        )
        return true
    }
}
