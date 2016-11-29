// Shirley
// Written in 2016 by Nate Stedman <nate@natestedman.com>
//
// To the extent possible under law, the author(s) have dedicated all copyright and
// related and neighboring rights to this software to the public domain worldwide.
// This software is distributed without any warranty.
//
// You should have received a copy of the CC0 Public Domain Dedication along with
// this software. If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.

import ReactiveSwift
import Result

extension SessionProtocol
{
    // MARK: - Transforms

    /**
     Transforms a session by transforming each producer the session creates for a request.

     This function is equivalent to creating a `Session` like so:

         Session { request in
             transform(self.producer(for: request))
         }

     - parameter transform: The transform function to apply to each producer.
     */
    public func mapProducers<OtherValue, OtherError>
        (_ transform: @escaping (SignalProducer<Value, Error>) -> SignalProducer<OtherValue, OtherError>)
        -> Session<Request, OtherValue, OtherError>
    {
        return Session { request in
            transform(self.producer(for: request))
        }
    }
    
    /**
    Transforms a session into a session with a different value type.
    
    - parameter transform: The transformation function to use.
    
    - returns: A `Session`, with `Value` type `Other`.
    */
    public func mapValues<Other>(_ transform: @escaping (Value) -> Other) -> Session<Request, Other, Error>
    {
        return mapProducers({ $0.map(transform) })
    }
    
    /**
     Performs a `flatMap` operation on each `SignalProducer` this session creates.

     - parameter strategy: The flatten strategy to use.
     - parameter transform: The transformation function.

     - returns: A `Session`, with `Value` type `Other`.
     */
    public func flatMapValues<Other>(_ strategy: FlattenStrategy,
                                     transform: @escaping (Value) -> SignalProducer<Other, Error>)
        -> Session<Request, Other, Error>
    {
        return mapProducers({ $0.flatMap(strategy, transform: transform) })
    }
    
    /**
     Transforms a session into a session with a different error type.
     
     - parameter transform: The transformation function to use.
     
     - returns: A `Session`, with `Error` type `Other`.
     */
    public func flatMapErrors<Other>(_ transform: @escaping (Error) -> SignalProducer<Value, Other>)
        -> Session<Request, Value, Other>
    {
        return mapProducers({ $0.flatMapError(transform) })
    }
    
    /**
     Transforms a session into a session with a different request type.
     
     - parameter transform: A transformation function, which transforms the transformed request type into the base
                            request type.
     
     - returns: A `Session`, with `Request` type `Other`.
     */
    public func mapRequests<Other>(_ transform: @escaping (Other) -> Request) -> Session<Other, Value, Error>
    {
        return Session { other in
            self.producer(for: transform(other))
        }
    }

    /**
     Transforms a session into a session with a diferent request type, allowing the transformation to fail.

     - parameter transform: A transformation function, which, if possible, transforms a value of the transformed request
                            type into a value of the base request type. If this cannot be done, returns a failure
                            result.

     - returns: A `Session`, with `Request` type `Other`.
     */
    public func flatMapRequests<Other>(transform: @escaping (Other) -> Result<Request, Error>) -> Session<Other, Value, Error>
    {
        return Session { other in
            switch transform(other)
            {
            case .success(let request):
                return self.producer(for: request)
            case .failure(let error):
                return SignalProducer(error: error)
            }
        }
    }
}
