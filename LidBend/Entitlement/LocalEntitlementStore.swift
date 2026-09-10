import Foundation

@MainActor
final class LocalEntitlementStore: EntitlementStore {
    private(set) var state: EntitlementState

    init(unlocked: Bool) {
        state = unlocked ? .unlocked : .locked
    }

    func purchase() async throws {
        state = .unlocked
    }

    func restore() async throws {
        state = .unlocked
    }
}
