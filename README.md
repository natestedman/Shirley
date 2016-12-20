# Shirley

[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Build Status](https://travis-ci.org/natestedman/Shirley.svg?branch=master)](https://travis-ci.org/natestedman/Shirley)
[![License](https://img.shields.io/badge/license-Creative%20Commons%20Zero%20v1.0%20Universal-blue.svg)](https://creativecommons.org/publicdomain/zero/1.0/)

A minimal request framework, built on top of [ReactiveSwift](https://github.com/ReactiveCocoa/ReactiveSwift). Shirley has full support for `URLSession`, but is not limited to `URLSession`, or to the Foundation URL system at all.

## Usage

Shirley allows a set of value and error transforms to be applied to request results, while using ReactiveSwift `SignalProducer` values throughout, as a universal language replacing closure callbacks. This allows disparate request-and-callback systems to be unified under a single handling mechanism.

### Sessions
A `SessionProtocol` value converts `Request` values into ReactiveSwift `SignalProducer` values. In addition to `Request`, `Value`, and `Error` associated types, types conforming to `SessionProtocol` provide `producer(for request:)`.

Sessions can be transformed with the `mapRequests(:)`, `mapValues(:)`, `flatMapValues(::)`, and `flatMapErrors(:)` functions, or with the built-in transforms for JSON and HTTP support. These transformations return a value of the `Session` type, which can also be used for type-erasure of `SessionProtocol` values. For sessions with `Hashable` requests, the `deduplicated` property creates a session that ensures only one underlying signal per request is active at any time. Transforming a session is non-destructive, so the underlying session can still be used independently, or transformed into multiple derived sessions.

`URLSession` is extended to conform to `SessionProtocol`, using requests of type `URLRequest` to produce values of type `Message<URLResponse, Data>` and errors of type `NSError`.

For example, by default, an `URLSession` produces pure data - `Data`. Since transformed sessions use their base sessions to do work, a single base URL session can be used to load JSON data, image data, or file data seamlessly.

### Messages
The `Message` type, which implements the `MessageProtocol` protocol, is a container for response and body values. When used as a `SessionProtocol`, `URLSession` produces signal producers that send values of type `Message<URLResponse, Data>`.

`MessageType` provides extensions for converting `Data` bodies to JSON, and for converting `URLResponse` responses to `HTTPURLResponse`.

Messages are essentially “nicer two-tuples”, and `MessageProtocol` provides a `tuple` property is that format is preferred. The message conversions to tuples, JSON, and HTTP responses are also supported by `SessionProtocol`, so that sessions _producing_ the prerequisite types can be transformed to sessions producing the derived types.

## Documentation
If necessary, install `jazzy`:

    gem install jazzy
   
Then run:

    make docs

To generate HTML documentation in the `Documentation` subdirectory.

## Installation

Add:

    github "natestedman/Shirley"

To your `Cartfile`.

![Shirley!](http://i.imgur.com/wCVDLYI.png)
