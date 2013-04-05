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

@implementation AFImageRequestOperation
#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
@synthesize imageScale = _imageScale;
#endif

+ (instancetype)imageRequestOperationWithRequest:(NSURLRequest *)urlRequest
										 success:(void (^)(AFImageClassName *image))success
{
    return [self imageRequestOperationWithRequest:urlRequest filterBlock:nil success:^(NSURLRequest __unused *request, NSHTTPURLResponse __unused *response, AFImageClassName *image) {
        if (success) {
            success(image);
        }
    } failure:nil];
}

+ (instancetype)imageRequestOperationWithRequest:(NSURLRequest *)urlRequest
                                     filterBlock:(AFImageFilterBlock)filterBlock
										 success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, AFImageClassName *image))success
										 failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error))failure
{
    AFImageRequestOperation *requestOperation = [[AFImageRequestOperation alloc] initWithRequest:urlRequest];
    requestOperation.filterBlock = filterBlock;
    [requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            success(operation.request, operation.response, responseObject);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(operation.request, operation.response, error);
        }
    }];

    return requestOperation;
}

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

-(void)processResponse {
    if (!self.responseObject && [self.responseData length] > 0 && [self isFinished]) {
#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
        UIImage *image = [UIImage imageWithData:self.responseData];
        self.responseObject = [UIImage imageWithCGImage:[image CGImage] scale:self.imageScale orientation:image.imageOrientation];
#elif defined(__IPHONE_OS_X_VERSION_MIN_REQUIRED)
        // Ensure that the image is set to it's correct pixel width and height
        NSBitmapImageRep *bitimage = [[NSBitmapImageRep alloc] initWithData:self.responseData];
        self.responseObject = [[NSImage alloc] initWithSize:NSMakeSize([bitimage pixelsWide], [bitimage pixelsHigh])];
        [self.responseObject addRepresentation:bitimage];
#endif
        if (self.filterBlock) {
            self.responseObject = self.filterBlock(self.responseObject);
        }
    }
}

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

@end
