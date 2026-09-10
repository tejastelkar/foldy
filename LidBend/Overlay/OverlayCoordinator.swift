import AppKit
import CoreGraphics
import MetalKit

@MainActor
final class OverlayCoordinator: OverlayCoordinating {
    private let captureService: ScreenCaptureServicing
    private var panel: NSPanel?
    private var renderer: FoldRenderer?
    private var frameTask: Task<Void, Never>?

    var isVisible: Bool { panel?.isVisible == true }

    init(captureService: ScreenCaptureServicing = ScreenCaptureService()) {
        self.captureService = captureService
    }

    func apply(_ state: FoldState) async throws {
        guard state.isVisible else {
            await dismissAll()
            return
        }

        if panel == nil {
            try await presentOverlay()
        }
        renderer?.update(state: state, viewportSize: panel?.contentView?.bounds.size ?? .zero)
    }

    func dismissAll() async {
        frameTask?.cancel()
        frameTask = nil
        await captureService.stop()
        panel?.orderOut(nil)
        panel = nil
        renderer = nil
    }

    private func presentOverlay() async throws {
        guard let screen = NSScreen.main,
              let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber
        else { throw ScreenCaptureError.displayUnavailable }

        let metalView = MTKView(frame: screen.frame, device: MTLCreateSystemDefaultDevice())
        metalView.autoresizingMask = [.width, .height]
        metalView.colorPixelFormat = .bgra8Unorm
        metalView.clearColor = MTLClearColorMake(0.006, 0.008, 0.014, 1)
        metalView.preferredFramesPerSecond = 60
        metalView.enableSetNeedsDisplay = false
        metalView.isPaused = false
        let renderer = try FoldRenderer(view: metalView)
        metalView.delegate = renderer

        try await captureService.start(displayID: CGDirectDisplayID(number.uint32Value))

        let panel = NSPanel(
            contentRect: screen.frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false,
            screen: screen
        )
        panel.level = .screenSaver
        panel.backgroundColor = .black
        panel.isOpaque = true
        panel.hasShadow = false
        panel.ignoresMouseEvents = true
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.contentView = metalView
        panel.orderFrontRegardless()

        self.panel = panel
        self.renderer = renderer
        let frames = captureService.frames
        frameTask = Task { [weak self] in
            for await frame in frames {
                guard !Task.isCancelled else { break }
                self?.renderer?.update(pixelBuffer: frame.pixelBuffer)
            }
        }
    }
}
