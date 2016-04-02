// Shirley
// Written in 2016 by Nate Stedman <nate@natestedman.com>
//
// To the extent possible under law, the author(s) have dedicated all copyright and
// related and neighboring rights to this software to the public domain worldwide.
// This software is distributed without any warranty.
//
// You should have received a copy of the CC0 Public Domain Dedication along with
// this software. If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.

import Foundation
import ReactiveCocoa

extension SessionType where Value == NSData, Error == NSError
{
    // MARK: - JSON Session
    
    /**
    Returns a transformed session, converting `NSData` to JSON `AnyObject`.
    
    This function is only available if `Value` is `NSData` and `Requester.Error` is `NSError`.
    
    - parameter options: The JSON reading options. If omitted, an empty set of options will be used.
    */
    public func JSONSession(options: NSJSONReadingOptions = NSJSONReadingOptions())
        -> Session<Request, AnyObject, Error>
    {
        return flatMapValues(.Concat, transform: { data in
            do
            {
                return SignalProducer(value: try NSJSONSerialization.JSONObjectWithData(data, options: options))
            }
            catch let error as NSError
            {
                return SignalProducer(error: error)
            }
        })
    }
}

extension SessionType where Value: MessageType, Value.Body == NSData, Error == NSError
{
    // MARK: - JSON Message Session
    
    /**
    Returns a transformed session, converting a message body `NSData` to JSON `AnyObject`.
    
    This function is only available if `Value` is a `MessageType` with `Body` type `NSData`, and `Requester.Error` is
    `NSError`.
    
    - parameter options: The JSON reading options. If omitted, an empty set of options will be used.
    */
    public func JSONSession(options: NSJSONReadingOptions = NSJSONReadingOptions())
        -> Session<Request, Message<Value.Response, AnyObject>, Error>
    {
        return flatMapValues(.Concat, transform: { message in
            do
            {
                return SignalProducer(value: Message(
                    response: message.response,
                    body: try NSJSONSerialization.JSONObjectWithData(message.body, options: options)
                ))
            }
            catch let error as NSError
            {
                return SignalProducer(error: error)
            }
        })
    }
}

