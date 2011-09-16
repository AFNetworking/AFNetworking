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

// Error codes for AFNetworkingErrorDomain correspond to codes in NSURLErrorDomain
extern NSString * const AFNetworkingErrorDomain;

extern NSString * const AFHTTPOperationDidStartNotification;
extern NSString * const AFHTTPOperationDidFinishNotification;

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

+ (id)operationWithRequest:(NSURLRequest *)urlRequest 
                completion:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSData *data, NSError *error))completion;

+ (id)operationWithRequest:(NSURLRequest *)urlRequest
               inputStream:(NSInputStream *)inputStream
              outputStream:(NSOutputStream *)outputStream
                completion:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error))completion;

- (void)setUploadProgressBlock:(void (^)(NSUInteger totalBytesWritten, NSUInteger totalBytesExpectedToWrite))block;
- (void)setDownloadProgressBlock:(void (^)(NSUInteger totalBytesRead, NSUInteger totalBytesExpectedToRead))block;

@end
