// AFURLSessionManager.h
// Copyright (c) 2011–2015 Alamofire Software Foundation (http://alamofire.org/)
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
#if !TARGET_OS_WATCH
#import "AFNetworkReachabilityManager.h"
#endif

#ifndef NS_DESIGNATED_INITIALIZER
#if __has_attribute(objc_designated_initializer)
#define NS_DESIGNATED_INITIALIZER __attribute__((objc_designated_initializer))
#else
#define NS_DESIGNATED_INITIALIZER
#endif
#endif

/**
 `AFURLSessionManager` creates and manages an `NSURLSession` object based on a specified `NSURLSessionConfiguration` object, which conforms to `<NSURLSessionTaskDelegate>`, `<NSURLSessionDataDelegate>`, `<NSURLSessionDownloadDelegate>`, and `<NSURLSessionDelegate>`.

 ## Subclassing Notes

 This is the base class for `AFHTTPSessionManager`, which adds functionality specific to making HTTP requests. If you are looking to extend `AFURLSessionManager` specifically for HTTP, consider subclassing `AFHTTPSessionManager` instead.

 ## NSURLSession & NSURLSessionTask Delegate Methods

 `AFURLSessionManager` implements the following delegate methods:

 ### `NSURLSessionDelegate`

 - `URLSession:didBecomeInvalidWithError:`
 - `URLSession:didReceiveChallenge:completionHandler:`
 - `URLSessionDidFinishEventsForBackgroundURLSession:`

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

 @warning Managers for background sessions must be owned for the duration of their use. This can be accomplished by creating an application-wide or shared singleton instance.
 */

NS_ASSUME_NONNULL_BEGIN

#if (defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000) || (defined(__MAC_OS_X_VERSION_MAX_ALLOWED) && __MAC_OS_X_VERSION_MAX_ALLOWED >= 1090) || TARGET_OS_WATCH

@interface AFURLSessionManager : NSObject <NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate, NSURLSessionDownloadDelegate, NSSecureCoding, NSCopying>

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

#if !TARGET_OS_WATCH
///--------------------------------------
/// @name Monitoring Network Reachability
///--------------------------------------

/**
 The network reachability manager. `AFURLSessionManager` uses the `sharedManager` by default.
 */
@property (readwrite, nonatomic, strong) AFNetworkReachabilityManager *reachabilityManager;
#endif

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

///-------------------------------
/// @name Managing Callback Queues
///-------------------------------

/**
 The dispatch queue for `completionBlock`. If `NULL` (default), the main queue is used.
 */
#if OS_OBJECT_HAVE_OBJC_SUPPORT
@property (nonatomic, strong, nullable) dispatch_queue_t completionQueue;
#else
@property (nonatomic, assign, nullable) dispatch_queue_t completionQueue;
#endif

/**
 The dispatch group for `completionBlock`. If `NULL` (default), a private dispatch group is used.
 */
#if OS_OBJECT_HAVE_OBJC_SUPPORT
@property (nonatomic, strong, nullable) dispatch_group_t completionGroup;
#else
@property (nonatomic, assign, nullable) dispatch_group_t completionGroup;
#endif

///---------------------------------
/// @name Working Around System Bugs
///---------------------------------

/**
 Whether to attempt to retry creation of upload tasks for background sessions when initial call returns `nil`. `NO` by default.

 @bug As of iOS 7.0, there is a bug where upload tasks created for background tasks are sometimes `nil`. As a workaround, if this property is `YES`, AFNetworking will follow Apple's recommendation to try creating the task again.

 @see https://github.com/AFNetworking/AFNetworking/issues/1675
 */
@property (nonatomic, assign) BOOL attemptsToRecreateUploadTasksForBackgroundSessions;

///---------------------
/// @name Initialization
///---------------------

/**
 Creates and returns a manager for a session created with the specified configuration. This is the designated initializer.

 @param configuration The configuration used to create the managed session.

 @return A manager for a newly-created session.
 */
