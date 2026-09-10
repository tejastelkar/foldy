import CoreGraphics
import XCTest
@testable import Foldy

final class FoldRenderParametersTests: XCTestCase {
    func testHiddenStateProducesFiniteIdentityParametersForZeroViewport() {
        let parameters = FoldRenderParameters(state: .hidden, appearance: .silk, viewportSize: .zero)

        XCTAssertEqual(parameters.progress, 0)
        XCTAssertEqual(parameters.perspective, 0)
        XCTAssertEqual(parameters.blur, 0)
        XCTAssertEqual(parameters.dim, 0)
        XCTAssertEqual(parameters.aspectRatio, 1)
        XCTAssertEqual(parameters.shadow, 0.55)
        XCTAssertEqual(parameters.styleMode, 0)
    }

    func testClosedStateProducesClampedNormalizedParameters() {
        let state = FoldStateMapper().state(for: 12, previousVisible: true)
        let parameters = FoldRenderParameters(state: state, appearance: .silk, viewportSize: CGSize(width: 1600, height: 1000))

        for value in [parameters.progress, parameters.perspective, parameters.blur, parameters.dim, parameters.frost] {
            XCTAssertTrue((0...1).contains(value))
            XCTAssertTrue(value.isFinite)
        }
        XCTAssertEqual(parameters.progress, 1)
        XCTAssertEqual(parameters.aspectRatio, 1.6, accuracy: 0.0001)
    }

    func testAppearanceControlsScaleTheVisualParameters() {
        let state = FoldStateMapper().state(for: 12, previousVisible: true)
        let appearance = FoldAppearance(style: .frost, perspective: 0.4, variableBlur: 0.25, shadow: 0.8)

        let parameters = FoldRenderParameters(state: state, appearance: appearance, viewportSize: CGSize(width: 1600, height: 1000))

        XCTAssertEqual(parameters.perspective, 0.4, accuracy: 0.0001)
        XCTAssertEqual(parameters.blur, 0.25, accuracy: 0.0001)
        XCTAssertEqual(parameters.shadow, 0.8, accuracy: 0.0001)
        XCTAssertEqual(parameters.styleMode, 2)
        XCTAssertEqual(parameters.frost, 1)
    }

    func testOnlyFrostStyleEnablesFrostGlassProfile() {
        let state = FoldStateMapper().state(for: 61, previousVisible: true)

        let silk = FoldRenderParameters(state: state, appearance: .silk, viewportSize: CGSize(width: 1600, height: 1000))
        let shade = FoldRenderParameters(state: state, appearance: .shade, viewportSize: CGSize(width: 1600, height: 1000))
        let frost = FoldRenderParameters(state: state, appearance: .frost, viewportSize: CGSize(width: 1600, height: 1000))

        XCTAssertEqual(silk.frost, 0)
        XCTAssertEqual(shade.frost, 0)
        XCTAssertEqual(frost.frost, 1)
    }
}
