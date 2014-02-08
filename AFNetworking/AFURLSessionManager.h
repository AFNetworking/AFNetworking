// AFURLSessionManager.h
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
#import "AFURLRequestSerialization.h"
#import "AFSecurityPolicy.h"
#import "AFNetworkReachabilityManager.h"

/**
 `AFURLSessionManager` creates and manages an `NSURLSession` object based on a specified `NSURLSessionConfiguration` object, which conforms to `<NSURLSessionTaskDelegate>`, `<NSURLSessionDataDelegate>`, `<NSURLSessionDownloadDelegate>`, and `<NSURLSessionDelegate>`.
 
 ## Subclassing Notes
 
 This is the base class for `AFHTTPSessionManager`, which adds functionality specific to making HTTP requests. If you are looking to extend `AFURLSessionManager` specifically for HTTP, consider subclassing `AFHTTPSessionManager` instead.
 
 ## NSURLSession & NSURLSessionTask Delegate Methods
 
 `AFURLSessionManager` implements the following delegate methods:
 
 ### `NSURLSessionDelegate`
 
 - `URLSession:didBecomeInvalidWithError:`
 - `URLSession:didReceiveChallenge:completionHandler:`

 ### `NSURLSessionTaskDelegate`
 
 - `URLSession:willPerformHTTPRedirection:newRequest:completionHandler:`
 - `URLSession:task:didReceiveChallenge:completionHandler:`
 - `URLSession:task:didSendBodyData:totalBytesSent:totalBytesExpectedToSend:`
 - `URLSession:task:didCompleteWithError:`

 ### `NSURLSessionDataDelegate`
 
 - `URLSession:dataTask:didReceiveResponse:completionHandler:`
 - `URLSession:dataTask:didBecomeDownloadTask:`
 - `URLSession:dataTask:didReceiveData:`
 - `URLSession:dataTask:willCacheResponse:completionHandler:`
 - `URLSessionDidFinishEventsForBackgroundURLSession:`

 ### `NSURLSessionDownloadDelegate`

 - `URLSession:downloadTask:didFinishDownloadingToURL:`
 - `URLSession:downloadTask:didWriteData:totalBytesWritten:totalBytesWritten:totalBytesExpectedToWrite:`
 - `URLSession:downloadTask:didResumeAtOffset:expectedTotalBytes:`
 
 If any of these methods are overridden in a subclass, they _must_ call the `super` implementation first.
 
 ## Network Reachability Monitoring

 Network reachability status and change monitoring is available through the `reachabilityManager` property. Applications may choose to monitor network reachability conditions in order to prevent or suspend any outbound requests. See `AFNetworkReachabilityManager` for more details.
 
 ## NSCoding Caveats
 
 - Encoded managers do not include any block properties. Be sure to set delegate callback blocks when using `-initWithCoder:` or `NSKeyedUnarchiver`.

 ## NSCopying Caveats

 - `-copy` and `-copyWithZone:` return a new manager with a new `NSURLSession` created from the configuration of the original.
 - Operation copies do not include any delegate callback blocks, as they often strongly captures a reference to `self`, which would otherwise have the unintuitive side-effect of pointing to the _original_ session manager when copied.
 */

#if (defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000) || (defined(__MAC_OS_X_VERSION_MAX_ALLOWED) && __MAC_OS_X_VERSION_MAX_ALLOWED >= 1090)

@interface AFURLSessionManager : NSObject <NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate, NSURLSessionDownloadDelegate, NSCoding, NSCopying>

/**
 The managed session.
 */
@property (readonly, nonatomic, strong) NSURLSession *session;

/**
 The operation queue on which delegate callbacks are run.
 */
@property (readonly, nonatomic, strong) NSOperationQueue *operationQueue;

/**
 Responses sent from the server in data tasks created with `dataTaskWithRequest:success:failure:` and run using the `GET` / `POST` / et al. convenience methods are automatically validated and serialized by the response serializer. By default, this property is set to an instance of `AFJSONResponseSerializer`.

 @warning `responseSerializer` must not be `nil`.
 */
