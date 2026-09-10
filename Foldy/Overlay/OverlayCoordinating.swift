import Foundation

@MainActor
protocol OverlayCoordinating: AnyObject {
    var isVisible: Bool { get }
    func update(appearance: FoldAppearance)
    func apply(_ state: FoldState) async throws
    func dismissAll() async
}
