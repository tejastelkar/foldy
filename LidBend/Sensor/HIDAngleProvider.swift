import Foundation
import IOKit.hid

@MainActor
final class HIDAngleProvider: LidAngleProviding {
    nonisolated private static let noOptions = IOOptionBits(kIOHIDOptionsTypeNone)

    private(set) var availability: SensorAvailability
    private(set) var angles = AsyncStream<Double> { $0.finish() }

    nonisolated(unsafe) private let device: IOHIDDevice?
    private var continuation: AsyncStream<Double>.Continuation?
    nonisolated(unsafe) private var timer: Timer?
    private var smoother = AngleSmoother()

    init() {
        if let device = Self.findDevice() {
            self.device = device
            availability = .available
        } else {
            device = nil
            availability = .unavailable(reason: "No compatible Apple lid-angle sensor was detected.")
        }
    }

    func start() throws {
        guard let device else { throw LidAngleProviderError.unavailable }
        guard timer == nil else { return }
        guard IOHIDDeviceOpen(device, Self.noOptions) == kIOReturnSuccess else {
            throw LidAngleProviderError.couldNotOpen
        }

        let pair = AsyncStream.makeStream(of: Double.self)
        angles = pair.stream
        continuation = pair.continuation
        smoother = AngleSmoother()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.poll()
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        continuation?.finish()
        continuation = nil
        if let device {
            IOHIDDeviceClose(device, Self.noOptions)
        }
    }

    private func poll() {
        guard let device else { return }
        var report = [UInt8](repeating: 0, count: 8)
        var length = CFIndex(report.count)
        let result = IOHIDDeviceGetReport(
            device,
            kIOHIDReportTypeFeature,
            1,
            &report,
            &length
        )

        guard result == kIOReturnSuccess,
              let angle = HIDReportParser.angle(from: Array(report.prefix(Int(length)))),
              let smoothed = smoother.ingest(angle: angle, at: Date.timeIntervalSinceReferenceDate)
        else { return }

        continuation?.yield(smoothed)
    }

    private static func findDevice() -> IOHIDDevice? {
        let manager = IOHIDManagerCreate(kCFAllocatorDefault, noOptions)
        guard IOHIDManagerOpen(manager, noOptions) == kIOReturnSuccess else { return nil }
        defer { IOHIDManagerClose(manager, noOptions) }

        let matching: [String: Any] = [
            kIOHIDVendorIDKey as String: 0x05AC,
            kIOHIDProductIDKey as String: 0x8104,
            kIOHIDDeviceUsagePageKey as String: 0x0020,
            kIOHIDDeviceUsageKey as String: 0x008A,
        ]
        IOHIDManagerSetDeviceMatching(manager, matching as CFDictionary)

        guard let devices = IOHIDManagerCopyDevices(manager) as? Set<IOHIDDevice> else {
            return nil
        }

        return devices.first(where: canReadAngle)
    }

    private static func canReadAngle(from device: IOHIDDevice) -> Bool {
        guard IOHIDDeviceOpen(device, noOptions) == kIOReturnSuccess else { return false }
        defer { IOHIDDeviceClose(device, noOptions) }

        var report = [UInt8](repeating: 0, count: 8)
        var length = CFIndex(report.count)
        let result = IOHIDDeviceGetReport(device, kIOHIDReportTypeFeature, 1, &report, &length)
        return result == kIOReturnSuccess && HIDReportParser.angle(from: Array(report.prefix(Int(length)))) != nil
    }

    deinit {
        let wasRunning = timer != nil
        timer?.invalidate()
        if wasRunning, let device {
            IOHIDDeviceClose(device, Self.noOptions)
        }
    }
}