@property (nonatomic, strong) id <AFURLResponseSerialization> responseSerializer;

///-------------------------------
/// @name Managing Security Policy
///-------------------------------

/**
 The security policy used by created request operations to evaluate server trust for secure connections. `AFURLSessionManager` uses the `defaultPolicy` unless otherwise specified.
 */
@property (nonatomic, strong) AFSecurityPolicy *securityPolicy;

///--------------------------------------
/// @name Monitoring Network Reachability
///--------------------------------------

/**
 The network reachability manager. `AFURLSessionManager` uses the `sharedManager` by default.
 */
@property (readwrite, nonatomic, strong) AFNetworkReachabilityManager *reachabilityManager;

///----------------------------
/// @name Getting Session Tasks
///----------------------------

/**
 The data, upload, and download tasks currently run by the managed session.
 */
@property (readonly, nonatomic, strong) NSArray *tasks;

/**
 The data tasks currently run by the managed session.
 */
@property (readonly, nonatomic, strong) NSArray *dataTasks;

/**
 The upload tasks currently run by the managed session.
 */
@property (readonly, nonatomic, strong) NSArray *uploadTasks;

/**
 The download tasks currently run by the managed session.
 */
@property (readonly, nonatomic, strong) NSArray *downloadTasks;

///---------------------------------
/// @name Managing Callback Queues
///---------------------------------

/**
 The dispatch queue for `completionBlock`. If `NULL` (default), the main queue is used.
 */
@property (nonatomic, strong) dispatch_queue_t completionQueue;

/**
 The dispatch group for `completionBlock`. If `NULL` (default), a private dispatch group is used.
 */
@property (nonatomic, strong) dispatch_group_t completionGroup;

///---------------------
/// @name Initialization
///---------------------

/**
 Creates and returns a manager for a session created with the specified configuration. This is the designated initializer.
 
 @param configuration The configuration used to create the managed session.
 
 @return A manager for a newly-created session.
 */
- (instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration *)configuration;

/**
 Invalidates the managed session, optionally canceling pending tasks.
 
 @param cancelPendingTasks Whether or not to cancel pending tasks.
 */
- (void)invalidateSessionCancelingTasks:(BOOL)cancelPendingTasks;

///-------------------------
/// @name Running Data Tasks
///-------------------------

/**
 Creates an `NSURLSessionDataTask` with the specified request.

 @param request The HTTP request for the request.
 @param completionHandler A block object to be executed when the task finishes. This block has no return value and takes three arguments: the server response, the response object created by that serializer, and the error that occurred, if any.
 */
- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request
                            completionHandler:(void (^)(NSURLResponse *response, id responseObject, NSError *error))completionHandler;

///---------------------------
/// @name Running Upload Tasks
///---------------------------

/**
 Creates an `NSURLSessionUploadTask` with the specified request for a local file.

 @param request The HTTP request for the request.
 @param fileURL A URL to the local file to be uploaded.
 @param progress A progress object monitoring the current upload progress.
 @param completionHandler A block object to be executed when the task finishes. This block has no return value and takes three arguments: the server response, the response object created by that serializer, and the error that occurred, if any.
 */
- (NSURLSessionUploadTask *)uploadTaskWithRequest:(NSURLRequest *)request
                                         fromFile:(NSURL *)fileURL
                                         progress:(NSProgress * __autoreleasing *)progress
                                completionHandler:(void (^)(NSURLResponse *response, id responseObject, NSError *error))completionHandler;

/**
 Creates an `NSURLSessionUploadTask` with the specified request for an HTTP body.

 @param request The HTTP request for the request.
 @param bodyData A data object containing the HTTP body to be uploaded.
 @param progress A progress object monitoring the current upload progress.
 @param completionHandler A block object to be executed when the task finishes. This block has no return value and takes three arguments: the server response, the response object created by that serializer, and the error that occurred, if any.
 */
