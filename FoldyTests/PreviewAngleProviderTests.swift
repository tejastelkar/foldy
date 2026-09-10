import XCTest
@testable import Foldy

@MainActor
final class PreviewAngleProviderTests: XCTestCase {
    func testSentAnglesAreClampedAndPublished() async throws {
        let provider = PreviewAngleProvider()
        try provider.start()
        var iterator = provider.angles.makeAsyncIterator()

        provider.send(angle: 200)

        let received = await iterator.next()
        XCTAssertEqual(received, 180)
    }

    func testStopFinishesStream() async throws {
        let provider = PreviewAngleProvider()
        try provider.start()
        var iterator = provider.angles.makeAsyncIterator()

        provider.stop()

        let received = await iterator.next()
        XCTAssertNil(received)
    }
}
