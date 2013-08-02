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

/**
 
 */
@interface AFURLSessionManager : NSObject <NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate, NSURLSessionDownloadDelegate, NSCoding, NSCopying>

/**
 
 */
@property (readonly, nonatomic, strong) NSURLSession *session;

/**
 
 */
@property (readonly, nonatomic, strong) NSOperationQueue *operationQueue;

///----------------------------
/// @name Getting Session Tasks
///----------------------------

/**
 
 */
@property (readonly, nonatomic, strong) NSArray *tasks;

/**
 
 */
@property (readonly, nonatomic, strong) NSArray *dataTasks;

/**
 
 */
@property (readonly, nonatomic, strong) NSArray *uploadTasks;

/**
 
 */
@property (readonly, nonatomic, strong) NSArray *downloadTasks;

///---------------------
/// @name Initialization
///---------------------

/**
 
 */
- (instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration *)configuration;

/**
 
 */
- (void)invalidateSessionCancellingTasks:(BOOL)cancelPendingTasks;

///---------------------------------
/// @name Setting Progress Callbacks
///---------------------------------

/**
 Sets a callback to be called when an undetermined number of bytes have been uploaded to the server.

 @param block A block object to be called when an undetermined number of bytes have been uploaded to the server. This block has no return value and takes three arguments: the number of bytes written since the last time the upload progress block was called, the total bytes written, and the total bytes expected to be written during the request, as initially determined by the length of the HTTP body. This block may be called multiple times, and will execute on the main thread.
 */
- (void)setUploadProgressForTask:(NSURLSessionTask *)task
                      usingBlock:(void (^)(uint32_t bytesWritten, uint32_t totalBytesWritten, uint32_t totalBytesExpectedToWrite))block;

/**
 Sets a callback to be called when an undetermined number of bytes have been downloaded from the server.

 @param block A block object to be called when an undetermined number of bytes have been downloaded from the server. This block has no return value and takes three arguments: the number of bytes read since the last time the download progress block was called, the total bytes read, and the total bytes expected to be read during the request, as initially determined by the expected content size of the `NSHTTPURLResponse` object. This block may be called multiple times, and will execute on the main thread.
 */
- (void)setDownloadProgressForTask:(NSURLSessionTask *)task
                        usingBlock:(void (^)(uint32_t bytesRead, uint32_t totalBytesRead, uint32_t totalBytesExpectedToRead))block;

///-----------------------------------------
/// @name Setting Session Delegate Callbacks
///-----------------------------------------

/**
 
 */
- (void)setSessionDidBecomeInvalidBlock:(void (^)(NSURLSession *session, NSError *error))block;

/**
 
 */
- (void)setSessionDidReceiveAuthenticationChallengeBlock:(NSURLSessionAuthChallengeDisposition (^)(NSURLSession *session, NSURLAuthenticationChallenge *challenge, NSURLCredential * __autoreleasing *credential))block;

///--------------------------------------
/// @name Setting Task Delegate Callbacks
///--------------------------------------

/**
 
 */
- (void)setTaskWillPerformHTTPRedirectionBlock:(NSURLRequest * (^)(NSURLSession *session, NSURLSessionTask *task, NSURLResponse *response, NSURLRequest *request))block;

/**
 
 */
- (void)setTaskDidReceiveAuthenticationChallengeBlock:(NSURLSessionAuthChallengeDisposition (^)(NSURLSession *session, NSURLSessionTask *task, NSURLAuthenticationChallenge *challenge, NSURLCredential * __autoreleasing *credential))block;

/**
 
 */
- (void)setTaskDidSendBodyDataBlock:(void (^)(NSURLSession *session, NSURLSessionTask *task, int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend))block;

/**
 
 */
- (void)setTaskDidCompleteBlock:(void (^)(NSURLSession *session, NSURLSessionTask *task, NSError *error))block;

///-------------------------------------------
/// @name Setting Data Task Delegate Callbacks
///-------------------------------------------

/**
 
 */
- (void)setDataTaskDidReceiveResponseBlock:(NSURLSessionResponseDisposition (^)(NSURLSession *session, NSURLSessionDataTask *dataTask, NSURLResponse *response))block;

/**
 
 */
- (void)setDataTaskDidBecomeDownloadTaskBlock:(void (^)(NSURLSession *session, NSURLSessionDataTask *dataTask, NSURLSessionDownloadTask *downloadTask))block;

/**
 
 */
- (void)setDataTaskDidReceiveDataBlock:(void (^)(NSURLSession *session, NSURLSessionDataTask *dataTask, NSData *data))block;

/**
 
 */
- (void)setDataTaskWillCacheResponseBlock:(NSCachedURLResponse * (^)(NSURLSession *session, NSURLSessionDataTask *dataTask, NSCachedURLResponse *proposedResponse))block;

///-----------------------------------------------
/// @name Setting Download Task Delegate Callbacks
///-----------------------------------------------

/**
 
 */
- (void)setDownloadTaskDidFinishDownloadingBlock:(void (^)(NSURLSession *session, NSURLSessionDownloadTask *dataTask, NSURL *location))block;

/**
 
 */
- (void)setDownloadTaskDidWriteDataBlock:(void (^)(NSURLSession *session, NSURLSessionDownloadTask *dataTask, int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite))block;

/**
 
 */
- (void)setDownloadTaskDidResumeBlock:(void (^)(NSURLSession *session, NSURLSessionDownloadTask *dataTask, int64_t fileOffset, int64_t expectedTotalBytes))block;

@end

///--------------------
/// @name Notifications
///--------------------

/**
 Posted when a task begins executing.
 */
extern NSString * const AFNetworkingTaskDidStartNotification; // TODO Unclear how, or if possible, to determine when tasks start, with no corresponding delegate methods

/**
 Posted when a task finishes.
 */
extern NSString * const AFNetworkingTaskDidFinishNotification;

/**

 */
extern NSString * const AFURLSessionDidInvalidateNotification;