- (NSURLSessionUploadTask *)uploadTaskWithRequest:(NSURLRequest *)request
                                         fromData:(NSData *)bodyData
                                         progress:(NSProgress * __autoreleasing *)progress
                                completionHandler:(void (^)(NSURLResponse *response, id responseObject, NSError *error))completionHandler;

/**
 Creates an `NSURLSessionUploadTask` with the specified streaming request.

 @param request The HTTP request for the request.
 @param progress A progress object monitoring the current upload progress.
 @param completionHandler A block object to be executed when the task finishes. This block has no return value and takes three arguments: the server response, the response object created by that serializer, and the error that occurred, if any.
 */
- (NSURLSessionUploadTask *)uploadTaskWithStreamedRequest:(NSURLRequest *)request
                                                 progress:(NSProgress * __autoreleasing *)progress
                                        completionHandler:(void (^)(NSURLResponse *response, id responseObject, NSError *error))completionHandler;

///-----------------------------
/// @name Running Download Tasks
///-----------------------------

/**
 Creates an `NSURLSessionDownloadTask` with the specified request.

 @param request The HTTP request for the request.
 @param progress A progress object monitoring the current download progress.
 @param destination A block object to be executed in order to determine the destination of the downloaded file. This block takes two arguments, the target path & the server response, and returns the desired file URL of the resulting download. The temporary file used during the download will be automatically deleted after being moved to the returned URL.
 @param completionHandler A block to be executed when a task finishes. This block has no return value and takes three arguments: the server response, the path of the downloaded file, and the error describing the network or parsing error that occurred, if any.
 */
- (NSURLSessionDownloadTask *)downloadTaskWithRequest:(NSURLRequest *)request
                                             progress:(NSProgress * __autoreleasing *)progress
                                          destination:(NSURL * (^)(NSURL *targetPath, NSURLResponse *response))destination
                                    completionHandler:(void (^)(NSURLResponse *response, NSURL *filePath, NSError *error))completionHandler;

/**
 Creates an `NSURLSessionDownloadTask` with the specified resume data.

 @param resumeData The data used to resume downloading.
 @param progress A progress object monitoring the current download progress.
 @param destination A block object to be executed in order to determine the destination of the downloaded file. This block takes two arguments, the target path & the server response, and returns the desired file URL of the resulting download. The temporary file used during the download will be automatically deleted after being moved to the returned URL.
 @param completionHandler A block to be executed when a task finishes. This block has no return value and takes three arguments: the server response, the path of the downloaded file, and the error describing the network or parsing error that occurred, if any.
 */
- (NSURLSessionDownloadTask *)downloadTaskWithResumeData:(NSData *)resumeData
                                                progress:(NSProgress * __autoreleasing *)progress
                                             destination:(NSURL * (^)(NSURL *targetPath, NSURLResponse *response))destination
                                       completionHandler:(void (^)(NSURLResponse *response, NSURL *filePath, NSError *error))completionHandler;

///-----------------------------------------
/// @name Setting Session Delegate Callbacks
///-----------------------------------------

/**
 Sets a block to be executed when the managed session becomes invalid, as handled by the `NSURLSessionDelegate` method `URLSession:didBecomeInvalidWithError:`.
 
 @param block A block object to be executed when the managed session becomes invalid. The block has no return value, and takes two arguments: the session, and the error related to the cause of invalidation.
 */
- (void)setSessionDidBecomeInvalidBlock:(void (^)(NSURLSession *session, NSError *error))block;

/**
 Sets a block to be executed when a connection level authentication challenge has occurred, as handled by the `NSURLSessionDelegate` method `URLSession:didReceiveChallenge:completionHandler:`.

 @param block A block object to be executed when a connection level authentication challenge has occurred. The block returns the disposition of the authentication challenge, and takes three arguments: the session, the authentication challenge, and a pointer to the credential that should be used to resolve the challenge.
 */
- (void)setSessionDidReceiveAuthenticationChallengeBlock:(NSURLSessionAuthChallengeDisposition (^)(NSURLSession *session, NSURLAuthenticationChallenge *challenge, NSURLCredential * __autoreleasing *credential))block;

