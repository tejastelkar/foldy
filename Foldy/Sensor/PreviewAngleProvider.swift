import Foundation

@MainActor
final class PreviewAngleProvider: LidAngleProviding {
    let availability: SensorAvailability = .available
    private(set) var angles = AsyncStream<Double> { $0.finish() }

    private var continuation: AsyncStream<Double>.Continuation?

    func start() throws {
        continuation?.finish()
        let pair = AsyncStream.makeStream(of: Double.self)
        angles = pair.stream
        continuation = pair.continuation
    }

    func send(angle: Double) {
        guard angle.isFinite else { return }
        continuation?.yield(min(max(angle, 0), 180))
    }

    func stop() {
        continuation?.finish()
        continuation = nil
    }
}
