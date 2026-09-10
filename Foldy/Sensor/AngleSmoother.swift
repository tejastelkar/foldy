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

        let effectiveAlpha: Double
        if adaptive, let lastTime = lastValidSampleTime, let lastAngle = lastRawAngle, time > lastTime {
            let dt = max(time - lastTime, 0.001)
            let speed = abs(angle - lastAngle) / dt
            // Adaptive 1€ filter response:
            // High smoothing (alpha ~ 0.18) at rest, snappy tracking (alpha ~ 0.80) in motion
            let speedFactor = min(speed / 45.0, 1.0)
            effectiveAlpha = 0.18 + 0.62 * speedFactor
        } else {
            effectiveAlpha = alpha
        }

        let next = smoothedAngle.map { $0 + effectiveAlpha * (angle - $0) } ?? angle
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

