import XCTest
@testable import Foldy

final class HIDReportParserTests: XCTestCase {
    func testDecodesLittleEndianFeatureReport() {
        XCTAssertEqual(HIDReportParser.angle(from: [0x01, 0x5A, 0x00]), 90)
        XCTAssertEqual(HIDReportParser.angle(from: [0x01, 0xB4, 0x00]), 180)
    }

    func testRejectsMalformedReports() {
        XCTAssertNil(HIDReportParser.angle(from: [0x01, 0x5A]))
        XCTAssertNil(HIDReportParser.angle(from: [0x02, 0x5A, 0x00]))
        XCTAssertNil(HIDReportParser.angle(from: [0x01, 0xB5, 0x00]))
    }
}
