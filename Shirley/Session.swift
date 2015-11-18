// Shirley
// Written in 2015 by Nate Stedman <nate@natestedman.com>
//
// To the extent possible under law, the author(s) have dedicated all copyright and
// related and neighboring rights to this software to the public domain worldwide.
// This software is distributed without any warranty.
//
// You should have received a copy of the CC0 Public Domain Dedication along with
// this software. If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.

import Foundation
import ReactiveCocoa

/// A session type that wraps another `SessionType`, erasing its type.
public struct Session<Request, Value, Error: ErrorType>
{
    // MARK: - Initialization
    
    /**
    Initializes a session.
    
    - parameter URLSession: The URL session to use.
    - parameter transform:  The transformation function to use.
    */
    public init<Wrapped: SessionType where Wrapped.Request == Request, Wrapped.Value == Value, Wrapped.Error == Error>
        (session: Wrapped)
    {
        producerFunction = Wrapped.producerForRequest(session)
    }
    
    // MARK: - Properties
    
    /// Wraps the inner session without directly referencing its type.
    let producerFunction: Request -> SignalProducer<Value, Error>
}

extension Session: SessionType
{
    // MARK: - SessionType
    
    /**
    Converts a request into a `SignalProducer` value.
    
    - parameter request: The request.
    
    - returns: A signal producer for the request.
    */
    public func producerForRequest(request: Request) -> SignalProducer<Value, Error>
    {
        return producerFunction(request)
    }
}
