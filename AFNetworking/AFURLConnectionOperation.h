// AFURLConnectionOperation.h
//
// Copyright (c) 2011 Gowalla (http://gowalla.com/)
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

/**
 Indicates an error occured in AFNetworking.
 
 @discussion Error codes for AFNetworkingErrorDomain correspond to codes in NSURLErrorDomain.
 */
extern NSString * const AFNetworkingErrorDomain;

/**
 Posted when an operation begins executing.
 */
extern NSString * const AFNetworkingOperationDidStartNotification;

/**
 Posted when an operation finishes.
 */
extern NSString * const AFNetworkingOperationDidFinishNotification;

/**
 `AFURLConnectionOperation` is an `NSOperation` that implements NSURLConnection delegate methods.
 
 ## Subclassing Notes
 
 This is the base class of all network request operations. You may wish to create your own subclass in order to implement additional `NSURLConnection` delegate methods (see "`NSURLConnection` Delegate Methods" below), or to provide additional properties and/or class constructors.
 
 If you are creating a subclass that communicates over the HTTP or HTTPS protocols, you may want to consider subclassing `AFHTTPRequestOperation` instead, as it supports specifying acceptable content types or status codes.
 
 ## NSURLConnection Delegate Methods
 
 `AFURLConnectionOperation` implements the following `NSURLConnection` delegate methods:
 
 - `connection:didReceiveResponse:`
 - `connection:didReceiveData:`
 - `connectionDidFinishLoading:`
 - `connection:didFailWithError:`
 - `connection:didSendBodyData:totalBytesWritten:totalBytesExpectedToWrite:`
 - `connection:willCacheResponse:`
 - `connection:canAuthenticateAgainstProtectionSpace:`
 - `connection:didReceiveAuthenticationChallenge:`
 
 If any of these methods are overriden in a subclass, they _must_ call the `super` implementation first.
  
 ## Class Constructors
 
 Class constructors, or methods that return an unowned (zero retain count) instance, are the preferred way for subclasses to encapsulate any particular logic for handling the setup or parsing of response data. For instance, `AFJSONRequestOperation` provides `JSONRequestOperationWithRequest:success:failure:`, which takes block arguments, whose parameter on for a successful request is the JSON object initialized from the `response data`.
 
 ## Callbacks and Completion Blocks
 
 The built-in `completionBlock` provided by `NSOperation` allows for custom behavior to be executed after the request finishes. It is a common pattern for class constructors in subclasses to take callback block parameters, and execute them conditionally in the body of its `completionBlock`. Make sure to handle cancelled operations appropriately when setting a `completionBlock` (e.g. returning early before parsing response data). See the implementation of any of the `AFHTTPRequestOperation` subclasses for an example of this.
 
 @warning Subclasses are strongly discouraged from overriding `setCompletionBlock:`, as `AFURLConnectionOperation`'s implementation includes a workaround to mitigate retain cycles, and what Apple rather ominously refers to as "The Deallocation Problem" (See http://developer.apple.com/library/ios/technotes/tn2109/_index.html#//apple_ref/doc/uid/DTS40010274-CH1-SUBSECTION11)
 
 @warning Attempting to load a `file://` URL in iOS 4 may result in an `NSInvalidArgumentException`, caused by the connection returning `NSURLResponse` rather than `NSHTTPURLResponse`, which is the behavior as of iOS 5.
 */
@interface AFURLConnectionOperation : NSOperation

///-------------------------------
/// @name Accessing Run Loop Modes
///-------------------------------

/**
 The run loop modes in which the operation will run on the network thread. By default, this is a single-member set containing `NSRunLoopCommonModes`.
 */
@property (nonatomic, retain) NSSet *runLoopModes;

///-----------------------------------------
/// @name Getting URL Connection Information
///-----------------------------------------

/**
 The request used by the operation's connection.
 */
@property (readonly, nonatomic, retain) NSURLRequest *request;

/**
 The last response received by the operation's connection.
 */
@property (readonly, nonatomic, retain) NSURLResponse *response;

/**
 The error, if any, that occured in the lifecycle of the request.
 */
@property (readonly, nonatomic, retain) NSError *error;

///----------------------------
/// @name Getting Response Data
///----------------------------

/**
 The data received during the request. 
 */
@property (readonly, nonatomic, retain) NSData *responseData;

/**
 The string representation of the response data.
 
 @discussion This method uses the string encoding of the response, or if UTF-8 if not specified, to construct a string from the response data.
 */
@property (readonly, nonatomic, copy) NSString *responseString;

///------------------------
/// @name Accessing Streams
///------------------------

/**
 The input stream used to read data to be sent during the request. 
 
 @discussion This property acts as a proxy to the `HTTPBodyStream` property of `request`.
 */
@property (nonatomic, retain) NSInputStream *inputStream;

/**
 The output stream that is used to write data received until the request is finished.
 
 @discussion By default, data is accumulated into a buffer that is stored into `responseData` upon completion of the request. When `outputStream` is set, the data will not be accumulated into an internal buffer, and as a result, the `responseData` property of the completed request will be `nil`. The output stream will be scheduled in the network thread runloop upon being set.
 */
@property (nonatomic, retain) NSOutputStream *outputStream;

///------------------------------------------------------
/// @name Initializing an AFURLConnectionOperation Object
///------------------------------------------------------

