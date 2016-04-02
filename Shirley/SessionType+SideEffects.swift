// Shirley
// Written in 2016 by Nate Stedman <nate@natestedman.com>
//
// To the extent possible under law, the author(s) have dedicated all copyright and
// related and neighboring rights to this software to the public domain worldwide.
// This software is distributed without any warranty.
//
// You should have received a copy of the CC0 Public Domain Dedication along with
// this software. If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.

import ReactiveCocoa

extension SessionType
{
    // MARK: - Side-Effects

    /**
    Adds side-effect functions to a session's producers.

    - parameter started:   A function to evaluate every time a producer is started.
    - parameter next:      A function to evaluate every time a producer sends a `next` value.
    - parameter completed: A function to evaluate every time a producer completes.
    - parameter failed:    A function to evaluate every time a producer fails.
    */
    public func onProducer(
        started started: (Request -> ())? = nil,
        next: ((Request, Value) -> ())? = nil,
        completed: (Request -> ())? = nil,
        failed: ((Request, Error) -> ())? = nil)
        -> Session<Request, Value, Error>
    {
        return Session { request in
            self.producerForRequest(request).on(
                started: { started?(request) },
                next: { value in next?(request, value) },
                completed: { completed?(request) },
                failed: { error in failed?(request, error) }
            )
        }
    }
}

