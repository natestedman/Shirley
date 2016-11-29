// Shirley
// Written in 2016 by Nate Stedman <nate@natestedman.com>
//
// To the extent possible under law, the author(s) have dedicated all copyright and
// related and neighboring rights to this software to the public domain worldwide.
// This software is distributed without any warranty.
//
// You should have received a copy of the CC0 Public Domain Dedication along with
// this software. If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.

extension SessionProtocol where Value: MessageProtocol
{
    // MARK: - Tuple Session
    
    /// Returns a transformed session, converting a message into its tuple type.
    ///
    /// This function is only available when `Value` conforms to `MessageProtocol`.
    public var tuple: Session<Request, (response: Value.Response, body: Value.Body), Error>
    {
        return mapValues({ message in message.tuple })
    }
    
    // MARK: - Body Session
    
    /// Returns a transformed session, dropping the message's response and including only its body.
    ///
    /// This function is only available when `Value` conforms to `MessageProtocol`.
    public var body: Session<Request, Value.Body, Error>
    {
        return mapValues({ message in message.body })
    }
}

