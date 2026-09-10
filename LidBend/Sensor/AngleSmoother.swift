import Foundation

struct AngleSmoother: Sendable {
    let alpha: Double
    let staleAfter: TimeInterval

    private var smoothedAngle: Double?
    private var lastValidSampleTime: TimeInterval?

    init(alpha: Double = 0.25, staleAfter: TimeInterval = 0.75) {
        self.alpha = min(max(alpha, 0), 1)
        self.staleAfter = max(staleAfter, 0)
    }

    mutating func ingest(angle: Double, at time: TimeInterval) -> Double? {
        guard angle.isFinite, (0...180).contains(angle), time.isFinite else { return nil }

        let next = smoothedAngle.map { $0 + alpha * (angle - $0) } ?? angle
        smoothedAngle = next
        lastValidSampleTime = time
        return next
    }

    func isStale(at time: TimeInterval) -> Bool {
        guard let lastValidSampleTime else { return true }
        return time - lastValidSampleTime > staleAfter
    }
}
