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

/// Applies a transform to a session's values or errors, creating a new session. This type is wrapped in `Session`
/// before being returned publically.
internal struct TransformSession<Request, Value, Error: ErrorType>
{
    // MARK: - Initialization
    
    /**
    Initializes a value transform session.
    
    - parameter session:         The session to wrap.
    - parameter flattenStrategy: The flatten strategy to use when transforming.
    - parameter transform:       The transform function.
    */
    init<Wrapped: SessionType where Request == Wrapped.Request, Error == Wrapped.Error>
        (session: Wrapped, flattenStrategy: FlattenStrategy, transform: Wrapped.Value -> SignalProducer<Value, Error>)
    {
        producerFunction = { request in
            session.producerForRequest(request).flatMap(flattenStrategy, transform: transform)
        }
    }
    
    /**
    Initializes a error transform session.
    
    - parameter session:        The session to wrap.
    - parameter transformError: The transform function.
    */
    init<Wrapped: SessionType where Request == Wrapped.Request, Value == Wrapped.Value>
        (session: Wrapped, transformError: Wrapped.Error -> SignalProducer<Value, Error>)
    {
        producerFunction = { request in
            session.producerForRequest(request).flatMapError(transformError)
        }
    }
    
    // MARK: - Properties
    
    /// Wraps the inner session without directly referencing its type.
    let producerFunction: Request -> SignalProducer<Value, Error>
}

extension TransformSession: SessionType
{
    // MARK: - SessionType
    
    /**
     Converts a request into a `SignalProducer` value.
     
     - parameter request: The request.
     
     - returns: A signal producer for the request.
     */
    func producerForRequest(request: Request) -> SignalProducer<Value, Error>
    {
        return producerFunction(request)
    }
}
