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
    
    /// The type of requester used by the session.
    typealias Requester: RequesterType
    
    /// The type of values yielded by the session.
    typealias Value
    
    // MARK: - Initialization
    
    /**
     Initializes a session.
     
     - parameter URLSession: The URL session to use.
     - parameter transform:  The transformation function to use.
     */
    init(requester: Requester, transform: Requester.Value -> SignalProducer<Value, Requester.Error>)
    
    // MARK: - Properties
    
    /// The requester used by this session.
    var requester: Requester { get }
    
    /// The transform function used by this session.
    var transform: Requester.Value -> SignalProducer<Value, Requester.Error> { get }
}

extension SessionType
{
    // MARK: - Transforms
    
    /**
    Transforms a session into a session with a different value type.
    
    - parameter transform: The transformation function to use.
    
    - returns: A `Session`, with `Value` type `Other`.
    */
    public func transform<Other>(transform: Value -> SignalProducer<Other, Requester.Error>) -> Session<Requester, Other>
    {
        return Session<Requester, Other>(requester: requester, transform: { message in
            self.transform(message).flatMap(.Merge, transform: transform)
        })
    }
    
    // MARK: - Requests
    
    /**
    Returns a signal produer that will send a request and transform its results.
    
    - parameter request: The request.
    */
    public func producerForRequest(request: Requester.Request) -> SignalProducer<Value, Requester.Error>
    {
        return requester.producerForRequest(request).flatMap(.Merge, transform: transform)
    }
}

extension SessionType where Value == Requester.Value
{
    // MARK: - Same Value Type
    
    /**
    Initializes a session without transforming the value.
    
    This initializer is only available when `Requester.Value` is the same as `Value.
    
    - parameter URLSession: The URL session to use.
    */
    public init(requester: Requester)
    {
        self.init(requester: requester, transform: { message in SignalProducer(value: message) })
    }
}

extension SessionType where Value: MessageType, Value.Response == NSURLResponse, Requester.Error == NSError
{
    // MARK: - NSURLResponse
    
    /// Returns a transformed session, converting `NSURLResponse` to `NSHTTPURLResponse`.
    ///
    /// If a conversion cannot be made, the signal producer will send a `.Failed` event, with `SessionError`'s
    /// `.NotHTTPResponse` converted to an `NSError` object.
    ///
    /// This property is only available when `Value` is `MessageType`, with a `Response` type of `NSURLResponse`, and
    /// `Requester.Error` is `NSError`.
    public var HTTPSession: Session<Requester, Message<NSHTTPURLResponse, Value.Body>>
    {
        return transform({ message in
            message.HTTPMessage.map({ HTTPMessage in
                SignalProducer(value: HTTPMessage)
            }) ?? SignalProducer(error: SessionError.NotHTTPResponse.NSError)
        })
    }
}

extension SessionType where Value == NSData, Requester.Error == NSError
{
    // MARK: - JSON Session
    
    /**
    Returns a transformed session, converting `NSData` to JSON `AnyObject`.
    
    This function is only available if `Value` is `NSData` and `Requester.Error` is `NSError`.
    
    - parameter options: The JSON reading options. If omitted, an empty set of options will be used.
    */
    public func JSONSession(options: NSJSONReadingOptions = NSJSONReadingOptions()) -> Session<Requester, AnyObject>
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

// MARK: - Implementation

/// A wrapper type for a `Requester`. A session produces transformed `SignalProducer`s.
///
/// Much of the functionality provided by this type is implemented in terms of `SessionType`.
public struct Session<Requester: RequesterType, Value>: SessionType
{
    // MARK: - Initialization
    
    /**
    Initializes a session.
    
    - parameter URLSession: The URL session to use.
    - parameter transform:  The transformation function to use.
    */
    public init(requester: Requester, transform: Requester.Value -> SignalProducer<Value, Requester.Error>)
    {
        self.requester = requester
        self.transform = transform
    }
    
    // MARK: - Properties
    
    /// The requester used by this session.
    public let requester: Requester
    
    /// The transform function used by this session.
    public let transform: Requester.Value -> SignalProducer<Value, Requester.Error>
}

// MARK: - Errors

/// Enumerates the errors generated by `Session` and `SessionType`.
///
/// These will be converted to `NSError` with `domain` as the error domain and `rawValue` as the error code.
public enum SessionError: Int, ErrorType
{
    // MARK: - Cases
    
    /// The URL response object could not be converted to `NSHTTPURLResponse`.
    case NotHTTPResponse
    
    // MARK: - Domain
    
    /// The domain for `NSError` objects created from `SessionError` values.
    public static let domain = "com.natestedman.Shirley.SessionError"
    
    // MARK: - Errors
    
    /// Returns an `NSError` object for the error value.
    var NSError: Foundation.NSError
    {
        return Foundation.NSError(domain: SessionError.domain, code: self.rawValue, userInfo: nil)
    }
}
