// Shirley
// Written in 2015 by Nate Stedman <nate@natestedman.com>
//
// To the extent possible under law, the author(s) have dedicated all copyright and
// related and neighboring rights to this software to the public domain worldwide.
// This software is distributed without any warranty.
//
// You should have received a copy of the CC0 Public Domain Dedication along with
// this software. If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.

import ReactiveCocoa
import Result
import Shirley
import XCTest

class SessionDeduplicationTests: XCTestCase
{
    /// Ensure that the delay session is working correctly for the other tests.
    func testDelaySession()
    {
        let delay = DelaySession(SquareSession())

        var next = Int?.None

        delay.producerForRequest(2).startWithNext({ next = $0 })
        XCTAssertNil(next)

        delay.advance()
        XCTAssertEqual(next, 4)
    }

    func testDeduplication()
    {
        var starts = 0
        let delay = DelaySession(SquareSession())
        let dedupe = delay.onProducer(started: { _ in starts += 1 }).deduplicatedSession()

        // start a producer twice, should only start an internal producer once
        let producer = dedupe.producerForRequest(2)
        producer.startWithNext({ _ in })
        producer.startWithNext({ _ in })
        XCTAssertEqual(starts, 1)

        // clear previous producers
        delay.advance()
        XCTAssertEqual(starts, 1)

        // start again, should start a new internal producer
        producer.startWithNext({ _ in })
        XCTAssertEqual(starts, 2)
        delay.advance()
    }

    func testSynchronousCompletion()
    {
        // ensure that we don't deadlock when completing a deduplicated session synchronously
        let session = SquareSession().deduplicatedSession()

        let expect = expectationWithDescription("Did not deadlock")

        BlockThread(block: {
            session.producerForRequest(2).start()
            expect.fulfill()
        }).start()

        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testBackgroundCompletion()
    {
        // session that performs work on a background thread
        let session = Session<Int, Int, NoError> { request in
            SignalProducer(value: request).delay(0.1, onScheduler: QueueScheduler(qos: QOS_CLASS_DEFAULT))
        }

        // count the number of starts - should only be one
        var starts = 0
        let dedupe = session.onProducer(started: { _ in starts += 1 }).deduplicatedSession()

        // start outer session producer twice
        let expect1 = expectationWithDescription("First Completed")
        let expect2 = expectationWithDescription("Second Completed")

        let producer = dedupe.producerForRequest(1)
        producer.startWithCompleted({ expect1.fulfill() })
        producer.startWithCompleted({ expect2.fulfill() })

        waitForExpectationsWithTimeout(1, handler: nil)
        XCTAssertEqual(starts, 1)
    }
}

final class DelaySession<Request, Value, Error: ErrorType>
{
    private let scheduler: TestScheduler
    private let backing: Request -> SignalProducer<Value, Error>

    init<Wrapped: SessionType where Wrapped.Request == Request, Wrapped.Value == Value, Wrapped.Error == Error>
        (_ session: Wrapped)
    {
        let scheduler = TestScheduler()

        backing = Session({ request in
            session.producerForRequest(request).delay(0.5, onScheduler: scheduler)
        }).producerForRequest

        self.scheduler = scheduler
    }

    func advance()
    {
        scheduler.advanceByInterval(1)
    }
}

extension DelaySession: SessionType
{
    func producerForRequest(request: Request) -> SignalProducer<Value, Error>
    {
        return backing(request)
    }
}

private class BlockThread: NSThread
{
    let block: () -> ()

    init(block: () -> ())
    {
        self.block = block
    }

    private override func main()
    {
        block()
    }
}
