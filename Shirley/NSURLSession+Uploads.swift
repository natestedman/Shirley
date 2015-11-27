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

/// The data source for an `UploadRequest`.
public enum UploadRequestSource
{
    /// In-memory data will be used.
    case Data(NSData)
    
    /// A file URL will be used.
    case File(NSURL)
}

/// The request type for `NSURLSession`'s `uploadSession()`.
public struct UploadRequest
{
    // MARK: - Properties
    
    /// The URL request to upload with.
    let URLRequest: NSURLRequest
    
    /// The source of data to upload.
    let source: UploadRequestSource
    
    // MARK: - Initialization
    
    /**
    Initializes an upload request.
    
    - parameter URLRequest: The URL request to upload with.
    - parameter source:     The source of data to upload.
    */
    public init(URLRequest: NSURLRequest, source: UploadRequestSource)
    {
        self.URLRequest = URLRequest
        self.source = source
    }
}

extension NSURLSession
{
    // MARK: - Uploads
    
    /**
    Converts an `UploadRequest` into an `NSURLSessionUploadTask`.
    
    - parameter request:           The upload request.
    - parameter completionHandler: The completion handler for the task.
    */
    private func uploadTaskWithUploadRequest(
        request: UploadRequest,
        completionHandler: (NSData?, NSURLResponse?, NSError?) -> Void)
        -> NSURLSessionUploadTask
    {
        switch request.source
        {
        case .Data(let data):
            return uploadTaskWithRequest(request.URLRequest, fromData: data, completionHandler: completionHandler)
        case .File(let URL):
            return uploadTaskWithRequest(request.URLRequest, fromFile: URL, completionHandler: completionHandler)
        }
    }
    
    /// A session that uses the underlying `NSURLSession` to upload files.
    ///
    /// The signal producers created by this session will fail with the error type `NSError`. Typically, this will be
    /// provided by `NSURLSession`, but if an error is not provided, an `NSError` representation of
    /// `SessionError.UnknownError` will be provided.
    public func uploadSession() -> Session<UploadRequest, Message<NSURLResponse, NSData>, NSError>
    {
        return Session({ request in
            SignalProducer({ observer, disposable in
                let task = self.uploadTaskWithUploadRequest(
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
