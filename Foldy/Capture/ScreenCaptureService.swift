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
    private var session: CaptureStreamSession?
    private let qualityPolicy = RenderQualityPolicy()
    private let outputQueue = DispatchQueue(label: "com.foldy.capture", qos: .userInteractive)

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
        let renderSize = qualityPolicy.renderSize(
            sourceWidth: display.width,
            sourceHeight: display.height
        )
        configuration.width = Int(renderSize.width)
        configuration.height = Int(renderSize.height)
        configuration.minimumFrameInterval = CMTime(value: 1, timescale: 60)
        configuration.queueDepth = 2
        configuration.pixelFormat = kCVPixelFormatType_32BGRA
        configuration.showsCursor = true
        configuration.capturesAudio = false
        configuration.scalesToFit = true
        configuration.preservesAspectRatio = true

        let session = CaptureStreamSession()
        frames = session.frames

        let stream = SCStream(filter: filter, configuration: configuration, delegate: session)
        try stream.addStreamOutput(session, type: .screen, sampleHandlerQueue: outputQueue)
        self.session = session
        self.stream = stream
        do {
            try await stream.startCapture()
        } catch {
            session.finish()
            self.session = nil
            self.stream = nil
            throw error
        }
    }

    func stop() async {
        session?.finish()
        if let stream {
            try? await stream.stopCapture()
        }
        session = nil
        stream = nil
    }
}

final class CaptureStreamSession: NSObject, @unchecked Sendable {
    let frames: AsyncStream<CapturedFrame>
    private let sink: AsyncStreamSink<CapturedFrame>

    override init() {
        let sink = AsyncStreamSink<CapturedFrame>(bufferingPolicy: .bufferingNewest(1))
        self.sink = sink
        frames = sink.stream
        super.init()
    }

    func yield(_ frame: CapturedFrame) {
        sink.yield(frame)
    }

    func finish() {
        sink.finish()
    }
}

extension CaptureStreamSession: SCStreamOutput, SCStreamDelegate {
    nonisolated func stream(
        _ stream: SCStream,
        didOutputSampleBuffer sampleBuffer: CMSampleBuffer,
        of outputType: SCStreamOutputType
    ) {
        guard outputType == .screen,
              sampleBuffer.isValid,
              let imageBuffer = sampleBuffer.imageBuffer
        else { return }

        yield(CapturedFrame(pixelBuffer: imageBuffer))
    }

    nonisolated func stream(_ stream: SCStream, didStopWithError error: any Error) {
        finish()
    }
}
