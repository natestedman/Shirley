# Shirley

[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Build Status](https://travis-ci.org/natestedman/Shirley.svg?branch=master)](https://travis-ci.org/natestedman/Shirley)
[![License](https://img.shields.io/badge/license-Creative%20Commons%20Zero%20v1.0%20Universal-blue.svg)](https://creativecommons.org/publicdomain/zero/1.0/)

A minimal request framework, built on top of [ReactiveCocoa](https://github.com/ReactiveCocoa/ReactiveCocoa). Shirley has full support for `NSURLSession`, but is not limited to `NSURLSession`, or to the Foundation URL system at all.

## Usage

Shirley allows a set of value and error transforms to be applied to request results, while using ReactiveCocoa `SignalProducer` values throughout, as a universal language replacing closure callbacks. This allows disparate request-and-callback systems to be unified under a single handling mechanism.

### Sessions
A `SessionType` value converts `Request` values into ReactiveCocoa `SignalProducer` values. In addition to `Request`, `Value`, and `Error` typealiases, types conforming to `SessionType` provide `producerForRequest(:)`.

Sessions can be transformed with the `transform(:)` and `transformError(:)` functions, or with the built-in transforms for JSON and HTTP support. These transformations return a value of the `Session` type, which can also be used to unify disparate `SessionType` values under a single type, as long as they share the same `Request`, `Value`, and `Error` types. Transforming a session is non-destructive, so the underlying session can still be used independently, or transformed into multiple derived sessions.

`NSURLSession` is extended to conform to `SessionType`, using requests of type `NSURLRequest` to produce values of type `Message<NSURLResponse, NSData>` and errors of type `NSError`.

For example, by default, an `NSURLSession` produces pure data - `NSData`. Since transformed sessions use their base sessions to do work, a single base URL session can be used to load JSON data, image data, or file data seamlessly.

### Messages
The `Message` type, which implements the `MessageType` protocol, is a container for response and body values. When used as a `SessionType`, `NSURLSession` produces signal producers that send values of type `Message<NSURLResponse, NSData>`.

`MessageType` provides extensions for converting `NSData` bodies to JSON, and for converting `NSURLResponse` responses to `NSHTTPURLResponse`.

Messages are essentially "nicer two-tuples", and `MessageType` provides a `tuple` property is that format is preferred. The message conversions to tuples, JSON, and HTTP responses are also supported by `SessionType`, so that sessions _producing_ the prerequisite types can be transformed to sessions producing the derived types.

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
