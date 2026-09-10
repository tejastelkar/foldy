@preconcurrency import ScreenCaptureKit
import CoreGraphics
import CoreMedia
import CoreVideo
import Foundation

@MainActor
final class ScreenCaptureService: NSObject, ScreenCaptureServicing {
    private(set) var frames = AsyncStream<CapturedFrame> { $0.finish() }
    var hasPermission: Bool { CGPreflightScreenCaptureAccess() }

    private var stream: SCStream?
    nonisolated(unsafe) private var continuation: AsyncStream<CapturedFrame>.Continuation?
    private let outputQueue = DispatchQueue(label: "com.lidbend.capture", qos: .userInteractive)

    func start(displayID: CGDirectDisplayID) async throws {
        guard hasPermission else { throw ScreenCaptureError.permissionDenied }
        await stop()

        let content = try await SCShareableContent.excludingDesktopWindows(
            false,
            onScreenWindowsOnly: true
        )
        guard let display = content.displays.first(where: { $0.displayID == displayID }) else {
            throw ScreenCaptureError.displayUnavailable
        }

        let ownBundleID = Bundle.main.bundleIdentifier
        let excludedApplications = content.applications.filter { $0.bundleIdentifier == ownBundleID }
        let filter = SCContentFilter(
            display: display,
            excludingApplications: excludedApplications,
            exceptingWindows: []
        )
        let configuration = SCStreamConfiguration()
        configuration.width = display.width
        configuration.height = display.height
        configuration.minimumFrameInterval = CMTime(value: 1, timescale: 30)
        configuration.queueDepth = 3
        configuration.pixelFormat = kCVPixelFormatType_32BGRA
        configuration.showsCursor = true
        configuration.capturesAudio = false

        let pair = AsyncStream.makeStream(of: CapturedFrame.self)
        frames = pair.stream
        continuation = pair.continuation

        let stream = SCStream(filter: filter, configuration: configuration, delegate: self)
        try stream.addStreamOutput(self, type: .screen, sampleHandlerQueue: outputQueue)
        self.stream = stream
        try await stream.startCapture()
    }

    func stop() async {
        if let stream {
            try? await stream.stopCapture()
        }
        stream = nil
        continuation?.finish()
        continuation = nil
    }
}

extension ScreenCaptureService: SCStreamOutput, SCStreamDelegate {
    nonisolated func stream(
        _ stream: SCStream,
        didOutputSampleBuffer sampleBuffer: CMSampleBuffer,
        of outputType: SCStreamOutputType
    ) {
        guard outputType == .screen,
              sampleBuffer.isValid,
              let imageBuffer = sampleBuffer.imageBuffer
        else { return }

        continuation?.yield(CapturedFrame(pixelBuffer: imageBuffer))
    }

    nonisolated func stream(_ stream: SCStream, didStopWithError error: any Error) {
        continuation?.finish()
    }
}
