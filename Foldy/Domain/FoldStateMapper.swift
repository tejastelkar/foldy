import CoreGraphics
import Foundation

struct FoldStateMapper: Sendable {
    let openAngle: Double
    let closedAngle: Double
    let hysteresis: Double

    init(openAngle: Double = 110, closedAngle: Double = 12, hysteresis: Double = 3) {
        self.openAngle = openAngle
        self.closedAngle = closedAngle
        self.hysteresis = hysteresis
    }

    func state(for angle: Double, previousVisible: Bool) -> FoldState {
        guard angle.isFinite, openAngle > closedAngle else { return .hidden }

        let exitAngle = openAngle + (previousVisible ? hysteresis : 0)
        let isVisible = angle < exitAngle
        guard isVisible else { return .hidden }

        let rawProgress = (openAngle - angle) / (openAngle - closedAngle)
        let progress = CGFloat(min(max(rawProgress, 0), 1))
        let dim = 0.75 * smoothstep(edge0: 0.55, edge1: 1, value: progress)

        return FoldState(
            progress: progress,
            perspective: 0.08 * progress,
            blurRadius: 12 * progress * progress,
            dimAmount: dim,
            isVisible: true
        )
    }

    private func smoothstep(edge0: CGFloat, edge1: CGFloat, value: CGFloat) -> CGFloat {
        let x = min(max((value - edge0) / (edge1 - edge0), 0), 1)
        return x * x * (3 - 2 * x)
    }
}
