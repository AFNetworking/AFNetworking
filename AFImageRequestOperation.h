// AFImageRequestOperation.h
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
#import <UIKit/UIKit.h>
#import "QHTTPOperation.h"
#import "AFCallback.h"

typedef enum {
    AFImageRequestResize                = 1 << 1,
    AFImageRequestRoundCorners			= 1 << 2,
    AFImageCacheProcessedImage          = 1 << 0xA,
	AFImageRequestDefaultOptions		= AFImageRequestResize,
} AFImageRequestOptions;

@class AFImageRequestOperationCallback;

@interface AFImageRequestOperation : QHTTPOperation {
@private
	AFImageRequestOperationCallback *_callback;
}

@property (nonatomic, retain) AFImageRequestOperationCallback *callback;

+ (id)operationWithRequest:(NSURLRequest *)urlRequest callback:(AFImageRequestOperationCallback *)callback;
- (id)initWithRequest:(NSURLRequest *)urlRequest callback:(AFImageRequestOperationCallback *)callback;

@end

#pragma mark - AFHTTPOperationCallback

typedef void (^AFImageRequestOperationSuccessBlock)(UIImage *image);
typedef void (^AFImageRequestOperationErrorBlock)(NSError *error);

@protocol AFImageRequestOperationCallback <NSObject>
@optional
+ (id)callbackWithSuccess:(AFImageRequestOperationSuccessBlock)success;
+ (id)callbackWithSuccess:(AFImageRequestOperationSuccessBlock)success error:(AFImageRequestOperationErrorBlock)error;
@end

@interface AFImageRequestOperationCallback : AFCallback <AFImageRequestOperationCallback> {
@private
    CGSize _imageSize;
    AFImageRequestOptions _options;
}

@property (readwrite, nonatomic, assign) CGSize imageSize;
@property (readwrite, nonatomic, assign) AFImageRequestOptions options;

@property (readwrite, nonatomic, copy) AFImageRequestOperationSuccessBlock successBlock;
@property (readwrite, nonatomic, copy) AFImageRequestOperationErrorBlock errorBlock;

+ (id)callbackWithSuccess:(AFImageRequestOperationSuccessBlock)success imageSize:(CGSize)imageSize options:(AFImageRequestOptions)options;
@end
