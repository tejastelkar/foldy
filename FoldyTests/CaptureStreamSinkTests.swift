import XCTest
@testable import Foldy

final class CaptureStreamSinkTests: XCTestCase {
    func testSlowConsumerReceivesOnlyNewestCapturedValue() async {
        let sink = AsyncStreamSink<Int>(bufferingPolicy: .bufferingNewest(1))
        var iterator = sink.stream.makeAsyncIterator()

        sink.yield(1)
        sink.yield(2)
        sink.yield(3)

        let newest = await iterator.next()
        XCTAssertEqual(newest, 3)
        sink.finish()
    }

    func testFinishRejectsValuesFromConcurrentProducers() async {
        let sink = AsyncStreamSink<Int>()
        var iterator = sink.stream.makeAsyncIterator()

        sink.finish()

        let producers = (0..<4).map { producer in
            Task.detached {
                for value in 0..<100 {
                    sink.yield(producer * 100 + value)
                }
            }
        }

        for producer in producers { await producer.value }

        let valueAfterFinish = await iterator.next()
        XCTAssertNil(valueAfterFinish)
        sink.yield(999)
        let valueAfterLateYield = await iterator.next()
        XCTAssertNil(valueAfterLateYield)
    }
}
