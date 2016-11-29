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
import ReactiveSwift

extension SessionProtocol where Value == Data, Error == NSError
{
    // MARK: - JSON Session
    
    /**
    Returns a transformed session, converting `Data` to JSON `AnyObject`.
    
    This function is only available if `Value` is `Data` and `Requester.Error` is `NSError`.
    
    - parameter options: The JSON reading options. If omitted, an empty set of options will be used.
    */
    public func json(options: JSONSerialization.ReadingOptions = JSONSerialization.ReadingOptions())
        -> Session<Request, Any, Error>
    {
        return flatMapValues(.concat, transform: { data in
            do
            {
                return SignalProducer(value: try JSONSerialization.jsonObject(with: data, options: options))
            }
            catch let error as NSError
            {
                return SignalProducer(error: error)
            }
        })
    }
}

extension SessionProtocol where Value: MessageProtocol, Value.Body == Data, Error == NSError
{
    // MARK: - JSON Message Session
    
    /**
    Returns a transformed session, converting a message body `Data` to JSON `AnyObject`.
    
    This function is only available if `Value` is a `MessageProtocol` with `Body` type `Data`, and `Requester.Error` is
    `NSError`.
    
    - parameter options: The JSON reading options. If omitted, an empty set of options will be used.
    */
    public func json(options: JSONSerialization.ReadingOptions = JSONSerialization.ReadingOptions())
        -> Session<Request, Message<Value.Response, Any>, Error>
    {
        return flatMapValues(.concat, transform: { message in
            do
            {
                return SignalProducer(value: Message(
                    response: message.response,
                    body: try JSONSerialization.jsonObject(with: message.body, options: options)
                ))
            }
            catch let error as NSError
            {
                return SignalProducer(error: error)
            }
        })
    }
}

