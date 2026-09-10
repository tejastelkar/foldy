import Foundation

enum EntitlementState: Equatable, Sendable {
    case checking
    case locked
    case unlocked
}

@MainActor
protocol EntitlementStore: AnyObject {
    var state: EntitlementState { get }
    func purchase() async throws
    func restore() async throws
}
