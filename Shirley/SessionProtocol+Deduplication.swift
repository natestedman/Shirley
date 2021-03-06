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

extension SessionProtocol where Request: Hashable
{
    // MARK: - Deduplication

    /// Creates a session that deduplicates active requests based on a hash value, so that there at most one started
    /// signal producer per request in the underlying session.
    ///
    /// Currently, underlying signal producers are not disposed until termination, even if all outer observers are
    /// disposed. Of course, a new observer could be added while the underlying producer is still active. This behavior
    /// may change in the future.
    public var deduplicated: Session<Request, Value, Error>
    {
        var signals = [Request:Signal<Value, Error>]()

        let lock = NSRecursiveLock()

        return Session { request in
            SignalProducer { observer, disposable in
                lock.lock()

                if let signal = signals[request]
                {
                    disposable += signal.observe(observer)
                }
                else
                {
                    self.producer(for: request).startWithSignal({ signal, _ in
                        signals[request] = signal

                        signal.observe { event in
                            lock.lock()

                            if event.isTerminating
                            {
                                signals.removeValue(forKey: request)
                            }

                            if !disposable.isDisposed
                            {
                                observer.send(event: event)
                            }

                            lock.unlock()
                        }
                    })
                }

                lock.unlock()
            }
        }
    }
}

extension Observer
{
    fileprivate func send(event: Event<Value, Error>)
    {
        switch event
        {
        case .value(let value):
            send(value: value)
        case .failed(let error):
            send(error: error)
        case .completed:
            sendCompleted()
        case .interrupted:
            sendInterrupted()
        }
    }
}
