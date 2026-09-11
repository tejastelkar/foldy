import CoreGraphics
import XCTest
@testable import Foldy

final class RenderQualityPolicyTests: XCTestCase {
    func testLargeRetinaDisplayIsDownscaledToPerformanceBudget() {
        let policy = RenderQualityPolicy(maxLongEdge: 1_920)

        let size = policy.renderSize(sourceWidth: 2_560, sourceHeight: 1_664)

        XCTAssertEqual(size.width, 1_920)
        XCTAssertEqual(size.height, 1_248)
    }

    func testSmallerDisplayKeepsItsNativeResolution() {
        let policy = RenderQualityPolicy(maxLongEdge: 1_920)

        let size = policy.renderSize(sourceWidth: 1_440, sourceHeight: 900)

        XCTAssertEqual(size.width, 1_440)
        XCTAssertEqual(size.height, 900)
    }

    func testInvalidDimensionsReturnSafeFallback() {
        let policy = RenderQualityPolicy(maxLongEdge: 1_920)

        let size = policy.renderSize(sourceWidth: 0, sourceHeight: -1)

        XCTAssertEqual(size.width, 1)
        XCTAssertEqual(size.height, 1)
    }
}
