import Foundation

/// A restartable, thread-safe bridge from callback queues into an async stream.
///
/// ScreenCaptureKit invokes its output callbacks on a private queue while the
/// owning service starts and stops capture on the main actor. The lock protects
/// the continuation during that handoff and makes finish terminal for the
/// current stream.
final class AsyncStreamSink<Element: Sendable>: @unchecked Sendable {
    private let lock = NSLock()
    private var streamStorage: AsyncStream<Element>
    private var continuation: AsyncStream<Element>.Continuation?

    init() {
        let pair = AsyncStream.makeStream(of: Element.self)
        streamStorage = pair.stream
        continuation = pair.continuation
    }

    var stream: AsyncStream<Element> {
        lock.lock()
        defer { lock.unlock() }
        return streamStorage
    }

    func reset() -> AsyncStream<Element> {
        lock.lock()
        let oldContinuation = continuation
        let pair = AsyncStream.makeStream(of: Element.self)
        streamStorage = pair.stream
        continuation = pair.continuation
        lock.unlock()

        oldContinuation?.finish()
        return pair.stream
    }

    func yield(_ element: Element) {
        lock.lock()
        let currentContinuation = continuation
        lock.unlock()

        currentContinuation?.yield(element)
    }

    func finish() {
        lock.lock()
        let currentContinuation = continuation
        continuation = nil
        lock.unlock()

        currentContinuation?.finish()
    }
}
