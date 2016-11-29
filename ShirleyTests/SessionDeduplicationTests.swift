// Shirley
// Written in 2015 by Nate Stedman <nate@natestedman.com>
//
// To the extent possible under law, the author(s) have dedicated all copyright and
// related and neighboring rights to this software to the public domain worldwide.
// This software is distributed without any warranty.
//
// You should have received a copy of the CC0 Public Domain Dedication along with
// this software. If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.

import ReactiveSwift
import Result
import Shirley
import XCTest

class SessionDeduplicationTests: XCTestCase
{
    /// Ensure that the delay session is working correctly for the other tests.
    func testDelaySession()
    {
        let delay = DelaySession(SquareSession())

        var next = Int?.none

        delay.producer(for: 2).startWithValues({ next = $0 })
        XCTAssertNil(next)

        delay.advance()
        XCTAssertEqual(next, 4)
    }

    func testDeduplication()
    {
        var starts = 0
        let delay = DelaySession(SquareSession())
        let dedupe = delay.mapProducers({ p in p.on(started: { _ in starts += 1 }) }).deduplicated

        // start a producer twice, should only start an internal producer once
        let producer = dedupe.producer(for: 2)
        producer.startWithValues({ _ in })
        producer.startWithValues({ _ in })
        XCTAssertEqual(starts, 1)

        // clear previous producers
        delay.advance()
        XCTAssertEqual(starts, 1)

        // start again, should start a new internal producer
        producer.startWithValues({ _ in })
        XCTAssertEqual(starts, 2)
        delay.advance()
    }

    func testSynchronousCompletion()
    {
        // ensure that we don't deadlock when completing a deduplicated session synchronously
        let session = SquareSession().deduplicated

        let expect = expectation(description: "Did not deadlock")

        BlockThread(block: {
            session.producer(for: 2).start()
            expect.fulfill()
        }).start()

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testBackgroundCompletion()
    {
        // session that performs work on a background thread
        let session = Session<Int, Int, NoError> { request in
            SignalProducer(value: request).delay(0.1, on: QueueScheduler(qos: .default))
        }

        // count the number of starts - should only be one
        var starts = 0
        let dedupe = session.mapProducers({ p in p.on(started: { _ in starts += 1 }) }).deduplicated

        // start outer session producer twice
        let expect1 = expectation(description: "First Completed")
        let expect2 = expectation(description: "Second Completed")

        let producer = dedupe.producer(for: 1)
        producer.startWithCompleted({ expect1.fulfill() })
        producer.startWithCompleted({ expect2.fulfill() })

        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertEqual(starts, 1)
    }
}

final class DelaySession<Request, Value, Error: Swift.Error>
{
    fileprivate let scheduler: TestScheduler
    fileprivate let backing: (Request) -> SignalProducer<Value, Error>

    init<Wrapped: SessionProtocol>
        (_ session: Wrapped) where Wrapped.Request == Request, Wrapped.Value == Value, Wrapped.Error == Error
    {
        let scheduler = TestScheduler()

        backing = Session({ request in
            session.producer(for: request).delay(0.5, on: scheduler)
        }).producer

        self.scheduler = scheduler
    }

    func advance()
    {
        scheduler.advance(by: 1)
    }
}

extension DelaySession: SessionProtocol
{
    func producer(for request: Request) -> SignalProducer<Value, Error>
    {
        return backing(request)
    }
}

private class BlockThread: Thread
{
    let block: () -> ()

    init(block: @escaping () -> ())
    {
        self.block = block
    }

    fileprivate override func main()
    {
        block()
    }
}
