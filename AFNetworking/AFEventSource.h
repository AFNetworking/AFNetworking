// AFEventSource.h
// 
// Copyright (c) 2013 AFNetworking (http://afnetworking.com)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import <Foundation/Foundation.h>

#import "AFURLResponseSerialization.h"

@class AFServerSentEvent;
@protocol AFEventSourceDelegate;

/**
 `AFEventSource` is an Objective-C implementation of the EventSource DOM interface supported by modern browsers.
 
 An event source opens an HTTP connection, and receives events as they are sent from the server. Each event is encoded as an `AFServerSentEvent` object, and dispatched to all listeners for that particular event type.

 @see http://www.w3.org/TR/eventsource/
 */
@interface AFEventSource : NSObject <NSCoding, NSCopying>

///-------------------------------------
/// @name Managing Event Source Delegate
///-------------------------------------

/**
 The event source delegate.
 */
@property (nonatomic, weak) id <AFEventSourceDelegate> delegate;

///---------------------------------------
/// @name Getting Event Source Information
///---------------------------------------

/**
 The request used to open connections to the server.
 */
@property (readonly, nonatomic, strong) NSURLRequest *request;

/**
 The last response received by the event source from the server.
 */
@property (readonly, nonatomic, strong) NSHTTPURLResponse *lastResponse;

/**
 The last event received by the event source from the server.
 */
@property (readonly, nonatomic, strong) AFServerSentEvent *lastEvent;

///-------------------------------
/// @name Getting Connection State
///-------------------------------

/**
 Whether the event source is currently connecting to the server. 
 
 An event source can only return `YES` to one of `isConnecting`, `isOpen`, or `isClosed` at a given point in time.
 */
@property (readonly, nonatomic, assign, getter = isConnecting) BOOL connecting;

/**
 Whether the event source currently has an open connection to the server.

 An event source can only return `YES` to one of `isConnecting`, `isOpen`, or `isClosed` at a given point in time.
 */
@property (readonly, nonatomic, assign, getter = isOpen) BOOL open;

/**
 Whether the event source currently has an closed connection to the server.

 An event source can only return `YES` to one of `isConnecting`, `isOpen`, or `isClosed` at a given point in time.
 */
@property (readonly, nonatomic, assign, getter = isClosed) BOOL closed;

///-------------------------------
/// @name Configuring Event Source
///-------------------------------

/**
 How often to retry connections, in seconds.
 */
@property (nonatomic, assign) NSTimeInterval retryInterval;

///-------------------------------
/// @name Creating an Event Source
///-------------------------------

/**
 Initializes an event source with a request created from the specified URL. The request specifies an `Accept` HTTP header field value of `text/event-stream`.
 
 @param url The URL used to create the event source request.
 
 @return An initialized event source object.
 */
- (instancetype)initWithURL:(NSURL *)url;

/**
 Initializes an event source with the specified request.
 
 @param request The event source request.
 
 @return An initialized event source object.
 */
- (instancetype)initWithRequest:(NSURLRequest *)request;

///-------------------------------------
/// @name Opening / Closing Event Source
///-------------------------------------

/**
 Opens the event source connection.
 
 @param error The error that occurred while attempting to encode the request parameters.

 @return `YES` if successful, otherwise `NO`, with the associated `error` available in the out parameter.
 */
- (BOOL)open:(NSError * __autoreleasing *)error;

/**
 Closes the event source connection.

 @param error The error that occurred while attempting to encode the request parameters.

 @return `YES` if successful, otherwise `NO`, with the associated `error` available in the out parameter.
 */
- (BOOL)close:(NSError * __autoreleasing *)error;

///-------------------------------
/// @name Managing Event Listeners
///-------------------------------

/**
 Adds a listener to execute a block when an event of the specified type is sent from the server.
 
 @param event The event to listen for.
 @param block The block to execute when the specified event is received from the server.
 
 @return The identifier associated with the listener for the specified event. Pass this to `removeEventListenerWithIdentifier:` to remove the listener.
 */
- (NSUInteger)addListenerForEvent:(NSString *)event
                       usingBlock:(void (^)(AFServerSentEvent *event))block;

/**
 Removes the event listener with the specified identifier
 
 @param identifier The identifier associated with the event listener.
 
 @discussion The event listener identifier is returned when added with `addListenerForEvent:usingBlock:`.
 */
- (void)removeEventListenerWithIdentifier:(NSUInteger)identifier;

/**
 Removes all listeners for events of the specified type.
 */
- (void)removeAllListenersForEvent:(NSString *)event;

@end

///----------------
/// @name Constants
///----------------

/**
 Indicates an event source connection error.
 */
extern NSString * const AFEventSourceErrorDomain;

#pragma mark -

/**
 The `AFEventSourceDelegate` protocol defines the methods that a delegate of an `AFEventSource` object should implement to handle events during the event source lifecycle.
 */
@protocol AFEventSourceDelegate <NSObject>

@optional

/**
 Tells the delegate that an event source has opened its connection.
 
 @param source The event source.
 */
- (void)eventSourceDidOpen:(AFEventSource *)source;

/**
 Tells the delegate that an event source has received an event.

 @param source The event source.
 @param event The received event.
 */
- (void)eventSource:(AFEventSource *)source
  didReceiveMessage:(AFServerSentEvent *)event;

/**
 Tells the delegate that an event source has closed its connection.

 @param source The event source.
 */
- (void)eventSourceDidClose:(AFEventSource *)source;

/**
 Tells the delegate that an event source has failed.

 @param source The event source.
 @param error The error associated with the event source.
 */
- (void)eventSource:(AFEventSource *)source
   didFailWithError:(NSError *)error;

@end

#pragma mark -

/**
 `AFServerSentEvent` objects represent events received from the server by an event source. A server-sent event has associated `event` type, an `identifier`, associated `data`, and a `retry` inteval. Any additional fields not defined by the EventSource API spec are stored in a `userInfo` dictionary.
 */
@interface AFServerSentEvent : NSObject <NSCoding, NSCopying>

///---------------------------------
/// @name Managing Event Information
///---------------------------------

/**
 The event type.
 */
@property (nonatomic, copy) NSString *event;

/**
 The event identifier.
 */
@property (nonatomic, copy) NSString *identifier;

/**
 The data associated with the event.
 */
@property (nonatomic, strong) NSData *data;

/**
 The retry interval sent with the event.
 */
@property (nonatomic, assign) NSTimeInterval retry;

/**
 Any additional fields in the event.
 */
@property (nonatomic, strong) NSDictionary *userInfo;

///------------------------
/// @name Creating an Event
///------------------------

/**
 Creates and returns an event with the specified fields.
 */
+ (instancetype)eventWithFields:(NSDictionary *)fields;

@end

#pragma mark -

/**
 `AFServerSentEventSerializer` is a subclass of `AFHTTPSerializer` that validates and decodes server sent event messages.

 By default, `AFServerSentEventSerializer` accepts responses with a MIME type of `text/event-stream`. 
 */
@interface AFServerSentEventResponseSerializer : AFHTTPResponseSerializer

@end
