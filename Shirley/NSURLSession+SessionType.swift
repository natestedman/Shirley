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

/// An implementation of `SessionType` for `NSURLSession`.
extension NSURLSession: SessionType
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
    public func producerForRequest(request: Request) -> SignalProducer<Message<NSURLResponse, NSData>, NSError>
    {
        return rac_dataWithRequest(request).map({ data, response in
            Message(response: response, body: data)
        })
    }
}
