import CoreGraphics

struct RenderQualityPolicy: Equatable, Sendable {
    let maxLongEdge: Int

    init(maxLongEdge: Int = 1_920) {
        self.maxLongEdge = max(maxLongEdge, 1)
    }

    func renderSize(sourceWidth: Int, sourceHeight: Int) -> CGSize {
        guard sourceWidth > 0, sourceHeight > 0 else {
            return CGSize(width: 1, height: 1)
        }

        let longEdge = max(sourceWidth, sourceHeight)
        let scale = min(1, Double(maxLongEdge) / Double(longEdge))
        return CGSize(
            width: max(1, Int((Double(sourceWidth) * scale).rounded())),
            height: max(1, Int((Double(sourceHeight) * scale).rounded()))
        )
    }
}
