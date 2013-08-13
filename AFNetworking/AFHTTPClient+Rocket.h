// AFHTTPClient+Rocket.h
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

#import "AFHTTPClient.h"

#import "AFEventSource.h"
#import "AFJSONPatchSerializer.h"

/**
 This category adds methods to AFNetworking's `AFHTTPClient` class related to real-time networking with Rocket.
 
 Rocket is a technique for building real-time functionality on top of REST web services that leverages web standards like Server-Sent Events and JSON Patch. According to REST conventions, when a client makes an HTTP `GET` request to a resource endpoint, a list of records is returned. With Rocket, a client can additionally `SUBSCRIBE` to changes for that resource by requesting an event stream at that endpoint. Anytime a record is created, updated, or destroyed, an event is sent in real-time over the event stream, encoding the changes as a JSON Patch document.
 
 @see http://rocket.github.io
 */
@interface AFHTTPClient (Rocket)

/**
 Creates and opens an event source with a `SUBSCRIBE` URL request to the specified URL string, executing a block for each received event.
 
 @param URLString The URL string used to create the request URL.
 @param block A block object to be executed each time an event is received from the server. This block has no return value and takes two arguments: the JSON Patch operations associated with the received server-sent event, and the error that occured while receiving the last event, if any.
 @param error The error that occurred while attempting to open the event stream.
 
 @return An event source, opened to the request created with the specified URL string.
 */
- (AFEventSource *)SUBSCRIBE:(NSString *)URLString
                  usingBlock:(void (^)(NSArray *operations, NSError *error))block
                       error:(NSError * __autoreleasing *)error;

/**
 Creates and opens an event source with the specified URL request, executing a block for each received event.

 @param request The request used to connect the event source.
 @param block A block object to be executed each time an event is received from the server. This block has no return value and takes two arguments: the JSON Patch operations associated with the received server-sent event, and the error that occured while receiving the last event, if any.
 @param error The error that occurred while attempting to open the event stream.
 
 @return An event source, opened to the request created with the specified URL request.
 */
- (AFEventSource *)openEventSourceWithRequest:(NSURLRequest *)request
                                   serializer:(AFJSONPatchSerializer *)serializer
                                   usingBlock:(void (^)(NSArray *operations, NSError *error))block
                                        error:(NSError * __autoreleasing *)error;

@end
