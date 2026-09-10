import CoreGraphics

struct FoldState: Equatable, Sendable {
    let progress: CGFloat
    let perspective: CGFloat
    let blurRadius: CGFloat
    let dimAmount: CGFloat
    let isVisible: Bool

    static let hidden = FoldState(
        progress: 0,
        perspective: 0,
        blurRadius: 0,
        dimAmount: 0,
        isVisible: false
    )
}
