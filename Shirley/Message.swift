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

// MARK: - Protocol

/// A protocol type for response messages, implemented by `Message`.
public protocol MessageType
{
    // MARK: - Response
    
    /// The response value type.
    typealias Response
    
    /// The response value.
    var response: Response { get }
    
    // MARK: - Data
    
    /// The body data type.
    typealias Body
    
    /// The response body.
    var body: Body { get }
}

extension MessageType where Response == NSURLResponse
{
    // MARK: - Converting to an HTTP Response
    
    /// Attempts to convert a non-HTTP `MessageType` to an HTTP `Message`. If the conversion is not possible, returns
    /// `nil`.
    ///
    /// This property is only available when `Response` is `NSURLResponse`.
    public var HTTPMessage: Message<NSHTTPURLResponse, Body>?
    {
        return (response as? NSHTTPURLResponse).map({ HTTP in
            Message(response: HTTP, body: body)
        })
    }
}

// MARK: - Implementation

/// A response message, with a response object and the response data.
public struct Message<Response, Body>: MessageType
{
    // MARK: - Response
    
    /// The URL response.
    public let response: Response
    
    // MARK: - Body
    
    /// The response body.
    public let body: Body
}
