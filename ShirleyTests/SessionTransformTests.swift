// Shirley
// Written in 2015 by Nate Stedman <nate@natestedman.com>
//
// To the extent possible under law, the author(s) have dedicated all copyright and
// related and neighboring rights to this software to the public domain worldwide.
// This software is distributed without any warranty.
//
// You should have received a copy of the CC0 Public Domain Dedication along with
// this software. If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.

@testable import Shirley
import ReactiveCocoa
import XCTest

class SessionTransformTests: XCTestCase
{
    func testTransformedValues()
    {
        let session = SquareSession().flatMapValues(.Latest, transform: { result in
            SignalProducer(value: result * 2)
        })
        
        XCTAssertEqual(session.producerForRequest(2).first()?.value, 8)
    }
    
    func testTransformedErrors()
    {
        let session = ErrorSession().flatMapErrors({ error in
            SignalProducer(error: TestError(value: error.value + 1))
        })
        
        XCTAssertEqual(session.producerForRequest(2).first()?.error?.value, 3)
    }

    func testOnProducerSuccess()
    {
        var startCount = 0
        var nextCount = 0
        var completedCount = 0
        var errorCount = 0

        let session = SquareSession().onProducer(
            started: { _ in startCount++ },
            next: { _ in nextCount++ },
            completed: { _ in completedCount++ },
            failed: { _ in errorCount++ }
        )

        session.producerForRequest(2).start()

        XCTAssertEqual(startCount, 1)
        XCTAssertEqual(nextCount, 1)
        XCTAssertEqual(completedCount, 1)
        XCTAssertEqual(errorCount, 0)
    }

    func testOnProducerFailed()
    {
        var startCount = 0
        var nextCount = 0
        var completedCount = 0
        var errorCount = 0

        let session = ErrorSession().onProducer(
            started: { _ in startCount++ },
            next: { _ in nextCount++ },
            completed: { _ in completedCount++ },
            failed: { _ in errorCount++ }
        )

        session.producerForRequest(2).start()

        XCTAssertEqual(startCount, 1)
        XCTAssertEqual(nextCount, 0)
        XCTAssertEqual(completedCount, 0)
        XCTAssertEqual(errorCount, 1)
    }
}
