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
 
 If any of these methods are overriden in a subclass, they _must_ call the `super` implementation first.
 
 Notably, `AFHTTPRequestOperation` does not implement any of the authentication challenge-related `NSURLConnection` delegate methods, and are thus safe to override without a call to `super`.
 
 ## Class Constructors
 
 Class constructors, or methods that return an unowned (zero retain count) instance, are the preferred way for subclasses to encapsulate any particular logic for handling the setup or parsing of response data. For instance, `AFJSONRequestOperation` provides `JSONRequestOperationWithRequest:success:failure:`, which takes block arguments, whose parameter on for a successful request is the JSON object initialized from the `response data`.
 
 ## Callbacks and Completion Blocks
 
 The built-in `completionBlock` provided by `NSOperation` allows for custom behavior to be executed after the request finishes. It is a common pattern for class constructors in subclasses to take callback block parameters, and execute them conditionally in the body of its `completionBlock`. Make sure to handle cancelled operations appropriately when setting a `completionBlock` (e.g. returning early before parsing response data). See the implementation of any of the `AFHTTPRequestOperation` subclasses for an example of this.
 
 @warning Subclasses are strongly discouraged from overriding `setCompletionBlock:`, as `AFURLConnectionOperation`'s implementation includes a workaround to mitigate retain cycles, and what Apple rather ominously refers to as "The Deallocation Problem" (See http://developer.apple.com/library/ios/technotes/tn2109/_index.html#//apple_ref/doc/uid/DTS40010274-CH1-SUBSECTION11) 
 */
@interface AFURLConnectionOperation : NSOperation {
@private
    unsigned short _state;
    BOOL _cancelled;
    NSRecursiveLock *_lock;
    
    NSSet *_runLoopModes;
    
    NSURLConnection *_connection;
    NSURLRequest *_request;
    NSHTTPURLResponse *_response;
    NSError *_error;

    NSData *_responseData;
    NSInteger _totalBytesRead;
    NSMutableData *_dataAccumulator;
    NSOutputStream *_outputStream;
}

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
 
 @discussion By default, data is accumulated into a buffer that is stored into `responseData` upon completion of the request. When `outputStream` is set, the data will not be accumulated into an internal buffer, and as a result, the `responseData` property of the completed request will be `nil`.
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

///---------------------------------
/// @name Setting Progress Callbacks
///---------------------------------

/**
 Sets a callback to be called when an undetermined number of bytes have been downloaded from the server.
 
 @param block A block object to be called when an undetermined number of bytes have been downloaded from the server. This block has no return value and takes three arguments: the number of bytes written since the last time the upload progress block was called, the total bytes written, and the total bytes expected to be written during the request, as initially determined by the length of the HTTP body. This block may be called multiple times.
 
 @see setDownloadProgressBlock
 */
- (void)setUploadProgressBlock:(void (^)(NSInteger bytesWritten, NSInteger totalBytesWritten, NSInteger totalBytesExpectedToWrite))block;

/**
 Sets a callback to be called when an undetermined number of bytes have been uploaded to the server.
 
 @param block A block object to be called when an undetermined number of bytes have been uploaded to the server. This block has no return value and takes three arguments: the number of bytes read since the last time the upload progress block was called, the total bytes read, and the total bytes expected to be read during the request, as initially determined by the expected content size of the `NSHTTPURLResponse` object. This block may be called multiple times.
 
 @see setUploadProgressBlock
 */
- (void)setDownloadProgressBlock:(void (^)(NSInteger bytesRead, NSInteger totalBytesRead, NSInteger totalBytesExpectedToRead))block;

///-------------------------------------------------
/// @name Setting Authentication Challenge Callbacks
///-------------------------------------------------

- (void)setAuthenticationChallengeBlock:(void (^)(NSURLConnection *connection, NSURLAuthenticationChallenge *challenge))block;

@end
