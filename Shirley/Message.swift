// Shirley
// Written in 2015 by Nate Stedman <nate@natestedman.com>
//
// To the extent possible under law, the author(s) have dedicated all copyright and
// related and neighboring rights to this software to the public domain worldwide.
// This software is distributed without any warranty.
//
// You should have received a copy of the CC0 Public Domain Dedication along with
// this software. If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.

/// A response message, with a response object and the response data.
public struct Message<Response, Body>: MessageType
{
    // MARK: - Initialization
    
    /**
    Initializes a message.
    
    - parameter response: The response value.
    - parameter body:     The body value.
    */
    public init(response: Response, body: Body)
    {
        self.response = response
        self.body = body
    }
    
    // MARK: - Response
    
    /// The URL response.
    public let response: Response
    
    // MARK: - Body
    
    /// The response body.
    public let body: Body
}
