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
/// @name Session Delegate Callbacks
///---------------------------------

/**
 
 */
- (void)setSessionDidBecomeInvalidBlock:(void (^)(NSURLSession *session, NSError *error))block;

/**
 
 */
- (void)setSessionDidReceiveAuthenticationChallengeBlock:(NSURLSessionResponseDisposition (^)(NSURLSession *session, NSURLAuthenticationChallenge *challenge, NSURLCredential * __autoreleasing *credential))block;

///------------------------------
/// @name Task Delegate Callbacks
///------------------------------

/**
 
 */
- (void)setTaskWillPerformHTTPRedirectionBlock:(NSURLRequest * (^)(NSURLSession *session, NSURLSessionTask *task, NSURLResponse *response, NSURLRequest *request))block;

/**
 
 */
- (void)setTaskDidReceiveAuthenticationChallengeBlock:(NSURLSessionResponseDisposition (^)(NSURLSession *session, NSURLSessionTask *task, NSURLAuthenticationChallenge *challenge, NSURLCredential * __autoreleasing *credential))block;

/**
 
 */
- (void)setTaskDidSendBodyDataBlock:(void (^)(NSURLSession *session, NSURLSessionTask *task, int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend))block;

/**
 
 */
- (void)setTaskDidCompleteBlock:(void (^)(NSURLSession *session, NSURLSessionTask *task, NSError *error))block;

///-----------------------------------
/// @name Data Task Delegate Callbacks
///-----------------------------------

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

///---------------------------------------
/// @name Download Task Delegate Callbacks
///---------------------------------------

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

///----------------
/// @name Constants
///----------------

/**
 
 */
extern NSString * const AFURLSessionDidInvalidateNotification;
