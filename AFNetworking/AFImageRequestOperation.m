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
        af_image_request_operation_processing_queue = dispatch_queue_create("com.alamofire.image-request.processing", 0);
    }
    
    return af_image_request_operation_processing_queue;
}

@implementation AFImageRequestOperation

+ (AFImageRequestOperation *)operationWithRequest:(NSURLRequest *)urlRequest                
                                          success:(void (^)(UIImage *image))success
{
    return [self operationWithRequest:urlRequest imageProcessingBlock:nil cacheName:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
        if (success) {
            success(image);
        }
    } failure:nil];
}

+ (AFImageRequestOperation *)operationWithRequest:(NSURLRequest *)urlRequest
                             imageProcessingBlock:(UIImage *(^)(UIImage *))imageProcessingBlock
                                        cacheName:(NSString *)cacheNameOrNil
                                          success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image))success
                                          failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error))failure
{
    return (AFImageRequestOperation *)[self operationWithRequest:urlRequest completion:^(NSURLRequest *request, NSHTTPURLResponse *response, NSData *data, NSError *error) {
        dispatch_async(image_request_operation_processing_queue(), ^(void) {
            if (error) {
                if (failure) {
                    dispatch_async(dispatch_get_main_queue(), ^(void) {
                        failure(request, response, error);
                    });
                }
            } else {
                UIImage *image = nil;    
                if ([[UIScreen mainScreen] scale] == 2.0) {
                    CGImageRef imageRef = [[UIImage imageWithData:data] CGImage];
                    image = [UIImage imageWithCGImage:imageRef scale:2.0 orientation:UIImageOrientationUp];
                } else {
                    image = [UIImage imageWithData:data]; 
                }
                
                if (imageProcessingBlock) {
                    image = imageProcessingBlock(image);
                }
                
                dispatch_async(dispatch_get_main_queue(), ^(void) {
                    if (success) {
                        success(request, response, image);
                    }
                });
                
                [[AFImageCache sharedImageCache] cacheImage:image forRequest:request cacheName:cacheNameOrNil];
            }
        });
    }];
}

@end
