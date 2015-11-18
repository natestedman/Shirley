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

/// Enumerates the errors generated by `SessionType`.
///
/// These will be converted to `NSError` with `domain` as the error domain and `rawValue` as the error code.
public enum SessionError: Int, ErrorType
{
    // MARK: - Cases
    
    /// The URL response object could not be converted to `NSHTTPURLResponse`.
    case NotHTTPResponse
    
    // MARK: - Domain
    
    /// The domain for `NSError` objects created from `SessionError` values.
    public static let domain = "com.natestedman.Shirley.SessionError"
    
    // MARK: - Errors
    
    /// Returns an `NSError` object for the error value.
    var NSError: Foundation.NSError
    {
        return Foundation.NSError(domain: SessionError.domain, code: rawValue, userInfo: nil)
    }
}
