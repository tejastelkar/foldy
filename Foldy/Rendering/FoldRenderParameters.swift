import CoreGraphics

struct FoldRenderParameters: Equatable, Sendable {
    var progress: Float
    var perspective: Float
    var blur: Float
    var dim: Float
    var aspectRatio: Float
    var shadow: Float
    var styleMode: Float
    var frost: Float

    init(state: FoldState, appearance: FoldAppearance, viewportSize: CGSize) {
        progress = Self.normalized(state.progress)
        perspective = Self.normalized(state.perspective / 0.08) * Self.normalized(appearance.perspective)
        blur = Self.normalized(state.blurRadius / 12) * Self.normalized(appearance.variableBlur)
        dim = Self.normalized(state.dimAmount / 0.75)
        shadow = Self.normalized(appearance.shadow)
        styleMode = switch appearance.style {
        case .silk: 0
        case .shade: 1
        case .frost: 2
        }
        frost = appearance.style == .frost ? 1 : 0

        let ratio = viewportSize.height > 0 ? viewportSize.width / viewportSize.height : 1
        aspectRatio = ratio.isFinite && ratio > 0 ? Float(ratio) : 1
    }

    private static func normalized(_ value: CGFloat) -> Float {
        guard value.isFinite else { return 0 }
        return Float(min(max(value, 0), 1))
    }

    private static func normalized(_ value: Double) -> Float {
        guard value.isFinite else { return 0 }
        return Float(min(max(value, 0), 1))
    }
}