- (instancetype)initWithSessionConfiguration:(nullable NSURLSessionConfiguration *)configuration NS_DESIGNATED_INITIALIZER;

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
                            completionHandler:(nullable void (^)(NSURLResponse *response, id __nullable responseObject,  NSError * __nullable error))completionHandler;

///---------------------------
/// @name Running Upload Tasks
///---------------------------

/**
 Creates an `NSURLSessionUploadTask` with the specified request for a local file.

 @param request The HTTP request for the request.
 @param fileURL A URL to the local file to be uploaded.
 @param progress A progress object monitoring the current upload progress.
 @param completionHandler A block object to be executed when the task finishes. This block has no return value and takes three arguments: the server response, the response object created by that serializer, and the error that occurred, if any.

 @see `attemptsToRecreateUploadTasksForBackgroundSessions`
 */
- (NSURLSessionUploadTask *)uploadTaskWithRequest:(NSURLRequest *)request
                                         fromFile:(NSURL *)fileURL
                                         progress:(NSProgress * __nullable __autoreleasing * __nullable)progress
                                completionHandler:(nullable void (^)(NSURLResponse *response, id __nullable responseObject, NSError  * __nullable error))completionHandler;

/**
 Creates an `NSURLSessionUploadTask` with the specified request for an HTTP body.

 @param request The HTTP request for the request.
 @param bodyData A data object containing the HTTP body to be uploaded.
 @param progress A progress object monitoring the current upload progress.
 @param completionHandler A block object to be executed when the task finishes. This block has no return value and takes three arguments: the server response, the response object created by that serializer, and the error that occurred, if any.
 */
- (NSURLSessionUploadTask *)uploadTaskWithRequest:(NSURLRequest *)request
                                         fromData:(nullable NSData *)bodyData
                                         progress:(NSProgress * __nullable __autoreleasing * __nullable)progress
                                completionHandler:(nullable void (^)(NSURLResponse *response, id __nullable responseObject, NSError * __nullable error))completionHandler;

/**
 Creates an `NSURLSessionUploadTask` with the specified streaming request.

 @param request The HTTP request for the request.
 @param progress A progress object monitoring the current upload progress.
 @param completionHandler A block object to be executed when the task finishes. This block has no return value and takes three arguments: the server response, the response object created by that serializer, and the error that occurred, if any.
 */
- (NSURLSessionUploadTask *)uploadTaskWithStreamedRequest:(NSURLRequest *)request
                                                 progress:(NSProgress * __nullable __autoreleasing * __nullable)progress
                                        completionHandler:(nullable void (^)(NSURLResponse *response, id __nullable responseObject, NSError * __nullable error))completionHandler;

///-----------------------------
/// @name Running Download Tasks
///-----------------------------

/**
 Creates an `NSURLSessionDownloadTask` with the specified request.

 @param request The HTTP request for the request.
 @param progress A progress object monitoring the current download progress.
 @param destination A block object to be executed in order to determine the destination of the downloaded file. This block takes two arguments, the target path & the server response, and returns the desired file URL of the resulting download. The temporary file used during the download will be automatically deleted after being moved to the returned URL.
 @param completionHandler A block to be executed when a task finishes. This block has no return value and takes three arguments: the server response, the path of the downloaded file, and the error describing the network or parsing error that occurred, if any.

 @warning If using a background `NSURLSessionConfiguration` on iOS, these blocks will be lost when the app is terminated. Background sessions may prefer to use `-setDownloadTaskDidFinishDownloadingBlock:` to specify the URL for saving the downloaded file, rather than the destination block of this method.
 */
- (NSURLSessionDownloadTask *)downloadTaskWithRequest:(NSURLRequest *)request
                                             progress:(NSProgress * __nullable __autoreleasing * __nullable)progress
                                          destination:(nullable NSURL * (^)(NSURL *targetPath, NSURLResponse *response))destination
                                    completionHandler:(nullable void (^)(NSURLResponse *response, NSURL * __nullable filePath, NSError * __nullable error))completionHandler;

