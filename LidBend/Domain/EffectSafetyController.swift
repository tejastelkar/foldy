import Foundation

struct EffectSafetyController: Sendable {
    private let mapper: FoldStateMapper
    private let staleAfter: TimeInterval
    private var lastValidSampleTime: TimeInterval?

    private(set) var currentState: FoldState = .hidden

    init(mapper: FoldStateMapper = FoldStateMapper(), staleAfter: TimeInterval = 0.75) {
        self.mapper = mapper
        self.staleAfter = max(staleAfter, 0)
    }

    mutating func ingest(angle: Double, at time: TimeInterval) -> FoldState {
        guard angle.isFinite, (0...180).contains(angle), time.isFinite else {
            return stop()
        }

        lastValidSampleTime = time
        currentState = mapper.state(for: angle, previousVisible: currentState.isVisible)
        return currentState
    }

    mutating func tick(at time: TimeInterval) -> FoldState? {
        guard currentState.isVisible,
              let lastValidSampleTime,
              time - lastValidSampleTime > staleAfter
        else { return nil }

        return stop()
    }

    mutating func stop() -> FoldState {
        lastValidSampleTime = nil
        currentState = .hidden
        return .hidden
    }
}
