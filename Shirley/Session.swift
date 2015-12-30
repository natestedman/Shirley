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

/// A session type that uses a closure to convert requests to signal producers.
///
/// `Session` can also be used to erase the type of arbitrary `SessionType` values.
public struct Session<Request, Value, Error: ErrorType>
{
    // MARK: - Initialization
    
    /**
    Initializes a `Session` with a closure.
    
    - parameter function: The function to use to convert request values into signal producers.
    */
    public init(_ function: Request -> SignalProducer<Value, Error>)
    {
        producerFunction = function
    }
    
    /**
    Initializes a session by wrapping another `SessionType` with the same `Request`, `Value`, and `Error`, erasing its
    type.
    
    - parameter URLSession: The URL session to use.
    - parameter transform:  The transformation function to use.
    */
    public init<Wrapped: SessionType where Wrapped.Request == Request, Wrapped.Value == Value, Wrapped.Error == Error>
        (session: Wrapped)
    {
        self.init(session.producerForRequest)
    }
    
    // MARK: - Properties
    
    /// Wraps the inner session without directly referencing its type.
    let producerFunction: Request -> SignalProducer<Value, Error>
}

extension Session
{
    // MARK: - Transform Initialization
    
    /**
    Initializes a value transform session.
    
    - parameter session:         The session to wrap.
    - parameter flattenStrategy: The flatten strategy to use when transforming.
    - parameter transform:       The transform function.
    */
    init<Wrapped: SessionType where Request == Wrapped.Request, Error == Wrapped.Error>
        (session: Wrapped, flattenStrategy: FlattenStrategy, transform: Wrapped.Value -> SignalProducer<Value, Error>)
    {
        self.init { request in
            session.producerForRequest(request).flatMap(flattenStrategy, transform: transform)
        }
    }
    
    /**
    Initializes an error transform session.
    
    - parameter session:        The session to wrap.
    - parameter transformError: The transform function.
    */
    init<Wrapped: SessionType where Request == Wrapped.Request, Value == Wrapped.Value>
        (session: Wrapped, transformError: Wrapped.Error -> SignalProducer<Value, Error>)
    {
        self.init { request in
            session.producerForRequest(request).flatMapError(transformError)
        }
    }
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
