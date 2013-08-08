// AFImageRequestOperation.m
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

#import "AFImageRequestOperation.h"
#import "AFSerialization.h"

static dispatch_queue_t image_request_operation_processing_queue() {
    static dispatch_queue_t af_image_request_operation_processing_queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        af_image_request_operation_processing_queue = dispatch_queue_create("com.alamofire.networking.image-request.processing", DISPATCH_QUEUE_CONCURRENT);
    });

    return af_image_request_operation_processing_queue;
}

@interface AFImageRequestOperation ()
#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
@property (readwrite, nonatomic, strong) UIImage *responseImage;
#elif defined(__MAC_OS_X_VERSION_MIN_REQUIRED)
@property (readwrite, nonatomic, strong) NSImage *responseImage;
#endif
@property (readwrite, nonatomic, strong) NSError *error;
@property (readwrite, nonatomic, strong) NSRecursiveLock *lock;
@end

@implementation AFImageRequestOperation
@dynamic error;
@dynamic lock;

#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
+ (instancetype)imageRequestOperationWithRequest:(NSURLRequest *)urlRequest
										 success:(void (^)(UIImage *image))success
{
    return [self imageRequestOperationWithRequest:urlRequest imageProcessingBlock:nil success:^(NSURLRequest __unused *request, NSHTTPURLResponse __unused *response, UIImage *image) {
        if (success) {
            success(image);
        }
    } failure:nil];
}
#elif defined(__MAC_OS_X_VERSION_MIN_REQUIRED)
+ (instancetype)imageRequestOperationWithRequest:(NSURLRequest *)urlRequest
										 success:(void (^)(NSImage *image))success
{
    return [self imageRequestOperationWithRequest:urlRequest imageProcessingBlock:nil success:^(NSURLRequest __unused *request, NSHTTPURLResponse __unused *response, NSImage *image) {
        if (success) {
            success(image);
        }
    } failure:nil];
}
#endif

#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
+ (instancetype)imageRequestOperationWithRequest:(NSURLRequest *)urlRequest
							imageProcessingBlock:(UIImage *(^)(UIImage *))imageProcessingBlock
										 success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image))success
										 failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error))failure
{
    AFImageRequestOperation *requestOperation = [(AFImageRequestOperation *)[self alloc] initWithRequest:urlRequest];
    [requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            UIImage *image = responseObject;
            if (imageProcessingBlock) {
                dispatch_async(image_request_operation_processing_queue(), ^(void) {
                    UIImage *processedImage = imageProcessingBlock(image);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wgnu"
                    dispatch_async(operation.completionQueue ?: dispatch_get_main_queue(), ^(void) {
                        success(operation.request, operation.response, processedImage);
                    });
#pragma clang diagnostic pop
                });
            } else {
                success(operation.request, operation.response, image);
            }
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(operation.request, operation.response, error);
        }
    }];


    return requestOperation;
}
#elif defined(__MAC_OS_X_VERSION_MIN_REQUIRED)
+ (instancetype)imageRequestOperationWithRequest:(NSURLRequest *)urlRequest
							imageProcessingBlock:(NSImage *(^)(NSImage *))imageProcessingBlock
										 success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSImage *image))success
										 failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error))failure
{
    AFImageRequestOperation *requestOperation = [(AFImageRequestOperation *)[self alloc] initWithRequest:urlRequest];
    [requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            NSImage *image = responseObject;
            if (imageProcessingBlock) {
                dispatch_async(image_request_operation_processing_queue(), ^(void) {
                    NSImage *processedImage = imageProcessingBlock(image);

                    dispatch_async(operation.completionQueue ?: dispatch_get_main_queue(), ^(void) {
                        success(operation.request, operation.response, processedImage);
                    });
                });
            } else {
                success(operation.request, operation.response, image);
            }
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(operation.request, operation.response, error);
        }
    }];

    return requestOperation;
}
#endif

- (instancetype)initWithRequest:(NSURLRequest *)urlRequest {
    self = [super initWithRequest:urlRequest];
    if (!self) {
        return nil;
    }
    
    self.responseSerializer = [AFImageSerializer serializer];

    return self;
}

#pragma mark - AFImageRequestOperation

#if defined(__MAC_OS_X_VERSION_MIN_REQUIRED)
- (NSImage *)responseImage {
    [self.lock lock];
    if (!_responseImage && [self.responseData length] > 0 && [self isFinished]) {
        NSError *error = nil;
        self.responseImage = [self.responseSerializer responseObjectForResponse:self.response data:self.responseData error:&error];

        if (error) {
            self.error = error;
        }
    }
    [self.lock unlock];

    return _responseImage;
}
#elif defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
- (UIImage *)responseImage {
    [self.lock lock];
    if (!_responseImage && [self.responseData length] > 0 && [self isFinished]) {
        NSError *error = nil;
        self.responseImage = [self.responseSerializer responseObjectForResponse:self.response data:self.responseData error:&error];
        self.error = error;
    }
    [self.lock unlock];

    return _responseImage;
}

- (CGFloat)imageScale {
    return [(AFImageSerializer *)self.responseSerializer imageScale];
}

- (void)setImageScale:(CGFloat)imageScale {
    [self.lock lock];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wfloat-equal"
    if (imageScale != [(AFImageSerializer *)self.responseSerializer imageScale]) {
        [(AFImageSerializer *)self.responseSerializer setImageScale:imageScale];

        self.responseImage = nil;
    }
#pragma clang diagnostic pop
    [self.lock unlock];
}
#endif

#pragma mark - AFHTTPRequestOperation

- (void)setCompletionBlockWithSuccess:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                              failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    __weak __typeof(self)weakSelf = self;
    [super setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        #if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
        if ([responseObject isKindOfClass:[UIImage class]]) {
            [strongSelf setResponseImage:responseObject];
        }
        #elif defined(__MAC_OS_X_VERSION_MIN_REQUIRED)
        if ([responseObject isKindOfClass:[NSImage class]]) {
            [strongSelf setResponseImage:responseObject];
        }
        #endif

        if (success) {
            success(operation, responseObject);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        [strongSelf setError:error];

        if (failure) {
            failure(operation, error);
        }
    }];
}

@end
