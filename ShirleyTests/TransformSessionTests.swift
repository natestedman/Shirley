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

class TransformSessionTests: XCTestCase
{
    func testTransformedValues()
    {
        let session = Session(session: SquareSession(), flattenStrategy: .Concat, transform: { result in
            SignalProducer(value: result * 2)
        })
        
        XCTAssertEqual(session.producerForRequest(2).first()?.value, 8)
    }
    
    func testTransformedErrors()
    {
        let session = Session(session: ErrorSession(), transformError: { error in
            SignalProducer(error: TestError(value: error.value + 1))
        })
        
        XCTAssertEqual(session.producerForRequest(2).first()?.error?.value, 3)
    }
}
