import Combine
import Foundation

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var isEnabled = false
    @Published private(set) var currentAngle: Double?
    @Published private(set) var sensorAvailability: SensorAvailability = .unknown
    @Published private(set) var errorMessage: String?

    private let sensor: LidAngleProviding
    private let overlay: OverlayCoordinating
    private var safety = EffectSafetyController()
    private var angleTask: Task<Void, Never>?
    private var staleTask: Task<Void, Never>?

    init(
        sensor: LidAngleProviding? = nil,
        overlay: OverlayCoordinating? = nil
    ) {
        let selectedSensor = sensor ?? HIDAngleProvider()
        self.sensor = selectedSensor
        self.overlay = overlay ?? OverlayCoordinator()
        sensorAvailability = selectedSensor.availability
    }

    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        if enabled {
            Task { await startEffect() }
        } else {
            Task { await stopEffect() }
        }
    }

    private func startEffect() async {
        errorMessage = nil
        do {
            try sensor.start()
            let angles = sensor.angles
            angleTask = Task { [weak self] in
                for await angle in angles {
                    guard let self, !Task.isCancelled else { break }
                    await self.consume(angle: angle)
                }
            }
            staleTask = Task { [weak self] in
                while !Task.isCancelled {
                    try? await Task.sleep(for: .milliseconds(250))
                    guard let self else { break }
                    await self.checkForStaleSensor()
                }
            }
        } catch {
            isEnabled = false
            errorMessage = error.localizedDescription
        }
    }

    private func consume(angle: Double) async {
        currentAngle = angle
        let state = safety.ingest(angle: angle, at: Date.timeIntervalSinceReferenceDate)
        do {
            try await overlay.apply(state)
        } catch {
            errorMessage = error.localizedDescription
            await stopEffect()
        }
    }

    private func checkForStaleSensor() async {
        if let state = safety.tick(at: Date.timeIntervalSinceReferenceDate) {
            try? await overlay.apply(state)
        }
    }

    private func stopEffect() async {
        isEnabled = false
        angleTask?.cancel()
        staleTask?.cancel()
        angleTask = nil
        staleTask = nil
        sensor.stop()
        _ = safety.stop()
        currentAngle = nil
        await overlay.dismissAll()
    }
}
