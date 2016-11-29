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

/// An implementation of `SessionProtocol` for `URLSession`.
extension URLSession: SessionProtocol
{
    // MARK: - Signal Producers
    
    /**
     Returns a signal producer for the specified URL request.
     
     - parameter request: The URL request.
     */
    public func producer(for request: URLRequest) -> SignalProducer<Message<URLResponse, Data>, NSError>
    {
        return self.taskProducer { observer in
            self.dataTask(with: request, completionHandler: self.messageCompletionHandler(observer))
        }
    }
}

extension URLSession
{
    // MARK: - Downloads
    
    /// A `Session` that uses the underlying `URLSession` to download files.
    ///
    /// The `UploadRequest` data type is used for requests, as `NSURLRequest` does not provide enough information.
    ///
    /// The signal producers created by this session will fail with the error type `NSError`. Typically, this will be
    /// provided by `URLSession`, but if an error is not provided, an `NSError` representation of
    /// `SessionError.UnknownError` will be provided.
    public var download: Session<URLRequest, Message<URLResponse, URL>, NSError>
    {
        return Session { request in
            self.taskProducer { observer in
                self.downloadTask(
                    with: request,
                    completionHandler: self.messageCompletionHandler(observer)
                )
            }
        }
    }
}

/// The request type for `URLSession`'s `uploadSession()`.
public struct UploadRequest
{
    // MARK: - Initialization

    /**
     Initializes an upload request.

     - parameter URLRequest: The URL request to upload with.
     - parameter source:     The source of data to upload.
     */
    public init(request: URLRequest, source: Source)
    {
        self.request = request
        self.source = source
    }

    // MARK: - Request

    /// The URL request to upload with.
    public let request: URLRequest

    // MARK: - Source

    /// The data source for an `UploadRequest`.
    public enum Source
    {
        /// In-memory data will be used.
        case data(Foundation.Data)

        /// A file URL will be used.
        case file(URL)
    }

    /// The source of data to upload.
    public let source: Source
}

extension URLSession
{
    // MARK: - Uploads
    
    /**
    Converts an `UploadRequest` into an `URLSessionUploadTask`.
    
    - parameter request:           The upload request.
    - parameter completionHandler: The completion handler for the task.
    */
    fileprivate func uploadTask(request: UploadRequest,
                                completionHandler: @escaping (Data?, URLResponse?, Swift.Error?) -> Void)
        -> URLSessionUploadTask
    {
        switch request.source
        {
        case .data(let data):
            return uploadTask(with: request.request, from: data, completionHandler: completionHandler)
        case .file(let URL):
            return uploadTask(with: request.request, fromFile: URL, completionHandler: completionHandler)
        }
    }
    
    /// A session that uses the underlying `URLSession` to upload files.
    ///
    /// The signal producers created by this session will fail with the error type `NSError`. Typically, this will be
    /// provided by `URLSession`, but if an error is not provided, an `NSError` representation of
    /// `SessionError.UnknownError` will be provided.
    public var upload: Session<UploadRequest, Message<URLResponse, Data>, NSError>
    {
        return Session { request in
            self.taskProducer { observer in
                self.uploadTask(request: request, completionHandler: self.messageCompletionHandler(observer))
            }
        }
    }
}

extension URLSession
{
    // MARK: - Utilities
    
    /**
    A ReactiveCocoa `Observer`-based completion handler for `URLSession` callbacks.
    
    - parameter observer: The observer to use.
    */
    fileprivate func messageCompletionHandler<Body>(_ observer: Observer<Message<URLResponse, Body>, NSError>)
        -> (Body?, URLResponse?, Swift.Error?) -> Void
    {
        return { optionalBody, optionalResponse, optionalError in
            if let t = optionalBody, let response = optionalResponse
            {
                observer.send(value: Message(response: response, body: t))
                observer.sendCompleted()
            }
            else
            {
                observer.send(error: (optionalError as? NSError) ?? SessionError.unknownError.NSError)
            }
        }
    }

    /// Creates a session-task-based producer.
    ///
    /// - Parameter makeTask: A function to create a session task. Events should be sent to the given observer.
    fileprivate func taskProducer<Value, Error: Swift.Error>
        (makeTask: @escaping (Observer<Value, Error>) -> URLSessionTask)
        -> SignalProducer<Value, Error>
    {
        return SignalProducer { observer, disposable in
            let task = makeTask(observer)
            disposable += ActionDisposable(action: task.cancel)
            task.resume()
        }
    }
}
