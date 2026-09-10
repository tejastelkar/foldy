import AppKit
import Foundation

@MainActor
enum FoldChime {
    private static let sound = NSSound(data: makeWaveData())

    static func play() {
        sound?.stop()
        sound?.play()
    }

    private static func makeWaveData() -> Data {
        let sampleRate = 44_100
        let duration = 0.24
        let sampleCount = Int(Double(sampleRate) * duration)
        var samples = [Int16]()
        samples.reserveCapacity(sampleCount)

        for index in 0..<sampleCount {
            let time = Double(index) / Double(sampleRate)
            let attack = min(time / 0.018, 1)
            let release = max(0, 1 - time / duration)
            let envelope = attack * release * release
            let first = sin(2 * .pi * 659.25 * time)
            let secondStart = max(0, time - 0.045)
            let second = time >= 0.045 ? sin(2 * .pi * 880 * secondStart) * 0.62 : 0
            samples.append(Int16(max(-1, min(1, (first + second) * envelope * 0.18)) * Double(Int16.max)))
        }

        let dataSize = UInt32(samples.count * MemoryLayout<Int16>.size)
        var data = Data()
        data.appendASCII("RIFF")
        data.appendLE(UInt32(36) + dataSize)
        data.appendASCII("WAVEfmt ")
        data.appendLE(UInt32(16))
        data.appendLE(UInt16(1))
        data.appendLE(UInt16(1))
        data.appendLE(UInt32(sampleRate))
        data.appendLE(UInt32(sampleRate * 2))
        data.appendLE(UInt16(2))
        data.appendLE(UInt16(16))
        data.appendASCII("data")
        data.appendLE(dataSize)
        samples.withUnsafeBytes { data.append(contentsOf: $0) }
        return data
    }
}

private extension Data {
    mutating func appendASCII(_ string: String) {
        append(string.data(using: .ascii)!)
    }

    mutating func appendLE<T: FixedWidthInteger>(_ value: T) {
        var littleEndian = value.littleEndian
        Swift.withUnsafeBytes(of: &littleEndian) { append(contentsOf: $0) }
    }
}