///--------------------------------------
/// @name Setting Task Delegate Callbacks
///--------------------------------------

/**
 Sets a block to be executed when an HTTP request is attempting to perform a redirection to a different URL, as handled by the `NSURLSessionTaskDelegate` method `URLSession:willPerformHTTPRedirection:newRequest:completionHandler:`.
 
 @param block A block object to be executed when an HTTP request is attempting to perform a redirection to a different URL. The block returns the request to be made for the redirection, and takes four arguments: the session, the task, the redirection response, and the request corresponding to the redirection response.
 */
- (void)setTaskWillPerformHTTPRedirectionBlock:(NSURLRequest * (^)(NSURLSession *session, NSURLSessionTask *task, NSURLResponse *response, NSURLRequest *request))block;

/**
 Sets a block to be executed when a session task has received a request specific authentication challenge, as handled by the `NSURLSessionTaskDelegate` method `URLSession:task:didReceiveChallenge:completionHandler:`.
 
 @param block A block object to be executed when a session task has received a request specific authentication challenge. The block returns the disposition of the authentication challenge, and takes four arguments: the session, the task, the authentication challenge, and a pointer to the credential that should be used to resolve the challenge.
 */
- (void)setTaskDidReceiveAuthenticationChallengeBlock:(NSURLSessionAuthChallengeDisposition (^)(NSURLSession *session, NSURLSessionTask *task, NSURLAuthenticationChallenge *challenge, NSURLCredential * __autoreleasing *credential))block;

/**
 Sets a block to be executed periodically to track upload progress, as handled by the `NSURLSessionTaskDelegate` method `URLSession:task:didSendBodyData:totalBytesSent:totalBytesExpectedToSend:`.
 
 @param block A block object to be called when an undetermined number of bytes have been uploaded to the server. This block has no return value and takes five arguments: the session, the task, the number of bytes written since the last time the upload progress block was called, the total bytes written, and the total bytes expected to be written during the request, as initially determined by the length of the HTTP body. This block may be called multiple times, and will execute on the main thread.
 */
- (void)setTaskDidSendBodyDataBlock:(void (^)(NSURLSession *session, NSURLSessionTask *task, int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend))block;

/**
 Sets a block to be executed as the last message related to a specific task, as handled by the `NSURLSessionTaskDelegate` method `URLSession:task:didCompleteWithError:`.
 
 @param block A block object to be executed when a session task is completed. The block has no return value, and takes three arguments: the session, the task, and any error that occurred in the process of executing the task.
 */
- (void)setTaskDidCompleteBlock:(void (^)(NSURLSession *session, NSURLSessionTask *task, NSError *error))block;

///-------------------------------------------
/// @name Setting Data Task Delegate Callbacks
///-------------------------------------------

/**
 Sets a block to be executed when a data task has received a response, as handled by the `NSURLSessionDataDelegate` method `URLSession:dataTask:didReceiveResponse:completionHandler:`.

 @param block A block object to be executed when a data task has received a response. The block returns the disposition of the session response, and takes three arguments: the session, the data task, and the received response.
 */
- (void)setDataTaskDidReceiveResponseBlock:(NSURLSessionResponseDisposition (^)(NSURLSession *session, NSURLSessionDataTask *dataTask, NSURLResponse *response))block;

/**
 Sets a block to be executed when a data task has become a download task, as handled by the `NSURLSessionDataDelegate` method `URLSession:dataTask:didBecomeDownloadTask:`.
 
 @param block A block object to be executed when a data task has become a download task. The block has no return value, and takes three arguments: the session, the data task, and the download task it has become.
 */
- (void)setDataTaskDidBecomeDownloadTaskBlock:(void (^)(NSURLSession *session, NSURLSessionDataTask *dataTask, NSURLSessionDownloadTask *downloadTask))block;

/**
 Sets a block to be executed when a data task receives data, as handled by the `NSURLSessionDataDelegate` method `URLSession:dataTask:didReceiveData:`.
 
 @param block A block object to be called when an undetermined number of bytes have been downloaded from the server. This block has no return value and takes three arguments: the session, the data task, and the data received. This block may be called multiple times, and will execute on the session manager operation queue.
 */
