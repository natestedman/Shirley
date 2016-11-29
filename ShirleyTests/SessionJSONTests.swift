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
import Shirley
import XCTest

struct StringDataSession<Error: Swift.Error>: SessionProtocol
{
    typealias Request = String
    typealias Value = Data

    func producer(for request: Request) -> SignalProducer<Value, Error>
    {
        return SignalProducer(value: request.data(using: .utf8)!)
    }
}

class SessionJSONTests: XCTestCase
{
    func testDataJSON()
    {
        let session = StringDataSession<NSError>().json()

        let first = session.producer(for: "{\"foo\":\"bar\"}").first()!
        XCTAssertEqual((first.value as? [String:String])!, ["foo": "bar"])
    }

    func testDataJSONFragment()
    {
        let session = StringDataSession<NSError>().json(options: .allowFragments)

        let first = session.producer(for: "\"foo\"").first()!
        XCTAssertEqual((first.value as? String)!, "foo")
    }

    func testMessageJSON()
    {
        let session = StringDataSession<NSError>()
            .mapValues({ data in Message<Int, Data>(response: 0, body: data) })
            .json()

        let first = session.producer(for: "{\"foo\":\"bar\"}").first()!
        XCTAssertEqual((first.value?.body as? [String:String])!, ["foo": "bar"])
    }

    func testMessageJSONFragment()
    {
        let session = StringDataSession<NSError>()
            .mapValues({ data in Message<Int, Data>(response: 0, body: data) })
            .json(options: .allowFragments)

        let first = session.producer(for: "\"foo\"").first()!
        XCTAssertEqual((first.value?.body as? String)!, "foo")
    }
}
