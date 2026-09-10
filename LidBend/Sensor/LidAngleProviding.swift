import Foundation

enum SensorAvailability: Equatable, Sendable {
    case unknown
    case available
    case unavailable(reason: String)
}

enum LidAngleProviderError: LocalizedError {
    case unavailable
    case couldNotOpen

    var errorDescription: String? {
        switch self {
        case .unavailable:
            "This Mac does not expose a compatible lid-angle sensor."
        case .couldNotOpen:
            "The lid-angle sensor could not be opened."
        }
    }
}

@MainActor
protocol LidAngleProviding: AnyObject {
    var availability: SensorAvailability { get }
    var angles: AsyncStream<Double> { get }
    func start() throws
    func stop()
}
