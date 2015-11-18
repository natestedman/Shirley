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

// MARK: - Protocol

/// A protocol type for sessions, implemented by `Session`.
public protocol SessionType
{
    // MARK: - Types
    
    /// The type of request used by the session to create signal producers.
    typealias Request
    
    /// The type of values yielded by signal producers created by the session.
    typealias Value
    
    /// The type of errors yielded by signal producers created by the session.
    typealias Error: ErrorType
    
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
    public func transform<Other>(transform: Value -> SignalProducer<Other, Error>) -> Session<Request, Other, Error>
    {
        return Session<Request, Other, Error>(
            session: TransformSession<Request, Other, Error>(
                session: self,
                flattenStrategy: .Concat,
                transform: transform
            )
        )
    }
    
    /**
     Transforms a session into a session with a different error type.
     
     - parameter transform: The transformation function to use.
     
     - returns: A `Session`, with `Error` type `Other`.
     */
    public func transformError<Other>(transform: Error -> SignalProducer<Value, Other>)
        -> Session<Request, Value, Other>
    {
        return Session(
            session: TransformSession(
                session: self,
                transform: transform
            )
        )
    }
}

extension SessionType where Value: MessageType
{
    // MARK: - Tuple Session
    
    /// Returns a transformed session, converting a message into its tuple type.
    public func tupleSession() -> Session<Request, (response: Value.Response, body: Value.Body), Error>
    {
        return transform({ message in SignalProducer(value: message.tuple) })
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
        return transform({ message in
            message.HTTPMessage.map({ HTTPMessage in
                SignalProducer(value: HTTPMessage)
            }) ?? SignalProducer(error: SessionError.NotHTTPResponse.NSError)
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
        return transform({ data in
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
        return transform({ message in
            do
            {
                return SignalProducer(value: try message.JSONMessage(options))
            }
            catch let error as NSError
            {
                return SignalProducer(error: error)
            }
        })
    }
}
