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

static dispatch_queue_t af_image_request_operation_processing_queue;
static dispatch_queue_t image_request_operation_processing_queue() {
    if (af_image_request_operation_processing_queue == NULL) {
        af_image_request_operation_processing_queue = dispatch_queue_create("com.alamofire.networking.image-request.processing", 0);
    }
    
    return af_image_request_operation_processing_queue;
}

@interface AFImageRequestOperation ()
#if __IPHONE_OS_VERSION_MIN_REQUIRED
@property (readwrite, nonatomic, retain) UIImage *responseImage;
#elif __MAC_OS_X_VERSION_MIN_REQUIRED 
@property (readwrite, nonatomic, retain) NSImage *responseImage;
#endif
@end

@implementation AFImageRequestOperation
@synthesize responseImage = _responseImage;
#if __IPHONE_OS_VERSION_MIN_REQUIRED
@synthesize imageScale = _imageScale;
#endif

#if __IPHONE_OS_VERSION_MIN_REQUIRED
+ (AFImageRequestOperation *)imageRequestOperationWithRequest:(NSURLRequest *)urlRequest                
                                                      success:(void (^)(UIImage *image))success
{
    return [self imageRequestOperationWithRequest:urlRequest imageProcessingBlock:nil cacheName:nil success:^(NSURLRequest __unused *request, NSHTTPURLResponse __unused *response, UIImage *image) {
        if (success) {
            success(image);
        }
    } failure:nil];
}
#elif __MAC_OS_X_VERSION_MIN_REQUIRED 
+ (AFImageRequestOperation *)imageRequestOperationWithRequest:(NSURLRequest *)urlRequest                
                                                      success:(void (^)(NSImage *image))success
{
    return [self imageRequestOperationWithRequest:urlRequest imageProcessingBlock:nil cacheName:nil success:^(NSURLRequest __unused *request, NSHTTPURLResponse __unused *response, NSImage *image) {
        if (success) {
            success(image);
        }
    } failure:nil];
}
#endif


#if __IPHONE_OS_VERSION_MIN_REQUIRED
+ (AFImageRequestOperation *)imageRequestOperationWithRequest:(NSURLRequest *)urlRequest
                                         imageProcessingBlock:(UIImage *(^)(UIImage *))imageProcessingBlock
                                                    cacheName:(NSString *)cacheNameOrNil
                                                      success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image))success
                                                      failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error))failure
{
    AFImageRequestOperation *requestOperation = [[[AFImageRequestOperation alloc] initWithRequest:urlRequest] autorelease];
    [requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            UIImage *image = responseObject;
            if (imageProcessingBlock) {
                dispatch_async(image_request_operation_processing_queue(), ^(void) {
                    UIImage *processedImage = imageProcessingBlock(image);

                    dispatch_async(dispatch_get_main_queue(), ^(void) {
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
#elif __MAC_OS_X_VERSION_MIN_REQUIRED 
+ (AFImageRequestOperation *)imageRequestOperationWithRequest:(NSURLRequest *)urlRequest
                                         imageProcessingBlock:(NSImage *(^)(NSImage *))imageProcessingBlock
                                                    cacheName:(NSString *)cacheNameOrNil
                                                      success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSImage *image))success
                                                      failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error))failure
{
    AFImageRequestOperation *requestOperation = [[[AFImageRequestOperation alloc] initWithRequest:urlRequest] autorelease];
    [requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            NSImage *image = responseObject;
            if (imageProcessingBlock) {
                dispatch_async(image_request_operation_processing_queue(), ^(void) {
                    NSImage *processedImage = imageProcessingBlock(image);

                    dispatch_async(dispatch_get_main_queue(), ^(void) {
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
        
#if __IPHONE_OS_VERSION_MIN_REQUIRED
    self.imageScale = [[UIScreen mainScreen] scale];
#endif
    
    return self;
}

- (void)dealloc {
    [_responseImage release];
    [super dealloc];
}

#if __IPHONE_OS_VERSION_MIN_REQUIRED
- (UIImage *)responseImage {
    if (!_responseImage && [self.responseData length] > 0 && [self isFinished]) {
        UIImage *image = [UIImage imageWithData:self.responseData];
        
        self.responseImage = [UIImage imageWithCGImage:[image CGImage] scale:self.imageScale orientation:image.imageOrientation];
    }
    
    return _responseImage;
}

- (void)setImageScale:(CGFloat)imageScale {
    if (imageScale == _imageScale) {
        return;
    }
    
    _imageScale = imageScale;
    
    self.responseImage = nil;
}
#elif __MAC_OS_X_VERSION_MIN_REQUIRED 
- (NSImage *)responseImage {
    if (!_responseImage && [self.responseData length] > 0 && [self isFinished]) {
        // Ensure that the image is set to it's correct pixel width and height
        NSBitmapImageRep *bitimage = [[NSBitmapImageRep alloc] initWithData:self.responseData];
        self.responseImage = [[[NSImage alloc] initWithSize:NSMakeSize([bitimage pixelsWide], [bitimage pixelsHigh])] autorelease];
        [self.responseImage addRepresentation:bitimage];
        [bitimage release];
    }
    
    return _responseImage;
}
#endif

#pragma mark - AFHTTPClientOperation

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
    self.completionBlock = ^ {
        if ([self isCancelled]) {
            return;
        }
        
        dispatch_async(image_request_operation_processing_queue(), ^(void) {
            if (self.error) {
                if (failure) {
                    dispatch_async(self.failureCallbackQueue ? self.failureCallbackQueue : dispatch_get_main_queue(), ^{
                        failure(self, self.error);
                    });
                }
            } else {            
                if (success) {
#if __IPHONE_OS_VERSION_MIN_REQUIRED
                    UIImage *image = nil;
#elif __MAC_OS_X_VERSION_MIN_REQUIRED
                    NSImage *image = nil;
#endif

                    image = self.responseImage;

                    dispatch_async(self.successCallbackQueue ? self.successCallbackQueue : dispatch_get_main_queue(), ^{
                        success(self, image);
                    });
                }
            }
        });        
    };  
}

@end
