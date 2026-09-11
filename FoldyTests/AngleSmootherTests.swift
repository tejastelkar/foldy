import XCTest
@testable import Foldy

final class AngleSmootherTests: XCTestCase {
    func testExponentialSmoothingReducesSuddenJump() {
        var smoother = AngleSmoother(alpha: 0.25, staleAfter: 0.75)

        XCTAssertEqual(smoother.ingest(angle: 100, at: 0), 100)
        XCTAssertEqual(smoother.ingest(angle: 60, at: 0.1), 90)
    }

    func testInvalidReadingsAreRejected() {
        var smoother = AngleSmoother()

        XCTAssertNil(smoother.ingest(angle: -1, at: 0))
        XCTAssertNil(smoother.ingest(angle: 181, at: 0))
        XCTAssertNil(smoother.ingest(angle: .nan, at: 0))
    }

    func testReadingBecomesStaleAfterConfiguredInterval() {
        var smoother = AngleSmoother(alpha: 0.25, staleAfter: 0.75)
        _ = smoother.ingest(angle: 90, at: 10)

        XCTAssertFalse(smoother.isStale(at: 10.75))
        XCTAssertTrue(smoother.isStale(at: 10.751))
    }

    func testAdaptiveMotionIsIndependentOfSensorFrequency() {
        let thirtyHz = finalAngle(sampleRate: 30)
        let sixtyHz = finalAngle(sampleRate: 60)

        XCTAssertEqual(thirtyHz, sixtyHz, accuracy: 0.1)
    }

    private func finalAngle(sampleRate: Int) -> Double {
        var smoother = AngleSmoother(adaptive: true)
        var result = 110.0

        for sample in 0...sampleRate {
            let time = Double(sample) / Double(sampleRate)
            let angle = 110.0 - 15.0 * time
            result = smoother.ingest(angle: angle, at: time) ?? result
        }

        return result
    }
}
