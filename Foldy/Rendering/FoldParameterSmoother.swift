import Foundation

struct FoldParameterSmoother: Sendable {
    private(set) var value: FoldRenderParameters
    let responseTime: TimeInterval

    init(initial: FoldRenderParameters, responseTime: TimeInterval = 0.045) {
        value = initial
        self.responseTime = max(responseTime, 0.001)
    }

    mutating func step(
        toward target: FoldRenderParameters,
        elapsed: TimeInterval
    ) -> FoldRenderParameters {
        guard elapsed.isFinite, elapsed > 0 else { return value }

        let amount = Float(1 - exp(-elapsed / responseTime))
        value.progress += (target.progress - value.progress) * amount
        value.perspective += (target.perspective - value.perspective) * amount
        value.blur += (target.blur - value.blur) * amount
        value.dim += (target.dim - value.dim) * amount
        value.shadow += (target.shadow - value.shadow) * amount
        value.textureStrength += (target.textureStrength - value.textureStrength) * amount
        value.aspectRatio = target.aspectRatio
        value.styleMode = target.styleMode
        value.frost = target.frost
        return value
    }

    mutating func reset(to parameters: FoldRenderParameters) {
        value = parameters
    }
}
