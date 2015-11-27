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

extension NSURLSession
{
    // MARK: - Utilities
    
    /**
    A ReactiveCocoa `Observer`-based completion handler for `NSURLSession` callbacks.
    
    - parameter observer: The observer to use.
    */
    internal func messageCompletionHandler<T>(observer: Observer<Message<NSURLResponse, T>, NSError>)
        -> (T?, NSURLResponse?, NSError?) -> Void
    {
        return { optT, optResponse, optError in
            if let t = optT, response = optResponse
            {
                observer.sendNext(Message(response: response, body: t))
                observer.sendCompleted()
            }
            else
            {
                observer.sendFailed(optError ?? SessionError.UnknownError.NSError)
            }
        }
    }
    
    // MARK: - Downloads
    
    /// A `Session` that uses the underlying `NSURLSession` to download files.
    ///
    /// The `UploadRequest` data type is used for requests, as `NSURLRequest` does not provide enough information.
    ///
    /// The signal producers created by this session will fail with the error type `NSError`. Typically, this will be
    /// provided by `NSURLSession`, but if an error is not provided, an `NSError` representation of
    /// `SessionError.UnknownError` will be provided.
    public func downloadSession() -> Session<NSURLRequest, Message<NSURLResponse, NSURL>, NSError>
    {
        return Session({ request in
            SignalProducer({ observer, disposable in
                let task = self.downloadTaskWithRequest(
                    request,
                    completionHandler: self.messageCompletionHandler(observer)
                )
                
                task.resume()
                
                disposable += ActionDisposable {
                    task.cancel()
                }
            })
        })
    }
}
