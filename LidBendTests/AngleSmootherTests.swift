import XCTest
@testable import LidBend

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
}
