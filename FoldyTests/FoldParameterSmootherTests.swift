import CoreGraphics
import XCTest
@testable import Foldy

final class FoldParameterSmootherTests: XCTestCase {
    func testPresentationResponseIsIndependentOfDisplayRefreshRate() {
        let start = FoldRenderParameters(
            state: .hidden,
            appearance: .silk,
            viewportSize: CGSize(width: 1_600, height: 1_000)
        )
        let targetState = FoldState(
            progress: 1,
            perspective: 0.08,
            blurRadius: 12,
            dimAmount: 0.75,
            isVisible: true
        )
        let target = FoldRenderParameters(
            state: targetState,
            appearance: .frost,
            viewportSize: CGSize(width: 1_600, height: 1_000)
        )

        let thirtyHz = presentedValue(start: start, target: target, sampleRate: 30)
        let sixtyHz = presentedValue(start: start, target: target, sampleRate: 60)

        XCTAssertEqual(thirtyHz.progress, sixtyHz.progress, accuracy: 0.0001)
        XCTAssertEqual(thirtyHz.blur, sixtyHz.blur, accuracy: 0.0001)
        XCTAssertEqual(thirtyHz.dim, sixtyHz.dim, accuracy: 0.0001)
        XCTAssertEqual(thirtyHz.textureStrength, sixtyHz.textureStrength, accuracy: 0.0001)
    }

    func testPresentationResponseNeverOvershootsTarget() {
        let start = FoldRenderParameters(
            state: .hidden,
            appearance: .silk,
            viewportSize: CGSize(width: 1_600, height: 1_000)
        )
        let targetState = FoldState(
            progress: 0.6,
            perspective: 0.04,
            blurRadius: 6,
            dimAmount: 0.3,
            isVisible: true
        )
        let target = FoldRenderParameters(
            state: targetState,
            appearance: .silk,
            viewportSize: CGSize(width: 1_600, height: 1_000)
        )
        var smoother = FoldParameterSmoother(initial: start)

        let value = smoother.step(toward: target, elapsed: 0.5)

        XCTAssertGreaterThan(value.progress, 0)
        XCTAssertLessThanOrEqual(value.progress, target.progress)
        XCTAssertLessThanOrEqual(value.blur, target.blur)
        XCTAssertLessThanOrEqual(value.dim, target.dim)
    }

    private func presentedValue(
        start: FoldRenderParameters,
        target: FoldRenderParameters,
        sampleRate: Int
    ) -> FoldRenderParameters {
        var smoother = FoldParameterSmoother(initial: start)
        var value = start
        for _ in 0..<sampleRate {
            value = smoother.step(toward: target, elapsed: 0.1 / Double(sampleRate))
        }
        return value
    }
}
