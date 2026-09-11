import AppKit
import CoreGraphics
import MetalKit

@MainActor
final class OverlayCoordinator: OverlayCoordinating {
    private let captureService: ScreenCaptureServicing
    private var panel: NSPanel?
    private var renderer: FoldRenderer?
    private var frameTask: Task<Void, Never>?
    private var appearance: FoldAppearance = .silk
    private let presentationGate = OverlayPresentationGate()
    private var pendingState: FoldState?

    var isVisible: Bool { panel?.isVisible == true }

    init(captureService: ScreenCaptureServicing = ScreenCaptureService()) {
        self.captureService = captureService
    }

    func update(appearance: FoldAppearance) {
        self.appearance = appearance
    }

    func apply(_ state: FoldState) async throws {
        pendingState = state
        guard state.isVisible else {
            await dismissAll()
            return
        }

        if panel == nil {
            guard let token = presentationGate.begin() else { return }
            defer {
                let committed = presentationGate.finish(token)
                if !committed {
                    schedulePendingPresentationIfNeeded()
                }
            }
            try await presentOverlay(token: token)
            guard presentationGate.isCurrent(token) else { return }
        }
        guard let latestState = pendingState, latestState.isVisible else { return }
        updateRenderer(with: latestState)
    }

    func dismissAll() async {
        pendingState = nil
        presentationGate.invalidate()
        frameTask?.cancel()
        frameTask = nil
        await captureService.stop()
        panel?.orderOut(nil)
        panel = nil
        renderer = nil
    }

    private func presentOverlay(token: UUID) async throws {
        guard let screen = NSScreen.main,
              let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber
        else { throw ScreenCaptureError.displayUnavailable }

        let displayID = CGDirectDisplayID(number.uint32Value)
        let renderSize = RenderQualityPolicy().renderSize(
            sourceWidth: Int(CGDisplayPixelsWide(displayID)),
            sourceHeight: Int(CGDisplayPixelsHigh(displayID))
        )
        let metalView = MTKView(frame: screen.frame, device: MTLCreateSystemDefaultDevice())
        metalView.autoresizingMask = [.width, .height]
        metalView.autoResizeDrawable = false
        metalView.drawableSize = renderSize
        metalView.colorPixelFormat = .bgra8Unorm
        metalView.clearColor = MTLClearColorMake(0.006, 0.008, 0.014, 1)
        metalView.preferredFramesPerSecond = 60
        metalView.enableSetNeedsDisplay = false
        metalView.isPaused = false
        metalView.layer?.magnificationFilter = .linear
        let renderer = try FoldRenderer(view: metalView)
        metalView.delegate = renderer

        try await captureService.start(displayID: displayID)

        guard presentationGate.isCurrent(token), pendingState?.isVisible == true else {
            await captureService.stop()
            return
        }

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
            guard !Task.isCancelled else { return }
            await self?.dismissAll()
        }
    }

    private func updateRenderer(with state: FoldState) {
        renderer?.update(
            state: state,
            appearance: appearance,
            viewportSize: panel?.contentView?.bounds.size ?? .zero
        )
    }

    private func schedulePendingPresentationIfNeeded() {
        guard panel == nil, pendingState?.isVisible == true else { return }

        Task { @MainActor [weak self] in
            guard let self,
                  !self.presentationGate.isPresenting,
                  let state = self.pendingState,
                  state.isVisible
            else { return }

            try? await self.apply(state)
        }
    }
}
