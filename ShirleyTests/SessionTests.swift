// Shirley
// Written in 2015 by Nate Stedman <nate@natestedman.com>
//
// To the extent possible under law, the author(s) have dedicated all copyright and
// related and neighboring rights to this software to the public domain worldwide.
// This software is distributed without any warranty.
//
// You should have received a copy of the CC0 Public Domain Dedication along with
// this software. If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.

import Shirley
import XCTest

class SessionTests: XCTestCase
{
    func testWrappedValue()
    {
        let wrapped = SquareSession()
        let session = Session(wrapped)
        
        XCTAssertNotNil(wrapped.producerForRequest(2).first()?.value)
        XCTAssertNotNil(session.producerForRequest(2).first()?.value)
        
        XCTAssertEqual(
            wrapped.producerForRequest(2).first()?.value,
            session.producerForRequest(2).first()?.value
        )
    }
    
    func testWrappedError()
    {
        let wrapped = ErrorSession()
        let session = Session(wrapped)
        
        XCTAssertNotNil(wrapped.producerForRequest(2).first()?.error?.value)
        XCTAssertNotNil(session.producerForRequest(2).first()?.error?.value)
        
        XCTAssertEqual(
            wrapped.producerForRequest(2).first()?.error?.value,
            session.producerForRequest(2).first()?.error?.value
        )
    }
}
