import CoreGraphics
import XCTest
@testable import LidBend

final class FoldRenderParametersTests: XCTestCase {
    func testHiddenStateProducesFiniteIdentityParametersForZeroViewport() {
        let parameters = FoldRenderParameters(state: .hidden, viewportSize: .zero)

        XCTAssertEqual(parameters.progress, 0)
        XCTAssertEqual(parameters.perspective, 0)
        XCTAssertEqual(parameters.crease, 0)
        XCTAssertEqual(parameters.blur, 0)
        XCTAssertEqual(parameters.dim, 0)
        XCTAssertEqual(parameters.aspectRatio, 1)
    }

    func testClosedStateProducesClampedNormalizedParameters() {
        let state = FoldStateMapper().state(for: 12, previousVisible: true)
        let parameters = FoldRenderParameters(state: state, viewportSize: CGSize(width: 1600, height: 1000))

        for value in [parameters.progress, parameters.perspective, parameters.crease, parameters.blur, parameters.dim] {
            XCTAssertTrue((0...1).contains(value))
            XCTAssertTrue(value.isFinite)
        }
        XCTAssertEqual(parameters.progress, 1)
        XCTAssertEqual(parameters.aspectRatio, 1.6, accuracy: 0.0001)
    }
}