/**
 Creates an `NSURLSessionDownloadTask` with the specified resume data.

 @param resumeData The data used to resume downloading.
 @param progress A progress object monitoring the current download progress.
 @param destination A block object to be executed in order to determine the destination of the downloaded file. This block takes two arguments, the target path & the server response, and returns the desired file URL of the resulting download. The temporary file used during the download will be automatically deleted after being moved to the returned URL.
 @param completionHandler A block to be executed when a task finishes. This block has no return value and takes three arguments: the server response, the path of the downloaded file, and the error describing the network or parsing error that occurred, if any.
 */
- (NSURLSessionDownloadTask *)downloadTaskWithResumeData:(NSData *)resumeData
                                                progress:(NSProgress * __nullable __autoreleasing * __nullable)progress
                                             destination:(nullable NSURL * (^)(NSURL *targetPath, NSURLResponse *response))destination
                                       completionHandler:(nullable void (^)(NSURLResponse *response, NSURL * __nullable filePath, NSError * __nullable error))completionHandler;

///---------------------------------
/// @name Getting Progress for Tasks
///---------------------------------

/**
 Returns the upload progress of the specified task.

 @param uploadTask The session upload task. Must not be `nil`.

 @return An `NSProgress` object reporting the upload progress of a task, or `nil` if the progress is unavailable.
 */
- (nullable NSProgress *)uploadProgressForTask:(NSURLSessionUploadTask *)uploadTask;

/**
 Returns the download progress of the specified task.

 @param downloadTask The session download task. Must not be `nil`.

 @return An `NSProgress` object reporting the download progress of a task, or `nil` if the progress is unavailable.
 */
- (nullable NSProgress *)downloadProgressForTask:(NSURLSessionDownloadTask *)downloadTask;

///-----------------------------------------
/// @name Setting Session Delegate Callbacks
///-----------------------------------------

/**
 Sets a block to be executed when the managed session becomes invalid, as handled by the `NSURLSessionDelegate` method `URLSession:didBecomeInvalidWithError:`.

 @param block A block object to be executed when the managed session becomes invalid. The block has no return value, and takes two arguments: the session, and the error related to the cause of invalidation.
 */
- (void)setSessionDidBecomeInvalidBlock:(nullable void (^)(NSURLSession *session, NSError *error))block;

/**
 Sets a block to be executed when a connection level authentication challenge has occurred, as handled by the `NSURLSessionDelegate` method `URLSession:didReceiveChallenge:completionHandler:`.

 @param block A block object to be executed when a connection level authentication challenge has occurred. The block returns the disposition of the authentication challenge, and takes three arguments: the session, the authentication challenge, and a pointer to the credential that should be used to resolve the challenge.
 */
- (void)setSessionDidReceiveAuthenticationChallengeBlock:(nullable NSURLSessionAuthChallengeDisposition (^)(NSURLSession *session, NSURLAuthenticationChallenge *challenge, NSURLCredential * __nullable __autoreleasing * __nullable credential))block;

///--------------------------------------
/// @name Setting Task Delegate Callbacks
///--------------------------------------

/**
 Sets a block to be executed when a task requires a new request body stream to send to the remote server, as handled by the `NSURLSessionTaskDelegate` method `URLSession:task:needNewBodyStream:`.

 @param block A block object to be executed when a task requires a new request body stream.
 */
- (void)setTaskNeedNewBodyStreamBlock:(nullable NSInputStream * (^)(NSURLSession *session, NSURLSessionTask *task))block;

/**
 Sets a block to be executed when an HTTP request is attempting to perform a redirection to a different URL, as handled by the `NSURLSessionTaskDelegate` method `URLSession:willPerformHTTPRedirection:newRequest:completionHandler:`.

 @param block A block object to be executed when an HTTP request is attempting to perform a redirection to a different URL. The block returns the request to be made for the redirection, and takes four arguments: the session, the task, the redirection response, and the request corresponding to the redirection response.
 */
