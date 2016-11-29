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

struct SquareSession: SessionProtocol
{
    func producer(for request: Int) -> SignalProducer<Int, NoError>
    {
        return SignalProducer(value: request * request)
    }
}

struct ErrorSession: SessionProtocol
{
    func producer(for request: Int) -> SignalProducer<Int, TestError>
    {
        return SignalProducer(error: TestError(value: request))
    }
}

struct TestError: Error
{
    let value: Int
}
