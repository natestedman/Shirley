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

/// A session type that uses a closure to convert requests to signal producers.
///
/// `Session` can also be used to erase the type of arbitrary `SessionProtocol` values.
public struct Session<Request, Value, Error: Swift.Error>
{
    // MARK: - Initialization
    
    /**
    Initializes a `Session` with a closure.
    
    - parameter function: The function to use to convert request values into signal producers.
    */
    public init(_ function: @escaping (Request) -> SignalProducer<Value, Error>)
    {
        producerFunction = function
    }
    
    /**
    Initializes a session by wrapping another `SessionProtocol` with the same `Request`, `Value`, and `Error`, erasing its
    type.
    
    - parameter URLSession: The URL session to use.
    - parameter transform:  The transformation function to use.
    */
    public init<Wrapped: SessionProtocol>
        (_ session: Wrapped) where Wrapped.Request == Request, Wrapped.Value == Value, Wrapped.Error == Error
    {
        self.init(session.producer)
    }
    
    // MARK: - Properties
    
    /// Wraps the inner session without directly referencing its type.
    let producerFunction: (Request) -> SignalProducer<Value, Error>
}

extension Session: SessionProtocol
{
    // MARK: - SessionProtocol
    
    /**
    Converts a request into a `SignalProducer` value.
    
    - parameter request: The request.
    
    - returns: A signal producer for the request.
    */
    public func producer(for request: Request) -> SignalProducer<Value, Error>
    {
        return producerFunction(request)
    }
}
