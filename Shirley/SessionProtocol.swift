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
import ReactiveSwift
import Result

// MARK: - Protocol

/// A protocol type for sessions, implemented by `Session`.
public protocol SessionProtocol
{
    // MARK: - Types
    
    /// The type of request used by the session to create signal producers.
    associatedtype Request
    
    /// The type of values yielded by signal producers created by the session.
    associatedtype Value
    
    /// The type of errors yielded by signal producers created by the session.
    associatedtype Error: Swift.Error
    
    // MARK: - Creating Signal Producers
    
    /**
     Converts a request into a `SignalProducer` value.
     
     - parameter request: The request.
     
     - returns: A signal producer for the request.
     */
    func producer(for request: Request) -> SignalProducer<Value, Error>
}
