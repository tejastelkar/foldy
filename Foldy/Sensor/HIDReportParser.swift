import Foundation

enum HIDReportParser {
    static func angle(from bytes: [UInt8]) -> Double? {
        guard bytes.count >= 3, bytes[0] == 1 else { return nil }

        let rawValue = UInt16(bytes[2]) << 8 | UInt16(bytes[1])
        let angle = Double(rawValue)
        return (0...180).contains(angle) ? angle : nil
    }
}