- (void)setDataTaskDidReceiveDataBlock:(void (^)(NSURLSession *session, NSURLSessionDataTask *dataTask, NSData *data))block;

/**
 Sets a block to be executed to determine the caching behavior of a data task, as handled by the `NSURLSessionDataDelegate` method `URLSession:dataTask:willCacheResponse:completionHandler:`.
 
 @param block A block object to be executed to determine the caching behavior of a data task. The block returns the response to cache, and takes three arguments: the session, the data task, and the proposed cached URL response.
 */
- (void)setDataTaskWillCacheResponseBlock:(NSCachedURLResponse * (^)(NSURLSession *session, NSURLSessionDataTask *dataTask, NSCachedURLResponse *proposedResponse))block;

/**
 Sets a block to be executed once all messages enqueued for a session have been delivered, as handled by the `NSURLSessionDataDelegate` method `URLSessionDidFinishEventsForBackgroundURLSession:`.
 
 @param block A block object to be executed once all messages enqueued for a session have been delivered. The block has no return value and takes a single argument: the session.
 */
- (void)setDidFinishEventsForBackgroundURLSessionBlock:(void (^)(NSURLSession *session))block;

///-----------------------------------------------
/// @name Setting Download Task Delegate Callbacks
///-----------------------------------------------

/**
 Sets a block to be executed when a download task has completed a download, as handled by the `NSURLSessionDownloadDelegate` method `URLSession:downloadTask:didFinishDownloadingToURL:`.
 
 @param block A block object to be executed when a download task has completed. The block returns the URL the download should be moved to, and takes three arguments: the session, the download task, and the temporary location of the downloaded file. If the file manager encounters an error while attempting to move the temporary file to the destination, an `AFURLSessionDownloadTaskDidFailToMoveFileNotification` will be posted, with the download task as its object, and the user info of the error.
 */
- (void)setDownloadTaskDidFinishDownloadingBlock:(NSURL * (^)(NSURLSession *session, NSURLSessionDownloadTask *downloadTask, NSURL *location))block;

/**
 Sets a block to be executed periodically to track download progress, as handled by the `NSURLSessionDownloadDelegate` method `URLSession:downloadTask:didWriteData:totalBytesWritten:totalBytesWritten:totalBytesExpectedToWrite:`.
 
 @param block A block object to be called when an undetermined number of bytes have been downloaded from the server. This block has no return value and takes five arguments: the session, the download task, the number of bytes read since the last time the download progress block was called, the total bytes read, and the total bytes expected to be read during the request, as initially determined by the expected content size of the `NSHTTPURLResponse` object. This block may be called multiple times, and will execute on the session manager operation queue.
 */
- (void)setDownloadTaskDidWriteDataBlock:(void (^)(NSURLSession *session, NSURLSessionDownloadTask *downloadTask, int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite))block;

/**
 Sets a block to be executed when a download task has been resumed, as handled by the `NSURLSessionDownloadDelegate` method `URLSession:downloadTask:didResumeAtOffset:expectedTotalBytes:`.
 
 @param block A block object to be executed when a download task has been resumed. The block has no return value and takes four arguments: the session, the download task, the file offset of the resumed download, and the total number of bytes expected to be downloaded.
 */
- (void)setDownloadTaskDidResumeBlock:(void (^)(NSURLSession *session, NSURLSessionDownloadTask *downloadTask, int64_t fileOffset, int64_t expectedTotalBytes))block;

@end

#endif

///--------------------
/// @name Notifications
///--------------------

/**
 Posted when a task begins executing.
 
 @deprecated Use `AFNetworkingTaskDidResumeNotification` instead.
 */
extern NSString * const AFNetworkingTaskDidStartNotification DEPRECATED_ATTRIBUTE;

/**
 Posted when a task resumes.
 */
extern NSString * const AFNetworkingTaskDidResumeNotification;

