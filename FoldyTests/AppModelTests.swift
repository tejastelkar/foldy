import XCTest
@testable import Foldy

@MainActor
final class AppModelTests: XCTestCase {
    func testSetEnabledChangesPublishedState() {
        let model = AppModel()

        XCTAssertFalse(model.isEnabled)
        model.setEnabled(true)
        XCTAssertTrue(model.isEnabled)
    }

    func testAppearanceConfigurationReachesOverlay() {
        let overlay = RecordingOverlay()
        let model = AppModel(sensor: PreviewAngleProvider(), overlay: overlay)

        model.configure(clearAngle: 135, appearance: .frost, playOpeningSound: false)

        XCTAssertEqual(overlay.appearance, .frost)
    }

    func testRapidToggleCoalescesLifecycleTransitions() async {
        let sensor = RecordingSensor()
        let model = AppModel(sensor: sensor, overlay: RecordingOverlay())

        model.setEnabled(true)
        model.setEnabled(false)
        model.setEnabled(true)
        for _ in 0..<5 { await Task.yield() }

        XCTAssertTrue(model.isEnabled)
        XCTAssertTrue(sensor.isRunning)
        XCTAssertEqual(sensor.startCount, 1)
        XCTAssertEqual(sensor.stopCount, 0)

        model.setEnabled(false)
        for _ in 0..<5 { await Task.yield() }

        XCTAssertFalse(model.isEnabled)
        XCTAssertFalse(sensor.isRunning)
        XCTAssertEqual(sensor.startCount, 1)
        XCTAssertEqual(sensor.stopCount, 1)
    }

    func testSensorStreamEndingStopsTheEffect() async {
        let sensor = RecordingSensor()
        let overlay = RecordingOverlay()
        let model = AppModel(sensor: sensor, overlay: overlay)

        model.setEnabled(true)
        for _ in 0..<5 { await Task.yield() }
        XCTAssertTrue(model.isEnabled)

        sensor.finish()
        for _ in 0..<5 { await Task.yield() }

        XCTAssertFalse(model.isEnabled)
        XCTAssertFalse(overlay.isVisible)
        XCTAssertEqual(sensor.stopCount, 1)
    }
}

@MainActor
private final class RecordingOverlay: OverlayCoordinating {
    var isVisible = false
    var appearance: FoldAppearance = .silk

    func update(appearance: FoldAppearance) {
        self.appearance = appearance
    }

    func apply(_ state: FoldState) async throws {
        isVisible = state.isVisible
    }

    func dismissAll() async {
        isVisible = false
    }
}

@MainActor
private final class RecordingSensor: LidAngleProviding {
    let availability: SensorAvailability = .available
    private(set) var angles = AsyncStream<Double> { $0.finish() }
    private var continuation: AsyncStream<Double>.Continuation?
    private(set) var startCount = 0
    private(set) var stopCount = 0
    private(set) var isRunning = false

    func start() throws {
        startCount += 1
        isRunning = true
        let pair = AsyncStream.makeStream(of: Double.self)
        angles = pair.stream
        continuation = pair.continuation
    }

    func stop() {
        stopCount += 1
        isRunning = false
        continuation?.finish()
        continuation = nil
    }

    func finish() {
        continuation?.finish()
        continuation = nil
    }
}
