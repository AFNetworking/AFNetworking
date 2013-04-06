// AFImageRequestOperation.m
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

#import "AFImageRequestOperation.h"

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
@end

@implementation AFImageRequestOperation
@synthesize responseImage = _responseImage;
#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
@synthesize imageScale = _imageScale;
#endif

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

                    dispatch_async(operation.successCallbackQueue ?: dispatch_get_main_queue(), ^(void) {
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

                    dispatch_async(operation.successCallbackQueue ?: dispatch_get_main_queue(), ^(void) {
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

- (id)initWithRequest:(NSURLRequest *)urlRequest {
    self = [super initWithRequest:urlRequest];
    if (!self) {
        return nil;
    }

#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
    self.imageScale = [[UIScreen mainScreen] scale];
#endif

    return self;
}


#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
- (UIImage *)responseImage {
    if (!_responseImage && [self.responseData length] > 0 && [self isFinished]) {
        UIImage *image = [UIImage imageWithData:self.responseData];

        self.responseImage = [UIImage imageWithCGImage:[image CGImage] scale:self.imageScale orientation:image.imageOrientation];
    }

    return _responseImage;
}

- (void)setImageScale:(CGFloat)imageScale {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wfloat-equal"
    if (imageScale == _imageScale) {
        return;
    }
#pragma clang diagnostic pop

    _imageScale = imageScale;

    self.responseImage = nil;
}
#elif defined(__MAC_OS_X_VERSION_MIN_REQUIRED)
- (NSImage *)responseImage {
    if (!_responseImage && [self.responseData length] > 0 && [self isFinished]) {
        // Ensure that the image is set to it's correct pixel width and height
        NSBitmapImageRep *bitimage = [[NSBitmapImageRep alloc] initWithData:self.responseData];
        self.responseImage = [[NSImage alloc] initWithSize:NSMakeSize([bitimage pixelsWide], [bitimage pixelsHigh])];
        [self.responseImage addRepresentation:bitimage];
    }

    return _responseImage;
}
#endif

#pragma mark - AFHTTPRequestOperation

+ (NSSet *)acceptableContentTypes {
    return [NSSet setWithObjects:@"image/tiff", @"image/jpeg", @"image/gif", @"image/png", @"image/ico", @"image/x-icon", @"image/bmp", @"image/x-bmp", @"image/x-xbitmap", @"image/x-win-bitmap", nil];
}

+ (BOOL)canProcessRequest:(NSURLRequest *)request {
    static NSSet * _acceptablePathExtension = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _acceptablePathExtension = [[NSSet alloc] initWithObjects:@"tif", @"tiff", @"jpg", @"jpeg", @"gif", @"png", @"ico", @"bmp", @"cur", nil];
    });

    return [_acceptablePathExtension containsObject:[[request URL] pathExtension]] || [super canProcessRequest:request];
}

- (void)setCompletionBlockWithSuccess:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                              failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-retain-cycles"
    self.completionBlock = ^ {
        dispatch_async(image_request_operation_processing_queue(), ^(void) {
            if (self.error) {
                if (failure) {
                    dispatch_async(self.failureCallbackQueue ?: dispatch_get_main_queue(), ^{
                        failure(self, self.error);
                    });
                }
            } else {
                if (success) {
#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
                    UIImage *image = nil;
#elif defined(__MAC_OS_X_VERSION_MIN_REQUIRED)
                    NSImage *image = nil;
#endif

                    image = self.responseImage;

                    dispatch_async(self.successCallbackQueue ?: dispatch_get_main_queue(), ^{
                        success(self, image);
                    });
                }
            }
        });        
    };
#pragma clang diagnostic pop
}

@end