/**
 Posted when a task finishes executing. Includes a userInfo dictionary with additional information about the task.
 
 @deprecated Use `AFNetworkingTaskDidCompleteNotification` instead.
 */
extern NSString * const AFNetworkingTaskDidFinishNotification DEPRECATED_ATTRIBUTE;

/**
 Posted when a task finishes executing. Includes a userInfo dictionary with additional information about the task.
 */
extern NSString * const AFNetworkingTaskDidCompleteNotification;

/**
 Posted when a task suspends its execution.
 */
extern NSString * const AFNetworkingTaskDidSuspendNotification;

/**
 Posted when a session is invalidated.
 */
extern NSString * const AFURLSessionDidInvalidateNotification;

/**
 Posted when a session download task encountered an error when moving the temporary download file to a specified destination.
 */
extern NSString * const AFURLSessionDownloadTaskDidFailToMoveFileNotification;

/**
 The raw response data of the task. Included in the userInfo dictionary of the `AFNetworkingTaskDidFinishNotification` if response data exists for the task.
 
 @deprecated Use `AFNetworkingTaskDidCompleteResponseDataKey` instead.
 */
extern NSString * const AFNetworkingTaskDidFinishResponseDataKey DEPRECATED_ATTRIBUTE;

/**
 The raw response data of the task. Included in the userInfo dictionary of the `AFNetworkingTaskDidFinishNotification` if response data exists for the task.
 */
extern NSString * const AFNetworkingTaskDidCompleteResponseDataKey;

/**
 The serialized response object of the task. Included in the userInfo dictionary of the `AFNetworkingTaskDidFinishNotification` if the response was serialized.
 
 @deprecated Use `AFNetworkingTaskDidCompleteSerializedResponseKey` instead.
 */
extern NSString * const AFNetworkingTaskDidFinishSerializedResponseKey DEPRECATED_ATTRIBUTE;

/**
 The serialized response object of the task. Included in the userInfo dictionary of the `AFNetworkingTaskDidFinishNotification` if the response was serialized.
 */
extern NSString * const AFNetworkingTaskDidCompleteSerializedResponseKey;

/**
 The response serializer used to serialize the response. Included in the userInfo dictionary of the `AFNetworkingTaskDidFinishNotification` if the task has an associated response serializer.
 
 @deprecated Use `AFNetworkingTaskDidCompleteResponseSerializerKey` instead.
 */
extern NSString * const AFNetworkingTaskDidFinishResponseSerializerKey DEPRECATED_ATTRIBUTE;

/**
 The response serializer used to serialize the response. Included in the userInfo dictionary of the `AFNetworkingTaskDidFinishNotification` if the task has an associated response serializer.
 */
extern NSString * const AFNetworkingTaskDidCompleteResponseSerializerKey;

/**
 The file path associated with the download task. Included in the userInfo dictionary of the `AFNetworkingTaskDidFinishNotification` if an the response data has been stored directly to disk.
 
 @deprecated Use `AFNetworkingTaskDidCompleteAssetPathKey` instead.
 */
extern NSString * const AFNetworkingTaskDidFinishAssetPathKey DEPRECATED_ATTRIBUTE;

/**
 The file path associated with the download task. Included in the userInfo dictionary of the `AFNetworkingTaskDidFinishNotification` if an the response data has been stored directly to disk.
 */
extern NSString * const AFNetworkingTaskDidCompleteAssetPathKey;

/**
 Any error associated with the task, or the serialization of the response. Included in the userInfo dictionary of the `AFNetworkingTaskDidFinishNotification` if an error exists.
 
 @deprecated Use `AFNetworkingTaskDidCompleteErrorKey` instead.
 */
extern NSString * const AFNetworkingTaskDidFinishErrorKey DEPRECATED_ATTRIBUTE;

/**
 Any error associated with the task, or the serialization of the response. Included in the userInfo dictionary of the `AFNetworkingTaskDidFinishNotification` if an error exists.
 */
extern NSString * const AFNetworkingTaskDidCompleteErrorKey;
