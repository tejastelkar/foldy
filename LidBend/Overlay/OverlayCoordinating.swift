import Foundation

@MainActor
protocol OverlayCoordinating: AnyObject {
    var isVisible: Bool { get }
    func apply(_ state: FoldState) async throws
    func dismissAll() async
}
