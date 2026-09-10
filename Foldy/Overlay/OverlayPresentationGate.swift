import Foundation

/// Serializes overlay presentation and invalidates work that was superseded by
/// a dismissal. Presentation can suspend while ScreenCaptureKit starts, so a
/// token is required before the resulting panel is allowed to commit.
@MainActor
final class OverlayPresentationGate {
    private(set) var isPresenting = false
    private var currentToken = UUID()

    func begin() -> UUID? {
        guard !isPresenting else { return nil }
        let token = UUID()
        currentToken = token
        isPresenting = true
        return token
    }

    func invalidate() {
        currentToken = UUID()
    }

    func isCurrent(_ token: UUID) -> Bool {
        isPresenting && token == currentToken
    }

    @discardableResult
    func finish(_ token: UUID) -> Bool {
        guard isPresenting else { return false }
        isPresenting = false
        return token == currentToken
    }
}
