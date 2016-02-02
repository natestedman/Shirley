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

/// A protocol type for response messages, implemented by `Message`.
public protocol MessageType
{
    // MARK: - Types
    
    /// The response value type.
    typealias Response
    
    /// The body value type.
    typealias Body
    
    // MARK: - Properties
    
    /// The response value.
    var response: Response { get }
    
    /// The response body.
    var body: Body { get }
}

extension MessageType
{
    // MARK: - Tuple
    
    /// The value of the message, as a tuple.
    public var tuple: (response: Response, body: Body)
    {
        return (response, body)
    }
}

extension MessageType where Body == NSData
{
    // MARK: - Converting to JSON
    
    /**
    Attempts to convert a data message to a JSON message.
    
    This function is only available when `Body` is `NSData`.
    
    - parameter options: The JSON reading options. This parameter may be omitted, in which case an empty set of options
                         will be used.
    
    - throws: An error from `NSJSONSerialization`.
    */
    public func JSONMessage(options: NSJSONReadingOptions = NSJSONReadingOptions())
        throws -> Message<Response, AnyObject>
    {
        return Message(
            response: response,
            body: try NSJSONSerialization.JSONObjectWithData(body, options: options)
        )
    }
}
