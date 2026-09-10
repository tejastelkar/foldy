import CoreGraphics

struct FoldRenderParameters: Equatable, Sendable {
    var progress: Float
    var perspective: Float
    var crease: Float
    var blur: Float
    var dim: Float
    var aspectRatio: Float
    var padding0: Float = 0
    var padding1: Float = 0

    init(state: FoldState, viewportSize: CGSize) {
        progress = Self.normalized(state.progress)
        perspective = Self.normalized(state.perspective / 0.08)
        crease = Self.normalized(state.crease)
        blur = Self.normalized(state.blurRadius / 12)
        dim = Self.normalized(state.dimAmount / 0.75)

        let ratio = viewportSize.height > 0 ? viewportSize.width / viewportSize.height : 1
        aspectRatio = ratio.isFinite && ratio > 0 ? Float(ratio) : 1
    }

    private static func normalized(_ value: CGFloat) -> Float {
        guard value.isFinite else { return 0 }
        return Float(min(max(value, 0), 1))
    }
}
