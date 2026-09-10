import AppKit
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
    private var clearAngle = 135.0
    private var playOpeningSound = true
    private var wasVisible = false
    private var angleTask: Task<Void, Never>?
    private var staleTask: Task<Void, Never>?
    private var lifecycleTask: Task<Void, Never>?
    private var lifecycleID = UUID()

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
        guard enabled != isEnabled || lifecycleTask != nil else { return }

        lifecycleTask?.cancel()
        let requestID = UUID()
        lifecycleID = requestID
        isEnabled = enabled

        if enabled {
            lifecycleTask = Task { [weak self] in
                await self?.startEffect(requestID: requestID)
                self?.finishLifecycle(requestID: requestID)
            }
        } else {
            lifecycleTask = Task { [weak self] in
                await self?.stopEffect(requestID: requestID)
                self?.finishLifecycle(requestID: requestID)
            }
        }
    }

    func configure(clearAngle: Double, appearance: FoldAppearance, playOpeningSound: Bool) {
        self.clearAngle = min(max(clearAngle, 90), 150)
        self.playOpeningSound = playOpeningSound
        overlay.update(appearance: appearance)
        guard !isEnabled else { return }
        safety = EffectSafetyController(
            mapper: FoldStateMapper(openAngle: self.clearAngle, closedAngle: 12, hysteresis: 3)
        )
    }

    func updateAppearance(_ appearance: FoldAppearance) {
        overlay.update(appearance: appearance)
    }

    private func startEffect(requestID: UUID) async {
        guard requestID == lifecycleID, isEnabled, !Task.isCancelled else { return }

        errorMessage = nil
        safety = EffectSafetyController(
            mapper: FoldStateMapper(openAngle: clearAngle, closedAngle: 12, hysteresis: 3)
        )
        do {
            try sensor.start()
            guard requestID == lifecycleID, isEnabled, !Task.isCancelled else {
                sensor.stop()
                return
            }

            let angles = sensor.angles
            angleTask = Task { [weak self] in
                for await angle in angles {
                    guard let self, !Task.isCancelled else { break }
                    await self.consume(angle: angle)
                }
                guard let self, !Task.isCancelled else { return }
                await self.stopEffect(requestID: requestID)
            }
            staleTask = Task { [weak self] in
                while !Task.isCancelled {
                    try? await Task.sleep(for: .milliseconds(250))
                    guard let self else { break }
                    await self.checkForStaleSensor()
                }
            }
        } catch {
            guard requestID == lifecycleID else { return }
            isEnabled = false
            errorMessage = error.localizedDescription
        }
    }

    private func consume(angle: Double) async {
        guard isEnabled else { return }

        currentAngle = angle
        let state = safety.ingest(angle: angle, at: Date.timeIntervalSinceReferenceDate)
        if wasVisible, !state.isVisible, playOpeningSound {
            FoldChime.play()
        }
        wasVisible = state.isVisible
        do {
            try await overlay.apply(state)
        } catch {
            guard isEnabled else { return }
            errorMessage = error.localizedDescription
            await stopEffect(requestID: lifecycleID)
        }
    }

    private func checkForStaleSensor() async {
        guard isEnabled else { return }

        if let state = safety.tick(at: Date.timeIntervalSinceReferenceDate) {
            try? await overlay.apply(state)
        }
    }

    private func stopEffect(requestID: UUID) async {
        guard requestID == lifecycleID else { return }

        isEnabled = false
        angleTask?.cancel()
        staleTask?.cancel()
        angleTask = nil
        staleTask = nil
        sensor.stop()
        _ = safety.stop()
        currentAngle = nil
        wasVisible = false
        await overlay.dismissAll()
    }

    private func finishLifecycle(requestID: UUID) {
        guard requestID == lifecycleID else { return }
        lifecycleTask = nil
    }
}
