// AFURLSessionManager.h
//
// Copyright (c) 2013-2015 AFNetworking (http://afnetworking.com)
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

#ifndef NS_DESIGNATED_INITIALIZER
#if __has_attribute(objc_designated_initializer)
#define NS_DESIGNATED_INITIALIZER __attribute__((objc_designated_initializer))
#else
#define NS_DESIGNATED_INITIALIZER
#endif
#endif
/**
 关于NSURLSession
 
 1. 提供的功能：
 通过URL将数据下载到内存
 通过URL将数据下载到文件系统
 将数据上传到指定URL
 在后台完成上述功能
 
 2. 创建NSSession时设置工作模式和网络设置
 工作模式分为：
 一般模式（default）：工作模式类似于原来的NSURLConnection，可以使用缓存的Cache，Cookie，鉴权。
 及时模式（ephemeral）：不使用缓存的Cache，Cookie，鉴权。
 后台模式（background）：在后台完成上传下载，创建Configuration对象的时候需要给一个NSString的ID用于追踪完成工作的Session是哪一个（后面会讲到）。
 
 3.创建一个NSURLSession，系统提供了两个创建方法：
 sessionWithConfiguration:
 

 3.1 sessionWithConfiguration:
    第一个粒度较低就是根据刚才创建的Configuration创建一个Session，系统默认创建一个新的OperationQueue处理Session的消息。
 回调: 如果是细粒度的Session调用，Session与Delegate会在指定的OperationQueue中进行交互，以咱们下载例子，交互过程的顺序图如下（假如不需要鉴权，即非HTTPS请求）：
 
 3.2 sessionWithConfiguration:delegate:delegateQueue:
    第二个粒度比较高，可以设定回调的delegate（注意这个回调delegate会被强引用），并且可以设定delegate在哪个OperationQueue回调，如果我们将其设置为[NSOperationQueue mainQueue]就能在主线程进行回调非常的方便。
 
 4. 创建一个NSURLRequest调用刚才的NSURLSession对象提供的Task函数，创建一个NSURLSessionTask。
 
 　　根据职能不同Task有三种子类：
    NSURLSessionUploadTask：上传用的Task，传完以后不会再下载返回结果；
    NSURLSessionDownloadTask：下载用的Task；
    NSURLSessionDataTask：可以上传内容，上传完成后再进行下载。
 
 　　得到的Task，调用resume开始工作。
 
 5. 停止session的进行
    当不再需要连接调用Session的invalidateAndCancel直接关闭，或者调用finishTasksAndInvalidate等待当前Task结束后关闭。这时Delegate会收到URLSession:didBecomeInvalidWithError:这个事件。Delegate收到这个事件之后会被解引用。

 6. session 在后台
    如果是一个BackgroundSession，在Task执行的时候，用户切到后台，Session会和ApplicationDelegate交互。当程序切到后台后，在BackgroundSession中的Task还会继续下载，这部分文档叙述比较少，现在分三个场景分析下Session和Application的关系：
    6.1 
    当加入了多个Task，程序没有切换到后台。
    这种情况Task会按照NSURLSessionConfiguration的设置正常下载，不会和ApplicationDelegate有交互。
 
    6.2
    当加入了多个Task，程序切到后台，所有Task都完成下载。
 　　在切到后台之后，Session的Delegate不会再收到，Task相关的消息，直到所有Task全都完成后，系统会调用ApplicationDelegate的application:handleEventsForBackgroundURLSession:completionHandler:回调，之后“汇报”下载工作，对于每一个后台下载的Task调用Session的Delegate中的URLSession:downloadTask:didFinishDownloadingToURL:（成功的话）和URLSession:task:didCompleteWithError:（成功或者失败都会调用）。
 
 　　之后调用Session的Delegate回调URLSessionDidFinishEventsForBackgroundURLSession:。
 
 
 warning
    注意：在ApplicationDelegate被唤醒后，会有个参数ComplietionHandler，这个参数是个Block，这个参数要在后面Session的Delegate中didFinish的时候调用一下，如下：
 
    6.3 当加入了多个Task，程序切到后台，下载完成了几个Task，然后用户又切换到前台。（程序没有退出）
 
 　　切到后台之后，Session的Delegate仍然收不到消息。在下载完成几个Task之后再切换到前台，系统会先汇报已经下载完成的Task的情况，然后继续下载没有下载完成的Task，后面的过程同第一种情况。
 
    当加入了多个Task，程序切到后台，几个Task已经完成，但还有Task还没有下载完的时候关掉强制退出程序，然后再进入程序的时候。（程序退出了）
 
 　　最后这个情况比较有意思，由于程序已经退出了，后面没有下完Session就不在了后面的Task肯定是失败了。但是已经下载成功的那些Task，新启动的程序也没有听“汇报”的机会了。经过实验发现，这个时候之前在NSURLSessionConfiguration设置的NSString类型的ID起作用了，当ID相同的时候，一旦生成Session对象并设置Delegate，马上可以收到上一次关闭程序之前没有汇报工作的Task的结束情况（成功或者失败）。但是当ID不相同，这些情况就收不到了，因此为了不让自己的消息被别的应用程序收到，或者收到别的应用程序的消息，起见ID还是和程序的Bundle名称绑定上比较好，至少保证唯一性。
 
 */
