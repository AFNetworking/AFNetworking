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
#import "QHTTPOperation.h"
#import "AFCallback.h"

extern NSString * const AFHTTPOperationDidStartNotification;
extern NSString * const AFHTTPOperationDidSucceedNotification;
extern NSString * const AFHTTPOperationDidFailNotification;

extern NSString * const AFHTTPOperationParsedDataErrorKey;

@class AFHTTPOperationCallback;

@interface AFHTTPOperation : QHTTPOperation {
@private
	AFHTTPOperationCallback *_callback;
}

@property (nonatomic, retain) AFHTTPOperationCallback *callback;
@property (readonly) NSString *responseString;

+ (id)operationWithRequest:(NSURLRequest *)urlRequest callback:(AFHTTPOperationCallback *)callback;
- (id)initWithRequest:(NSURLRequest *)urlRequest callback:(AFHTTPOperationCallback *)callback;

@end

#pragma mark - AFHTTPOperationCallback

typedef void (^AFHTTPOperationSuccessBlock)(NSURLRequest *request, NSHTTPURLResponse *response, NSDictionary *data);
typedef void (^AFHTTPOperationErrorBlock)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error);

@protocol AFHTTPOperationCallback <NSObject>
@optional
+ (id)callbackWithSuccess:(AFHTTPOperationSuccessBlock)success;
+ (id)callbackWithSuccess:(AFHTTPOperationSuccessBlock)success error:(AFHTTPOperationErrorBlock)error;
@end

@interface AFHTTPOperationCallback : AFCallback <AFHTTPOperationCallback>
@property (readwrite, nonatomic, copy) AFHTTPOperationSuccessBlock successBlock;
@property (readwrite, nonatomic, copy) AFHTTPOperationErrorBlock errorBlock;
@end
