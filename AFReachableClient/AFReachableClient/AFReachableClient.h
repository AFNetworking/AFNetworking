// AFReachableClient.h
//
// Copyright (c) 2011 Kevin Harwood
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

#import "AFNetworking.h"
#import "Reachability.h"

/**
 `AFReachableClient` is a subclass of `AFHTTPClient`, and is designed to encapsulate monitoring the network connection status of a specific URL. This ensures that when requests are in process or started, they will immediately fail with error.  Requests that are executing will be cancelled.
 
 `AFReachableClient` depends on the `Reachability` class provided by Apple.
 
 ## Network Error Handling
 
 One of two errors will be returned by the operation if network connectivity is lost:
 
 - *Executing Requests*: Requests that are in process will return error code `NSURLErrorNetworkConnectionLost` to the failure block.
 - *Pending Requests*: Requests that have yet to start will return error code `NSURLErrorCannotConnectToHost` to the failure block.
 
 ## Subclassing Notes
 `AFReachableClient` is designed to be subclassed exactly like `AFHTTPClient` with one exception - if the subclass invokes `initWithBaseURL:`, `AFReachableClient` will use the base URL as the reachable host URL.  If a different reachable host URL is needed, use `initWithBaseURL:reachableHostURL:`.
 
 */

@interface AFReachableClient : AFHTTPClient

///---------------------------------------
/// @name Accessing HTTP Client Properties
///---------------------------------------

/**
 The url used as the reachable host URL for the `reachableHost`. 
 */
@property (nonatomic,readonly) NSURL * reachableHostURL;

/**
 The Reachability object that contains the network connectivity status for the `reachableHostURL`.
 */
@property (nonatomic,readonly) Reachability * reachableHost;

///---------------------------------------------
/// @name Creating and Initializing Reachable HTTP Clients
///---------------------------------------------
/**
 Initializes an `AFReachableClient` object with the specified base URL and a Reachability object with the specified reachable URL.
 
 @param url The base URL for the HTTP client. This argument must not be nil.
 @param reachableHostURL The reachable host URL for the reachability object. This argument must not be nil.
 
 @discussion This is the designated initializer.
 
 @return The newly-initialized reachable HTTP client
 */
- (id)initWithBaseURL:(NSURL *)url 
     reachableHostURL:(NSURL*)reachableHostURL;

@end