- (void)setTaskWillPerformHTTPRedirectionBlock:(nullable NSURLRequest * (^)(NSURLSession *session, NSURLSessionTask *task, NSURLResponse *response, NSURLRequest *request))block;

/**
 Sets a block to be executed when a session task has received a request specific authentication challenge, as handled by the `NSURLSessionTaskDelegate` method `URLSession:task:didReceiveChallenge:completionHandler:`.

 @param block A block object to be executed when a session task has received a request specific authentication challenge. The block returns the disposition of the authentication challenge, and takes four arguments: the session, the task, the authentication challenge, and a pointer to the credential that should be used to resolve the challenge.
 */
- (void)setTaskDidReceiveAuthenticationChallengeBlock:(nullable NSURLSessionAuthChallengeDisposition (^)(NSURLSession *session, NSURLSessionTask *task, NSURLAuthenticationChallenge *challenge, NSURLCredential * __nullable __autoreleasing * __nullable credential))block;

/**
 Sets a block to be executed periodically to track upload progress, as handled by the `NSURLSessionTaskDelegate` method `URLSession:task:didSendBodyData:totalBytesSent:totalBytesExpectedToSend:`.

 @param block A block object to be called when an undetermined number of bytes have been uploaded to the server. This block has no return value and takes five arguments: the session, the task, the number of bytes written since the last time the upload progress block was called, the total bytes written, and the total bytes expected to be written during the request, as initially determined by the length of the HTTP body. This block may be called multiple times, and will execute on the main thread.
 */
- (void)setTaskDidSendBodyDataBlock:(nullable void (^)(NSURLSession *session, NSURLSessionTask *task, int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend))block;

/**
 Sets a block to be executed as the last message related to a specific task, as handled by the `NSURLSessionTaskDelegate` method `URLSession:task:didCompleteWithError:`.

 @param block A block object to be executed when a session task is completed. The block has no return value, and takes three arguments: the session, the task, and any error that occurred in the process of executing the task.
 */
- (void)setTaskDidCompleteBlock:(nullable void (^)(NSURLSession *session, NSURLSessionTask *task, NSError * __nullable error))block;

///-------------------------------------------
/// @name Setting Data Task Delegate Callbacks
///-------------------------------------------

/**
 Sets a block to be executed when a data task has received a response, as handled by the `NSURLSessionDataDelegate` method `URLSession:dataTask:didReceiveResponse:completionHandler:`.

 @param block A block object to be executed when a data task has received a response. The block returns the disposition of the session response, and takes three arguments: the session, the data task, and the received response.
 */
- (void)setDataTaskDidReceiveResponseBlock:(nullable NSURLSessionResponseDisposition (^)(NSURLSession *session, NSURLSessionDataTask *dataTask, NSURLResponse *response))block;

/**
 Sets a block to be executed when a data task has become a download task, as handled by the `NSURLSessionDataDelegate` method `URLSession:dataTask:didBecomeDownloadTask:`.

 @param block A block object to be executed when a data task has become a download task. The block has no return value, and takes three arguments: the session, the data task, and the download task it has become.
 */
- (void)setDataTaskDidBecomeDownloadTaskBlock:(nullable void (^)(NSURLSession *session, NSURLSessionDataTask *dataTask, NSURLSessionDownloadTask *downloadTask))block;

/**
 Sets a block to be executed when a data task receives data, as handled by the `NSURLSessionDataDelegate` method `URLSession:dataTask:didReceiveData:`.

 @param block A block object to be called when an undetermined number of bytes have been downloaded from the server. This block has no return value and takes three arguments: the session, the data task, and the data received. This block may be called multiple times, and will execute on the session manager operation queue.
 */
- (void)setDataTaskDidReceiveDataBlock:(nullable void (^)(NSURLSession *session, NSURLSessionDataTask *dataTask, NSData *data))block;

/**
 Sets a block to be executed to determine the caching behavior of a data task, as handled by the `NSURLSessionDataDelegate` method `URLSession:dataTask:willCacheResponse:completionHandler:`.

 @param block A block object to be executed to determine the caching behavior of a data task. The block returns the response to cache, and takes three arguments: the session, the data task, and the proposed cached URL response.
 */
