import Foundation

struct AngleSmoother: Sendable {
    let alpha: Double
    let staleAfter: TimeInterval
    let adaptive: Bool

    private var smoothedAngle: Double?
    private var lastValidSampleTime: TimeInterval?
    private var lastRawAngle: Double?

    init(alpha: Double = 0.25, staleAfter: TimeInterval = 0.75, adaptive: Bool = false) {
        self.alpha = min(max(alpha, 0), 1)
        self.staleAfter = max(staleAfter, 0)
        self.adaptive = adaptive
    }

    mutating func ingest(angle: Double, at time: TimeInterval) -> Double? {
        guard angle.isFinite, (0...180).contains(angle), time.isFinite else { return nil }

        let next: Double
        if adaptive,
           let previous = smoothedAngle,
           let lastTime = lastValidSampleTime,
           let lastAngle = lastRawAngle,
           time > lastTime {
            let dt = max(time - lastTime, 0.001)
            let speed = abs(angle - lastAngle) / dt
            let speedFactor = min(speed / 45.0, 1.0)
            let responseTime = 0.11 - 0.085 * speedFactor
            let decay = exp(-dt / responseTime)
            let slope = (angle - lastAngle) / dt

            // Exact response for a linearly moving input. Unlike a per-sample
            // alpha, this feels the same at 30, 60, or irregular sensor rates.
            next = angle - slope * responseTime
                + (previous - lastAngle + slope * responseTime) * decay
        } else {
            next = smoothedAngle.map { $0 + alpha * (angle - $0) } ?? angle
        }
        smoothedAngle = next
        lastRawAngle = angle
        lastValidSampleTime = time
        return next
    }

    func isStale(at time: TimeInterval) -> Bool {
        guard let lastValidSampleTime else { return true }
        return time - lastValidSampleTime > staleAfter
    }
}
