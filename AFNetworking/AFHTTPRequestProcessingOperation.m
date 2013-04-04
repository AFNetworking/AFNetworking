// AFHTTPRequestProcessingOperation.m
//
// Copyright (c) 2013 Paul Melnikow
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

#import "AFHTTPRequestProcessingOperation.h"

@implementation AFHTTPRequestProcessingOperation

- (NSError *)error {
    return self.processingError ?: [super error];
}

- (void)processResponse {
    [NSException raise:NSInvalidArgumentException format:@"Subclasses must override this method"];
}

+ (dispatch_queue_t)sharedProcessingQueue {
    static dispatch_queue_t queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("com.alamofire.networking.processing", DISPATCH_QUEUE_CONCURRENT);
    });
    
    return queue;
}

- (void)setCompletionBlockWithSuccess:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                              failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-retain-cycles"
    self.completionBlock = ^ {
        if ([self error]) {
            if (failure) {
                dispatch_async(self.failureCallbackQueue ?: dispatch_get_main_queue(), ^{
                    failure(self, [self error]);
                });
            }
        } else {
            dispatch_async(self.processingQueue ?: [AFHTTPRequestProcessingOperation sharedProcessingQueue], ^{
                // Deserialize the response
                // This should set self.responseObject and may also set self.processingError
                [self processResponse];                
                if (self.processingError) {
                    if (failure) {
                        dispatch_async(self.failureCallbackQueue ?: dispatch_get_main_queue(), ^{
                            failure(self, [self error]);
                        });
                    }
                } else {
                    if (success) {
                        dispatch_async(self.successCallbackQueue ?: dispatch_get_main_queue(), ^{
                            success(self, self.responseObject);
                        });
                    }
                }
            });
        }
    };
#pragma clang diagnostic pop
}

@end