/**
 Initializes and returns a newly allocated operation object with a url connection configured with the specified url request.
 
 @param urlRequest The request object to be used by the operation connection.
 
 @discussion This is the designated initializer.
 */
- (id)initWithRequest:(NSURLRequest *)urlRequest;

///----------------------------------
/// @name Pausing / Resuming Requests
///----------------------------------

/**
 Pauses the execution of the request operation.
 
 @discussion A paused operation returns `NO` for `-isReady`, `-isExecuting`, and `-isFinished`. As such, it will remain in an `NSOperationQueue` until it is either cancelled or resumed. Pausing a finished or cancelled operation has no effect.
 */
- (void)pause;

/**
 Whether the request operation is currently paused.
 
 @return `YES` if the operation is currently paused, otherwise `NO`.
 */
- (BOOL)isPaused;

/**
 Resumes the execution of the paused request operation.
 
 @discussion Pause/Resume behavior varies depending on the underlying implementation for the operation class. In its base implementation, resuming a paused requests restarts the original request. However, since HTTP defines a specification for how to request a specific content range, `AFHTTPRequestOperation` will resume downloading the request from where it left off, instead of restarting the original request.
 */
- (void)resume;

///----------------------------------------------
/// @name Configuring Backgrounding Task Behavior
///----------------------------------------------

/**
 Specifies that the operation should continue execution after the app has entered the background, and the expiration handler for that background task.
 
 @param handler A handler to be called shortly before the application’s remaining background time reaches 0. The handler is wrapped in a block that cancels the operation, and cleans up and marks the end of execution, unlike the `handler` parameter in `UIApplication -beginBackgroundTaskWithExpirationHandler:`, which expects this to be done in the handler itself. The handler is called synchronously on the main thread, thus blocking the application’s suspension momentarily while the application is notified. 
 */
#if __IPHONE_OS_VERSION_MIN_REQUIRED
- (void)setShouldExecuteAsBackgroundTaskWithExpirationHandler:(void (^)(void))handler;
#endif

///---------------------------------
/// @name Setting Progress Callbacks
///---------------------------------

/**
 Sets a callback to be called when an undetermined number of bytes have been uploaded to the server.
 
 @param block A block object to be called when an undetermined number of bytes have been uploaded to the server. This block has no return value and takes three arguments: the number of bytes written since the last time the upload progress block was called, the total bytes written, and the total bytes expected to be written during the request, as initially determined by the length of the HTTP body. This block may be called multiple times.
 
 @see setDownloadProgressBlock
 */
- (void)setUploadProgressBlock:(void (^)(NSInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite))block;

/**
 Sets a callback to be called when an undetermined number of bytes have been downloaded from the server.
 
 @param block A block object to be called when an undetermined number of bytes have been downloaded from the server. This block has no return value and takes three arguments: the number of bytes read since the last time the download progress block was called, the total bytes read, and the total bytes expected to be read during the request, as initially determined by the expected content size of the `NSHTTPURLResponse` object. This block may be called multiple times.
 
 @see setUploadProgressBlock
 */
- (void)setDownloadProgressBlock:(void (^)(NSInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead))block;

///-------------------------------------------------
/// @name Setting NSURLConnection Delegate Callbacks
///-------------------------------------------------

/**
 Sets a block to be executed to determine whether the connection should be able to respond to a protection space's form of authentication, as handled by the `NSURLConnectionDelegate` method `connection:canAuthenticateAgainstProtectionSpace:`.
 
 @param block A block object to be executed to determine whether the connection should be able to respond to a protection space's form of authentication. The block has a `BOOL` return type and takes two arguments: the URL connection object, and the protection space to authenticate against.
 
 @discussion If `_AFNETWORKING_ALLOW_INVALID_SSL_CERTIFICATES_` is defined, `connection:canAuthenticateAgainstProtectionSpace:` will accept invalid SSL certificates, returning `YES` if the protection space authentication method is `NSURLAuthenticationMethodServerTrust`.
 */
- (void)setAuthenticationAgainstProtectionSpaceBlock:(BOOL (^)(NSURLConnection *connection, NSURLProtectionSpace *protectionSpace))block;

/**
 Sets a block to be executed when the connection must authenticate a challenge in order to download its request, as handled by the `NSURLConnectionDelegate` method `connection:didReceiveAuthenticationChallenge:`.
 
 @param block A block object to be executed when the connection must authenticate a challenge in order to download its request. The block has no return type and takes two arguments: the URL connection object, and the challenge that must be authenticated.
 
 @discussion If `_AFNETWORKING_ALLOW_INVALID_SSL_CERTIFICATES_` is defined, `connection:didReceiveAuthenticationChallenge:` will attempt to have the challenge sender use credentials with invalid SSL certificates.
 */
- (void)setAuthenticationChallengeBlock:(void (^)(NSURLConnection *connection, NSURLAuthenticationChallenge *challenge))block;

/**
 Sets a block to be executed to modify the response a connection will cache, if any, as handled by the `NSURLConnectionDelegate` method `connection:willCacheResponse:`.
 
 @param block A block object to be executed to determine what response a connection will cache, if any. The block returns an `NSCachedURLResponse` object, the cached response to store in memory or `nil` to prevent the response from being cached, and takes two arguments: the URL connection object, and the cached response provided for the request.
 */
- (void)setCacheResponseBlock:(NSCachedURLResponse * (^)(NSURLConnection *connection, NSCachedURLResponse *cachedResponse))block;

@end
