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
import Shirley
import XCTest

struct StringDataSession<Error: ErrorType>: SessionType
{
    typealias Request = String
    typealias Value = NSData

    func producerForRequest(request: Request) -> SignalProducer<Value, Error>
    {
        return SignalProducer(value: (request as NSString).dataUsingEncoding(NSUTF8StringEncoding)!)
    }
}

class SessionJSONTests: XCTestCase
{
    func testDataJSON()
    {
        let session = StringDataSession<NSError>().JSONSession()

        let first = session.producerForRequest("{\"foo\":\"bar\"}").first()!
        XCTAssertEqual((first.value as? [String:String])!, ["foo": "bar"])
    }

    func testDataJSONFragment()
    {
        let session = StringDataSession<NSError>().JSONSession(.AllowFragments)

        let first = session.producerForRequest("\"foo\"").first()!
        XCTAssertEqual((first.value as? String)!, "foo")
    }

    func testMessageJSON()
    {
        let session = StringDataSession<NSError>()
            .map({ data in Message<Int, NSData>(response: 0, body: data) })
            .JSONSession()

        let first = session.producerForRequest("{\"foo\":\"bar\"}").first()!
        XCTAssertEqual((first.value?.body as? [String:String])!, ["foo": "bar"])
    }

    func testMessageJSONFragment()
    {
        let session = StringDataSession<NSError>()
            .map({ data in Message<Int, NSData>(response: 0, body: data) })
            .JSONSession(.AllowFragments)

        let first = session.producerForRequest("\"foo\"").first()!
        XCTAssertEqual((first.value?.body as? String)!, "foo")
    }
}