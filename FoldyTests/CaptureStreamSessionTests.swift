import CoreVideo
import XCTest
@testable import Foldy

final class CaptureStreamSessionTests: XCTestCase {
    func testFinishingOneSessionDoesNotFinishAnother() async {
        let first = CaptureStreamSession()
        let second = CaptureStreamSession()
        var firstIterator = first.frames.makeAsyncIterator()
        var secondIterator = second.frames.makeAsyncIterator()

        var pixelBuffer: CVPixelBuffer?
        CVPixelBufferCreate(
            kCFAllocatorDefault,
            1,
            1,
            kCVPixelFormatType_32BGRA,
            nil,
            &pixelBuffer
        )
        guard let pixelBuffer else {
            XCTFail("Could not create a test pixel buffer")
            return
        }
        let frame = CapturedFrame(pixelBuffer: pixelBuffer)

        first.finish()
        second.yield(frame)

        let firstValue = await firstIterator.next()
        let secondValue = await secondIterator.next()
        XCTAssertNil(firstValue)
        XCTAssertNotNil(secondValue)
    }
}
