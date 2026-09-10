import Combine
import Foundation

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var isEnabled = false

    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
    }
}
