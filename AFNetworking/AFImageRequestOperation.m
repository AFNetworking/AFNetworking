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
#import "AFImageCache.h"

static dispatch_queue_t af_image_request_operation_processing_queue;
static dispatch_queue_t image_request_operation_processing_queue() {
    if (af_image_request_operation_processing_queue == NULL) {
        af_image_request_operation_processing_queue = dispatch_queue_create("com.alamofire.networking.image-request.processing", 0);
    }
    
    return af_image_request_operation_processing_queue;
}

@interface AFImageRequestOperation ()
#if TARGET_OS_IPHONE
@property (readwrite, nonatomic, retain) UIImage *responseImage;
#else
@property (readwrite, nonatomic, retain) NSImage *responseImage;
#endif
+ (NSSet *)defaultAcceptableContentTypes;
+ (NSSet *)defaultAcceptablePathExtensions;
@end

@implementation AFImageRequestOperation
@synthesize responseImage = _responseImage;
#if TARGET_OS_IPHONE
@synthesize imageScale = _imageScale;
#endif

#if TARGET_OS_IPHONE
+ (AFImageRequestOperation *)imageRequestOperationWithRequest:(NSURLRequest *)urlRequest                
                                                      success:(void (^)(UIImage *image))success
{
    return [self imageRequestOperationWithRequest:urlRequest imageProcessingBlock:nil cacheName:nil success:^(NSURLRequest __unused *request, NSHTTPURLResponse __unused *response, UIImage *image) {
        if (success) {
            success(image);
        }
    } failure:nil];
}
#else
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

#if TARGET_OS_IPHONE
+ (AFImageRequestOperation *)imageRequestOperationWithRequest:(NSURLRequest *)urlRequest
                                         imageProcessingBlock:(UIImage *(^)(UIImage *))imageProcessingBlock
                                                    cacheName:(NSString *)cacheNameOrNil
                                                      success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image))success
                                                      failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error))failure
#else
+ (AFImageRequestOperation *)imageRequestOperationWithRequest:(NSURLRequest *)urlRequest
                                         imageProcessingBlock:(NSImage *(^)(NSImage *))imageProcessingBlock
                                                    cacheName:(NSString *)cacheNameOrNil
                                                      success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSImage *image))success
                                                      failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error))failure
#endif
{
    AFImageRequestOperation *requestOperation = [[[AFImageRequestOperation alloc] initWithRequest:urlRequest] autorelease];
    [requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
#if TARGET_OS_IPHONE
            UIImage *image = responseObject;
#else
            NSImage *image = responseObject;
#endif
            
            if (imageProcessingBlock) {
                image = imageProcessingBlock(image);
            }
            
            success(operation.request, operation.response, image);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(operation.request, operation.response, error);
        }
    }];
    
    
    return requestOperation;
}

+ (NSSet *)defaultAcceptableContentTypes {
    return [NSSet setWithObjects:@"image/tiff", @"image/jpeg", @"image/gif", @"image/png", @"image/ico", @"image/x-icon" @"image/bmp", @"image/x-bmp", @"image/x-xbitmap", @"image/x-win-bitmap", nil];
}

+ (NSSet *)defaultAcceptablePathExtensions {
    return [NSSet setWithObjects:@"tif", @"tiff", @"jpg", @"jpeg", @"gif", @"png", @"ico", @"bmp", @"cur", nil];
}

- (id)initWithRequest:(NSURLRequest *)urlRequest {
    self = [super initWithRequest:urlRequest];
    if (!self) {
        return nil;
    }
    
    self.acceptableContentTypes = [[self class] defaultAcceptableContentTypes];
    
#if TARGET_OS_IPHONE
    self.imageScale = [[UIScreen mainScreen] scale];
#endif
    
    return self;
}

- (void)dealloc {
    [_responseImage release];
    [super dealloc];
}

#if TARGET_OS_IPHONE
- (UIImage *)responseImage {
    if (!_responseImage && [self isFinished]) {
        UIImage *image = [UIImage imageWithData:self.responseData];
        self.responseImage = [UIImage imageWithCGImage:[image CGImage] scale:self.imageScale orientation:image.imageOrientation];
    }
    return _responseImage;    
}
#else
- (NSImage *)responseImage {
    if (!_responseImage && [self isFinished]) {        
        // Ensure that the image is set to it's correct pixel width and height
        NSBitmapImageRep *bitimage = [[NSBitmapImageRep alloc] initWithData:self.responseData];
        self.responseImage = [[[NSImage alloc] initWithSize:NSMakeSize([bitimage pixelsWide], [bitimage pixelsHigh])] autorelease];
        [self.responseImage addRepresentation:bitimage];
        [bitimage release];
    }
    return _responseImage;
}
#endif

#if TARGET_OS_IPHONE
- (void)setImageScale:(CGFloat)imageScale {
    if (imageScale == _imageScale) {
        return;
    }
    
    [self willChangeValueForKey:@"imageScale"];
    _imageScale = imageScale;
    [self didChangeValueForKey:@"imageScale"];
    
    self.responseImage = nil;
}
#endif

#pragma mark - AFHTTPClientOperation

+ (BOOL)canProcessRequest:(NSURLRequest *)request {
    return [[self defaultAcceptableContentTypes] containsObject:[request valueForHTTPHeaderField:@"Accept"]] || [[self defaultAcceptablePathExtensions] containsObject:[[request URL] pathExtension]];
}

+ (AFHTTPRequestOperation *)HTTPRequestOperationWithRequest:(NSURLRequest *)urlRequest
                                                    success:(void (^)(id object))success 
                                                    failure:(void (^)(NSHTTPURLResponse *response, NSError *error))failure
{
#if TARGET_OS_IPHONE
    return [self imageRequestOperationWithRequest:urlRequest imageProcessingBlock:nil cacheName:nil success:^(NSURLRequest __unused *request, NSHTTPURLResponse __unused *response, UIImage *image) {
#else
    return [self imageRequestOperationWithRequest:urlRequest imageProcessingBlock:nil cacheName:nil success:^(NSURLRequest __unused *request, NSHTTPURLResponse __unused *response, NSImage *image) {
#endif
        success(image);
    } failure:^(NSURLRequest __unused *request, NSHTTPURLResponse *response, NSError *error) {
        failure(response, error);
    }];
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
                    dispatch_async(dispatch_get_main_queue(), ^(void) {
                        failure(self, self.error);
                    });
                }
            } else {                
                if (success) {
                    dispatch_async(dispatch_get_main_queue(), ^(void) {
                        success(self, self.responseImage);
                    });
                }
            }
        });        
    };  
}

@end
