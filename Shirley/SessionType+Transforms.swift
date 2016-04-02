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
import Result

extension SessionType
{
    // MARK: - Transforms
    
    /**
    Transforms a session into a session with a different value type.
    
    - parameter transform: The transformation function to use.
    
    - returns: A `Session`, with `Value` type `Other`.
    */
    public func mapValues<Other>(transform: Value -> Other) -> Session<Request, Other, Error>
    {
        return flatMapValues(.Concat, transform: { value in SignalProducer(value: transform(value)) })
    }
    
    /**
     Performs a `flatMap` operation on each `SignalProducer` this session creates.

     - parameter strategy:  The flatten strategy to use.
     - parameter transform: The transformation function.

     - returns: A `Session`, with `Value` type `Other`.
     */
    public func flatMapValues<Other>(strategy: FlattenStrategy, transform: Value -> SignalProducer<Other, Error>)
        -> Session<Request, Other, Error>
    {
        return Session { request in
            self.producerForRequest(request).flatMap(.Concat, transform: transform)
        }
    }
    
    /**
     Transforms a session into a session with a different error type.
     
     - parameter transform: The transformation function to use.
     
     - returns: A `Session`, with `Error` type `Other`.
     */
    public func flatMapErrors<Other>(transform: Error -> SignalProducer<Value, Other>)
        -> Session<Request, Value, Other>
    {
        return Session { request in
            self.producerForRequest(request).flatMapError(transform)
        }
    }
    
    /**
     Transforms a session into a session with a different request type.
     
     - parameter transform: A transformation function, which transforms the transformed request type into the base
                            request type.
     
     - returns: A `Session`, with `Request` type `Other`.
     */
    public func mapRequests<Other>(transform: Other -> Request) -> Session<Other, Value, Error>
    {
        return Session { other in
            self.producerForRequest(transform(other))
        }
    }

    /**
     Transforms a session into a session with a diferent request type, allowing the transformation to fail.

     - parameter transform: A transformation function, which, if possible, transforms a value of the transformed request
                            type into a value of the base request type. If this cannot be done, returns a failure
                            result.

     - returns: A `Session`, with `Request` type `Other`.
     */
    public func flatMapRequests<Other>(transform: Other -> Result<Request, Error>) -> Session<Other, Value, Error>
    {
        return Session { other in
            switch transform(other)
            {
            case .Success(let request):
                return self.producerForRequest(request)
            case .Failure(let error):
                return SignalProducer(error: error)
            }
        }
    }
}
