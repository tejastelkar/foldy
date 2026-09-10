import CoreGraphics
import CoreVideo
import Foundation

struct CapturedFrame: @unchecked Sendable {
    let pixelBuffer: CVPixelBuffer
}

enum ScreenCaptureError: LocalizedError {
    case permissionDenied
    case displayUnavailable

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            "Screen Recording permission is required for the live desktop effect."
        case .displayUnavailable:
            "The selected display is no longer available."
        }
    }
}

@MainActor
protocol ScreenCaptureServicing: AnyObject {
    var frames: AsyncStream<CapturedFrame> { get }
    var hasPermission: Bool { get }
    func start(displayID: CGDirectDisplayID) async throws
    func stop() async
}
