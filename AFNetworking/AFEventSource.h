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

#import "AFSerialization.h"

// TODO extract into separate extension

@class AFServerSentEvent;
@protocol AFEventSourceDelegate;

/** 
 @see http://www.w3.org/TR/eventsource/
 */
@interface AFEventSource : NSObject

@property (nonatomic, weak) id <AFEventSourceDelegate> delegate;

@property (readonly, nonatomic, strong) NSURLRequest *request;
@property (readonly, nonatomic, strong) NSHTTPURLResponse *lastResponse;
@property (readonly, nonatomic, strong) AFServerSentEvent *lastEvent;

@property (nonatomic, assign) NSTimeInterval retryInterval;

@property (readonly, nonatomic, assign, getter = isConnecting) BOOL connecting;
@property (readonly, nonatomic, assign, getter = isOpen) BOOL open;
@property (readonly, nonatomic, assign, getter = isClosed) BOOL closed;

/**

 */
- (instancetype)initWithURL:(NSURL *)url;

/**

 */
- (instancetype)initWithRequest:(NSURLRequest *)request;

/**

 */
- (BOOL)open:(NSError * __autoreleasing *)error;

/**

 */
- (BOOL)close:(NSError * __autoreleasing *)error;

/**

 */
- (void)addEventListener:(NSString *)event
              usingBlock:(void (^)(AFServerSentEvent *event))block;

/**

 */
- (void)removeListenersForEvent:(NSString *)event;

@end

///

extern NSString * const AFEventSourceErrorDomain;

#pragma mark -

/**
 
 */
@protocol AFEventSourceDelegate <NSObject>

@optional

/**
 
 */
- (void)eventSourceDidOpen:(AFEventSource *)source;

/**
 
 */
- (void)eventSource:(AFEventSource *)source
  didReceiveMessage:(AFServerSentEvent *)event;

/**
 
 */
- (void)eventSourceDidClose:(AFEventSource *)source;

/**
 
 */
- (void)eventSource:(AFEventSource *)source
   didFailWithError:(NSError *)error;

@end

#pragma mark -

/**

 */
@interface AFServerSentEvent : NSObject

@property (nonatomic, copy) NSString *event;
@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, strong) NSData *data;
@property (nonatomic, assign) NSTimeInterval retry;
@property (nonatomic, strong) NSDictionary *userInfo;

/**

 */
+ (instancetype)eventWithFields:(NSDictionary *)fields;

@end

#pragma mark -

@interface AFServerSentEventSerializer : AFHTTPSerializer

@end
