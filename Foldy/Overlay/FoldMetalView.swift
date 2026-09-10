import MetalKit
import SwiftUI

struct FoldMetalView: NSViewRepresentable {
    let state: FoldState
    let appearance: FoldAppearance

    final class Coordinator {
        var renderer: FoldRenderer?
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> MTKView {
        let view = MTKView(frame: .zero, device: MTLCreateSystemDefaultDevice())
        view.colorPixelFormat = .bgra8Unorm
        view.clearColor = MTLClearColorMake(0.006, 0.008, 0.014, 1)
        view.preferredFramesPerSecond = 60
        view.enableSetNeedsDisplay = false
        view.isPaused = false

        if let renderer = try? FoldRenderer(view: view) {
            context.coordinator.renderer = renderer
            view.delegate = renderer
        }
        return view
    }

    func updateNSView(_ view: MTKView, context: Context) {
        context.coordinator.renderer?.update(state: state, appearance: appearance, viewportSize: view.drawableSize)
    }
}