- (void)setDataTaskWillCacheResponseBlock:(nullable NSCachedURLResponse * (^)(NSURLSession *session, NSURLSessionDataTask *dataTask, NSCachedURLResponse *proposedResponse))block;

/**
 Sets a block to be executed once all messages enqueued for a session have been delivered, as handled by the `NSURLSessionDataDelegate` method `URLSessionDidFinishEventsForBackgroundURLSession:`.

 @param block A block object to be executed once all messages enqueued for a session have been delivered. The block has no return value and takes a single argument: the session.
 */
- (void)setDidFinishEventsForBackgroundURLSessionBlock:(nullable void (^)(NSURLSession *session))block;

///-----------------------------------------------
/// @name Setting Download Task Delegate Callbacks
///-----------------------------------------------

/**
 Sets a block to be executed when a download task has completed a download, as handled by the `NSURLSessionDownloadDelegate` method `URLSession:downloadTask:didFinishDownloadingToURL:`.

 @param block A block object to be executed when a download task has completed. The block returns the URL the download should be moved to, and takes three arguments: the session, the download task, and the temporary location of the downloaded file. If the file manager encounters an error while attempting to move the temporary file to the destination, an `AFURLSessionDownloadTaskDidFailToMoveFileNotification` will be posted, with the download task as its object, and the user info of the error.
 */
- (void)setDownloadTaskDidFinishDownloadingBlock:(nullable NSURL * (^)(NSURLSession *session, NSURLSessionDownloadTask *downloadTask, NSURL *location))block;

/**
 Sets a block to be executed periodically to track download progress, as handled by the `NSURLSessionDownloadDelegate` method `URLSession:downloadTask:didWriteData:totalBytesWritten:totalBytesWritten:totalBytesExpectedToWrite:`.

 @param block A block object to be called when an undetermined number of bytes have been downloaded from the server. This block has no return value and takes five arguments: the session, the download task, the number of bytes read since the last time the download progress block was called, the total bytes read, and the total bytes expected to be read during the request, as initially determined by the expected content size of the `NSHTTPURLResponse` object. This block may be called multiple times, and will execute on the session manager operation queue.
 */
- (void)setDownloadTaskDidWriteDataBlock:(nullable void (^)(NSURLSession *session, NSURLSessionDownloadTask *downloadTask, int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite))block;

/**
 Sets a block to be executed when a download task has been resumed, as handled by the `NSURLSessionDownloadDelegate` method `URLSession:downloadTask:didResumeAtOffset:expectedTotalBytes:`.

 @param block A block object to be executed when a download task has been resumed. The block has no return value and takes four arguments: the session, the download task, the file offset of the resumed download, and the total number of bytes expected to be downloaded.
 */
- (void)setDownloadTaskDidResumeBlock:(nullable void (^)(NSURLSession *session, NSURLSessionDownloadTask *downloadTask, int64_t fileOffset, int64_t expectedTotalBytes))block;

@end

#endif

///--------------------
/// @name Notifications
///--------------------

/**
 Posted when a task begins executing.

 @deprecated Use `AFNetworkingTaskDidResumeNotification` instead.
 */
FOUNDATION_EXPORT NSString * const AFNetworkingTaskDidStartNotification DEPRECATED_ATTRIBUTE;

/**
 Posted when a task resumes.
 */
FOUNDATION_EXPORT NSString * const AFNetworkingTaskDidResumeNotification;

/**
 Posted when a task finishes executing. Includes a userInfo dictionary with additional information about the task.

 @deprecated Use `AFNetworkingTaskDidCompleteNotification` instead.
 */
FOUNDATION_EXPORT NSString * const AFNetworkingTaskDidFinishNotification DEPRECATED_ATTRIBUTE;

/**
 Posted when a task finishes executing. Includes a userInfo dictionary with additional information about the task.
 */
