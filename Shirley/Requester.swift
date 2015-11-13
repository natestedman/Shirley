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

/// A type for values that can create signal producers for requests.
///
/// An implementation is provided for `NSURLSession`, and `SessionType` provides extensions specific to `NSURLSession`,
/// but custom implementations are supported.
public protocol RequesterType
{
    // MARK: - Types
    
    /// The type of values produced by successful requests.
    typealias Value
    
    /// The type of request consumed by the requester.
    typealias Request
    
    /// The type of error produced by the requester when a request fails.
    typealias Error: ErrorType
    
    // MARK: - Signal Producers
    
    /**
     Returns a signal producer for the specified request.
     
     - parameter request: The request.
     */
    func producerForRequest(request: Request) -> SignalProducer<Value, Error>
}

// MARK: - NSURLSession

/// An implementation of `RequesterType` for `NSURLSession`.
extension NSURLSession: RequesterType
{
    // MARK: - Types
    
    /// The type of values produced by successful URL requests.
    public typealias Value = Message<NSURLResponse, NSData>
    
    /// The type of request consumed by the requester.
    public typealias Request = NSURLRequest
    
    /// The type of error produced by the requester when a request fails.
    public typealias Error = NSError
    
    // MARK: - Signal Producers
    
    /**
     Returns a signal producer for the specified URL request.
     
     - parameter request: The URL request.
     */
    public func producerForRequest(request: Request) -> SignalProducer<Value, NSError>
    {
        return rac_dataWithRequest(request).map({ data, response in
            Message(response: response, body: data)
        })
    }
}
