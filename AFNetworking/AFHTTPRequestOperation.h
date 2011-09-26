// AFHTTPOperation.h
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
extern NSString * const AFHTTPOperationDidStartNotification;

/**
 Posted when an operation finishes.
 */
extern NSString * const AFHTTPOperationDidFinishNotification;

/**
  `AFHTTPRequestOperation` is an `NSOperation` that implements the `NSURLConnection` delegate methods, and provides a simple block-based interface to asynchronously get the result and context of that operation finishes.
 
 # Subclassing Notes
 
 In cases where you don't need all of the information provided in the callback, or you want to validate and/or represent it in a different way, it makes sense to create a subclass to define this behavior. 
 
 For instance, `AFJSONRequestOperation` makes a distinction between successful and unsuccessful requests by validating the HTTP status code and content type of the response, and provides separate callbacks for both the succeeding and failing cases. As another example, `AFImageRequestOperation` offers a pared-down callback, with a single block argument that is an image object that was created from the response data.
 
 # Methods to Subclass
 
 Unless you need to override specific `NSURLConnection` delegate methods, you shouldn't need to subclass any methods. Instead, you should provide alternative constructor class methods, that are essentially wrappers around the callback from `AFHTTPRequestOperation`.
 
 ## `NSURLConnection` Delegate Methods
 
 Notably, `AFHTTPRequestOperation` does not implement any of the authentication challenge-related `NSURLConnection` delegate methods.
 
 `AFHTTPRequestOperation` does implement the following `NSURLConnection` delegate methods:
 
 - `connection:didReceiveResponse:`
 - `connection:didReceiveData:`
 - `connectionDidFinishLoading:`
 - `connection:didFailWithError:`
 - `connection:didSendBodyData:totalBytesWritten:totalBytesExpectedToWrite:`
 - `connection:willCacheResponse:`
 
 If you overwrite any of the above methods, be sure to make the call to `super` first, or else it may cause unexpected results.
 
 @see NSOperation
 @see NSURLConnection
 */
@interface AFHTTPRequestOperation : NSOperation {
@private    
    NSSet *_runLoopModes;
    
    NSURLConnection *_connection;
    NSURLRequest *_request;
    NSHTTPURLResponse *_response;
    NSError *_error;
    
    NSData *_responseBody;
    NSUInteger _totalBytesRead;
    NSMutableData *_dataAccumulator;
    NSOutputStream *_outputStream;
}

@property (nonatomic, retain) NSSet *runLoopModes;

@property (readonly, nonatomic, retain) NSURLRequest *request;
@property (readonly, nonatomic, retain) NSHTTPURLResponse *response;
@property (readonly, nonatomic, retain) NSError *error;

@property (readonly, nonatomic, retain) NSData *responseBody;
@property (readonly) NSString *responseString;

///---------------------------------------
/// @name Creating HTTP Request Operations
///---------------------------------------

/**
 Creates and returns an `AFHTTPRequestOperation` object and sets the specified completion callback.
 
 @param urlRequest The request object to be loaded asynchronously during execution of the operation.
 @param completion A block object to be executed when the HTTP request operation is finished. This block has no return value and takes four arguments: the request sent from the client, the response received from the server, the HTTP body received by the server during the execution of the request, and an error, which will have been set if an error occured while loading the request.
 
 @return A new HTTP request operation
 */
+ (AFHTTPRequestOperation *)operationWithRequest:(NSURLRequest *)urlRequest 
                                      completion:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSData *data, NSError *error))completion;

/**
 Creates and returns a streaming `AFHTTPRequestOperation` object and sets the specified input stream, output stream, and completion callback.
 
 @param urlRequest The request object to be loaded asynchronously during execution of the operation.
 @param inputStream The input stream object for reading data to be sent during the request. If set, the input stream is set as the `HTTPBodyStream` on the `NSMutableURLRequest`. If the request method is `GET`, it is changed to `POST`. This argument may be `nil`.
 @param outputStream The output stream object for writing data received during the request. If set, data accumulated in `NSURLConnectionDelegate` methods will be sent to the output stream, and the NSData parameter in the completion block will be `nil`. This argument may be `nil`.
 @param completion A block object to be executed when the HTTP request operation is finished. This block has no return value and takes four arguments: the request sent from the client, the response received from the server, the data received by the server during the execution of the request, and an error, which will have been set if an error occured while loading the request. This argument may be `nil`.
 
 @see operationWithRequest:completion
 
 @return A new streaming HTTP request operation
 */
+ (AFHTTPRequestOperation *)streamingOperationWithRequest:(NSURLRequest *)urlRequest
                                              inputStream:(NSInputStream *)inputStream
                                             outputStream:(NSOutputStream *)outputStream
                                               completion:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error))completion;

///---------------------------------
/// @name Setting Progress Callbacks
///---------------------------------

/**
 Sets a callback to be called when an undetermined number of bytes have been downloaded from the server.
 
 @param block A block object to be called when an undetermined number of bytes have been downloaded from the server. This block has no return value and takes two arguments: the total bytes written, and the total bytes expected to be written during the request, as initially determined by the length of the HTTP body. This block may be called multiple times.
 
 @see setDownloadProgressBlock
 */
- (void)setUploadProgressBlock:(void (^)(NSUInteger totalBytesWritten, NSUInteger totalBytesExpectedToWrite))block;

/**
 Sets a callback to be called when an undetermined number of bytes have been uploaded to the server.
 
 @param block A block object to be called when an undetermined number of bytes have been uploaded to the server. This block has no return value and takes two arguments: the total bytes read, and the total bytes expected to be read during the request, as initially determined by the expected content size of the `NSHTTPURLResponse` object. This block may be called multiple times.
 
 @see setUploadProgressBlock
 */
- (void)setDownloadProgressBlock:(void (^)(NSUInteger totalBytesRead, NSUInteger totalBytesExpectedToRead))block;

@end
