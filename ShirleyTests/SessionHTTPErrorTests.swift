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

private struct HTTPErrorSession: SessionProtocol
{
    func producer(for request: (Int, String)) -> SignalProducer<Message<HTTPURLResponse, String>, NSError>
    {
        return SignalProducer(value: Message(
            response: HTTPURLResponse(
                url: URL(string: "http://test.com")!,
                statusCode: request.0,
                httpVersion: nil,
                headerFields: nil
            )!,
            body: request.1
        ))
    }
}

class SessionHTTPErrorTests: XCTestCase
{
    func testValidResponseCode()
    {
        let session = HTTPErrorSession().raiseHTTPErrors()

        let first = session.producer(for: (200, "test")).first()!
        XCTAssertEqual(first.value?.body, "test")
    }

    func testInvalidResponseCode()
    {
        let session = HTTPErrorSession().raiseHTTPErrors()

        let first = session.producer(for: (400, "test")).first()!
        XCTAssertEqual(first.error?.domain, SessionHTTPErrorDomain)
        XCTAssertEqual(first.error?.code, 400)
    }

    func testInvalidResponseCodeCustomUserInfo()
    {
        let session = HTTPErrorSession().raiseHTTPErrors(userInfo: { _, body in ["body": body] })

        let first = session.producer(for: (400, "test")).first()!
        XCTAssertEqual(first.error?.userInfo["body"] as? String, "test")
    }

    func testInvalidResponseCodeCustomUserInfoLocalizedDescription()
    {
        let session = HTTPErrorSession().raiseHTTPErrors(userInfo: { _, body in [NSLocalizedDescriptionKey: body] })

        let first = session.producer(for: (400, "test")).first()!
        XCTAssertEqual(first.error?.userInfo[NSLocalizedDescriptionKey] as? String, "test")
    }
}