FOUNDATION_EXPORT NSString * const AFNetworkingTaskDidCompleteNotification;

/**
 Posted when a task suspends its execution.
 */
FOUNDATION_EXPORT NSString * const AFNetworkingTaskDidSuspendNotification;

/**
 Posted when a session is invalidated.
 */
FOUNDATION_EXPORT NSString * const AFURLSessionDidInvalidateNotification;

/**
 Posted when a session download task encountered an error when moving the temporary download file to a specified destination.
 */
FOUNDATION_EXPORT NSString * const AFURLSessionDownloadTaskDidFailToMoveFileNotification;

/**
 The raw response data of the task. Included in the userInfo dictionary of the `AFNetworkingTaskDidFinishNotification` if response data exists for the task.

 @deprecated Use `AFNetworkingTaskDidCompleteResponseDataKey` instead.
 */
FOUNDATION_EXPORT NSString * const AFNetworkingTaskDidFinishResponseDataKey DEPRECATED_ATTRIBUTE;

/**
 The raw response data of the task. Included in the userInfo dictionary of the `AFNetworkingTaskDidFinishNotification` if response data exists for the task.
 */
FOUNDATION_EXPORT NSString * const AFNetworkingTaskDidCompleteResponseDataKey;

/**
 The serialized response object of the task. Included in the userInfo dictionary of the `AFNetworkingTaskDidFinishNotification` if the response was serialized.

 @deprecated Use `AFNetworkingTaskDidCompleteSerializedResponseKey` instead.
 */
FOUNDATION_EXPORT NSString * const AFNetworkingTaskDidFinishSerializedResponseKey DEPRECATED_ATTRIBUTE;

/**
 The serialized response object of the task. Included in the userInfo dictionary of the `AFNetworkingTaskDidFinishNotification` if the response was serialized.
 */
FOUNDATION_EXPORT NSString * const AFNetworkingTaskDidCompleteSerializedResponseKey;

/**
 The response serializer used to serialize the response. Included in the userInfo dictionary of the `AFNetworkingTaskDidFinishNotification` if the task has an associated response serializer.

 @deprecated Use `AFNetworkingTaskDidCompleteResponseSerializerKey` instead.
 */
FOUNDATION_EXPORT NSString * const AFNetworkingTaskDidFinishResponseSerializerKey DEPRECATED_ATTRIBUTE;

/**
 The response serializer used to serialize the response. Included in the userInfo dictionary of the `AFNetworkingTaskDidFinishNotification` if the task has an associated response serializer.
 */
FOUNDATION_EXPORT NSString * const AFNetworkingTaskDidCompleteResponseSerializerKey;

/**
 The file path associated with the download task. Included in the userInfo dictionary of the `AFNetworkingTaskDidFinishNotification` if an the response data has been stored directly to disk.

 @deprecated Use `AFNetworkingTaskDidCompleteAssetPathKey` instead.
 */
FOUNDATION_EXPORT NSString * const AFNetworkingTaskDidFinishAssetPathKey DEPRECATED_ATTRIBUTE;

/**
 The file path associated with the download task. Included in the userInfo dictionary of the `AFNetworkingTaskDidFinishNotification` if an the response data has been stored directly to disk.
 */
FOUNDATION_EXPORT NSString * const AFNetworkingTaskDidCompleteAssetPathKey;

/**
 Any error associated with the task, or the serialization of the response. Included in the userInfo dictionary of the `AFNetworkingTaskDidFinishNotification` if an error exists.

 @deprecated Use `AFNetworkingTaskDidCompleteErrorKey` instead.
 */
FOUNDATION_EXPORT NSString * const AFNetworkingTaskDidFinishErrorKey DEPRECATED_ATTRIBUTE;

/**
 Any error associated with the task, or the serialization of the response. Included in the userInfo dictionary of the `AFNetworkingTaskDidFinishNotification` if an error exists.
 */
FOUNDATION_EXPORT NSString * const AFNetworkingTaskDidCompleteErrorKey;

NS_ASSUME_NONNULL_END