/**
 `AFURLSessionManager` creates and manages an `NSURLSession` object based on a specified `NSURLSessionConfiguration` object, which conforms to `<NSURLSessionTaskDelegate>`, `<NSURLSessionDataDelegate>`, `<NSURLSessionDownloadDelegate>`, and `<NSURLSessionDelegate>`.

 ## Subclassing Notes
 如果是做HTTP请求的话就可以使用AFHTTPSessionManager 这个类去搞定
 This is the base class for `AFHTTPSessionManager`, which adds functionality specific to making HTTP requests. If you are looking to extend `AFURLSessionManager` specifically for HTTP, consider subclassing `AFHTTPSessionManager` instead.

 ## NSURLSession & NSURLSessionTask Delegate Methods
 总共实现了一下的方法
 `AFURLSessionManager` implements the following delegate methods:

 1. session的代理
 ### `NSURLSessionDelegate`
 session无效（被取消）
 - `URLSession:didBecomeInvalidWithError:`
 session需要鉴权
 - `URLSession:didReceiveChallenge:completionHandler:`
 session进入后台
 - `URLSessionDidFinishEventsForBackgroundURLSession:`

 2. sessionTask代理
 ### `NSURLSessionTaskDelegate`
 
 - `URLSession:willPerformHTTPRedirection:newRequest:completionHandler:`
 - `URLSession:task:didReceiveChallenge:completionHandler:`
 - `URLSession:task:didSendBodyData:totalBytesSent:totalBytesExpectedToSend:`
 - `URLSession:task:didCompleteWithError:`
 3. 下载用的task的代理方法
 ### `NSURLSessionDataDelegate`
 接受到响应
 - `URLSession:dataTask:didReceiveResponse:completionHandler:`
 成为
 - `URLSession:dataTask:didBecomeDownloadTask:`
 收到数据
 - `URLSession:dataTask:didReceiveData:`
 缓存响应
 - `URLSession:dataTask:willCacheResponse:completionHandler:`
4. 下载
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

#if (defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000) || (defined(__MAC_OS_X_VERSION_MAX_ALLOWED) && __MAC_OS_X_VERSION_MAX_ALLOWED >= 1090)

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

///-------------------------------
/// @name Managing Callback Queues
///-------------------------------

/**
 The dispatch queue for `completionBlock`. If `NULL` (default), the main queue is used.
 */
#if OS_OBJECT_HAVE_OBJC_SUPPORT
@property (nonatomic, strong) dispatch_queue_t completionQueue;
#else
@property (nonatomic, assign) dispatch_queue_t completionQueue;
#endif

/**
 The dispatch group for `completionBlock`. If `NULL` (default), a private dispatch group is used.
 */
#if OS_OBJECT_HAVE_OBJC_SUPPORT
@property (nonatomic, strong) dispatch_group_t completionGroup;
#else
@property (nonatomic, assign) dispatch_group_t completionGroup;
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
- (instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration *)configuration NS_DESIGNATED_INITIALIZER;

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

 @see `attemptsToRecreateUploadTasksForBackgroundSessions`
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

 @warning If using a background `NSURLSessionConfiguration` on iOS, these blocks will be lost when the app is terminated. Background sessions may prefer to use `-setDownloadTaskDidFinishDownloadingBlock:` to specify the URL for saving the downloaded file, rather than the destination block of this method.
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

///---------------------------------
/// @name Getting Progress for Tasks
///---------------------------------

/**
 Returns the upload progress of the specified task.

 @param uploadTask The session upload task. Must not be `nil`.

 @return An `NSProgress` object reporting the upload progress of a task, or `nil` if the progress is unavailable.
 */
- (NSProgress *)uploadProgressForTask:(NSURLSessionUploadTask *)uploadTask;

/**
 Returns the download progress of the specified task.

 @param downloadTask The session download task. Must not be `nil`.

 @return An `NSProgress` object reporting the download progress of a task, or `nil` if the progress is unavailable.
 */
- (NSProgress *)downloadProgressForTask:(NSURLSessionDownloadTask *)downloadTask;

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
 Sets a block to be executed when a task requires a new request body stream to send to the remote server, as handled by the `NSURLSessionTaskDelegate` method `URLSession:task:needNewBodyStream:`.

 @param block A block object to be executed when a task requires a new request body stream.
 */
- (void)setTaskNeedNewBodyStreamBlock:(NSInputStream * (^)(NSURLSession *session, NSURLSessionTask *task))block;

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
