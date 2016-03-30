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
    associatedtype Response
    
    /// The body value type.
    associatedtype Body
    
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
