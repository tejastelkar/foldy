import Foundation

enum AppWindowKind: Hashable, Sendable {
    case onboarding
    case settings
    case preview
}

struct WindowPresentationGate: Sendable {
    private var claimed = Set<AppWindowKind>()

    mutating func claim(_ kind: AppWindowKind) -> Bool {
        claimed.insert(kind).inserted
    }

    mutating func release(_ kind: AppWindowKind) {
        claimed.remove(kind)
    }
}
