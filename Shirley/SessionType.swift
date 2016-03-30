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
import Result

// MARK: - Protocol

/// A protocol type for sessions, implemented by `Session`.
public protocol SessionType
{
    // MARK: - Types
    
    /// The type of request used by the session to create signal producers.
    associatedtype Request
    
    /// The type of values yielded by signal producers created by the session.
    associatedtype Value
    
    /// The type of errors yielded by signal producers created by the session.
    associatedtype Error: ErrorType
    
    // MARK: - Creating Signal Producers
    
    /**
     Converts a request into a `SignalProducer` value.
     
     - parameter request: The request.
     
     - returns: A signal producer for the request.
     */
    func producerForRequest(request: Request) -> SignalProducer<Value, Error>
}

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

extension SessionType where Value: MessageType
{
    // MARK: - Tuple Session
    
    /// Returns a transformed session, converting a message into its tuple type.
    ///
    /// This function is only available when `Value` conforms to `MessageType`.
    public func tupleSession() -> Session<Request, (response: Value.Response, body: Value.Body), Error>
    {
        return mapValues({ message in message.tuple })
    }
    
    // MARK: - Body Session
    
    /// Returns a transformed session, dropping the message's response and including only its body.
    ///
    /// This function is only available when `Value` conforms to `MessageType`.
    public func bodySession() -> Session<Request, Value.Body, Error>
    {
        return mapValues({ message in message.body })
    }
}

extension SessionType where Value: MessageType, Value.Response == NSURLResponse, Error == NSError
{
    // MARK: - HTTP Response Session
    
    /// Returns a transformed session, converting `NSURLResponse` to `NSHTTPURLResponse`.
    ///
    /// If a conversion cannot be made, the signal producer will send a `.Failed` event, with `SessionError`'s
    /// `.NotHTTPResponse` converted to an `NSError` object.
    ///
    /// This function is only available when `Value` is `MessageType`, with a `Response` type of `NSURLResponse`, and
    /// `Requester.Error` is `NSError`.
    public func HTTPSession() -> Session<Request, Message<NSHTTPURLResponse, Value.Body>, Error>
    {
        return flatMapValues(.Concat, transform: { message in
            (message.response as? NSHTTPURLResponse).map({ HTTP in
                SignalProducer(value: Message(response: HTTP, body: message.body))
            }) ?? SignalProducer(error: SessionError.NotHTTPResponse.NSError)
        })
    }
}

/// The domain for errors generated by `SessionType.raiseHTTPErrors`.
public let SessionTypeHTTPErrorDomain = "Shirley.SessionTypeHTTPErrorDomain"

extension SessionType where Value: MessageType, Value.Response == NSHTTPURLResponse, Error == NSError
{
    // MARK: - HTTP Errors

    /**
     Converts message values with HTTP

     - parameter userInfo: An optional function to provide custom user info values for the error. By default, a
                           localized description is provided, but if a different localized description is included in
                           the dictionary returned from a function passed to this parameter, it will be overridden.
     */
    public func raiseHTTPErrors(userInfo userInfo: ((Value.Response, Value.Body) -> [String:AnyObject])? = nil)
        -> Session<Request, Value, Error>
    {
        return flatMapValues(.Concat, transform: { message in
            let statusCode = message.response.statusCode

            if statusCode >= 400
            {
                var baseUserInfo: [String:AnyObject] = [
                    NSLocalizedDescriptionKey: NSHTTPURLResponse.localizedStringForStatusCode(statusCode)
                ]

                if let extraUserInfo = userInfo?(message.response, message.body)
                {
                    for (key, value) in extraUserInfo
                    {
                        baseUserInfo[key] = value
                    }
                }

                return SignalProducer(error: NSError(
                    domain: SessionTypeHTTPErrorDomain,
                    code: statusCode,
                    userInfo: baseUserInfo
                ))
            }
            else
            {
                return SignalProducer(value: message)
            }
        })
    }
}

extension SessionType where Value == NSData, Error == NSError
{
    // MARK: - JSON Session
    
    /**
    Returns a transformed session, converting `NSData` to JSON `AnyObject`.
    
    This function is only available if `Value` is `NSData` and `Requester.Error` is `NSError`.
    
    - parameter options: The JSON reading options. If omitted, an empty set of options will be used.
    */
    public func JSONSession(options: NSJSONReadingOptions = NSJSONReadingOptions())
        -> Session<Request, AnyObject, Error>
    {
        return flatMapValues(.Concat, transform: { data in
            do
            {
                return SignalProducer(value: try NSJSONSerialization.JSONObjectWithData(data, options: options))
            }
            catch let error as NSError
            {
                return SignalProducer(error: error)
            }
        })
    }
}

extension SessionType where Value: MessageType, Value.Body == NSData, Error == NSError
{
    // MARK: - JSON Message Session
    
    /**
    Returns a transformed session, converting a message body `NSData` to JSON `AnyObject`.
    
    This function is only available if `Value` is a `MessageType` with `Body` type `NSData`, and `Requester.Error` is
    `NSError`.
    
    - parameter options: The JSON reading options. If omitted, an empty set of options will be used.
    */
    public func JSONSession(options: NSJSONReadingOptions = NSJSONReadingOptions())
        -> Session<Request, Message<Value.Response, AnyObject>, Error>
    {
        return flatMapValues(.Concat, transform: { message in
            do
            {
                return SignalProducer(value: Message(
                    response: message.response,
                    body: try NSJSONSerialization.JSONObjectWithData(message.body, options: options)
                ))
            }
            catch let error as NSError
            {
                return SignalProducer(error: error)
            }
        })
    }
}
