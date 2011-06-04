// AFImageRequest.m
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

#import "AFImageRequest.h"
#import "AFImageRequestOperation.h"

static NSOperationQueue *_operationQueue = nil;

@implementation AFImageRequest

+ (void)initialize {
	_operationQueue = [[NSOperationQueue alloc] init];
	[_operationQueue setMaxConcurrentOperationCount:6];
}

+ (void)requestImageWithURLString:(NSString *)urlString options:(AFImageRequestOptions)options block:(void (^)(UIImage *image))block {
	[self requestImageWithURLString:urlString size:CGSizeZero options:options block:block];
}

+ (void)requestImageWithURLString:(NSString *)urlString size:(CGSize)imageSize options:(AFImageRequestOptions)options block:(void (^)(UIImage *image))block {
	// Append a hash anchor to the image URL so that unique image options get cached separately
    NSString *cacheAnchor = [NSString stringWithFormat:@"%fx%f:%d", imageSize.width, imageSize.height, options];
	NSURL *url = [NSURL URLWithString:[urlString stringByAppendingString:[NSString stringWithFormat:@"#%@", cacheAnchor]]];
	if (!url) {
		if (block) {
			block(nil);
		}
		return;
	}
	
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLCacheStorageAllowed timeoutInterval:30.0];
	[request setHTTPShouldHandleCookies:NO];
	
	AFImageRequestOperationCallback *callback = [AFImageRequestOperationCallback callbackWithSuccess:block imageSize:imageSize options:options];
	AFImageRequestOperation *operation = [[[AFImageRequestOperation alloc] initWithRequest:request callback:callback] autorelease];
	
	NSCachedURLResponse *cachedResponse = [[[[NSURLCache sharedURLCache] cachedResponseForRequest:request] retain] autorelease];
	if (cachedResponse) {
		if (block) {
			block([UIImage imageWithData:[cachedResponse data]]);
			return;
		}
	}
	
	[_operationQueue addOperation:operation];
}

+ (void)cancelImageRequestOperationsForURLString:(NSString *)urlString {
    if (!urlString) {
        return;
    }
    
    for (AFImageRequestOperation *operation in [_operationQueue operations]) {
        NSString *requestURLString = [[[operation request] URL] absoluteString];
        NSRange anchorRange = [requestURLString rangeOfString:@"#" options:NSBackwardsSearch];
        if (anchorRange.location != NSNotFound && [[requestURLString substringToIndex:anchorRange.location] isEqualToString:urlString]) {
            if (!([operation isExecuting] || [operation isCancelled])) {
                [operation cancel];
            }
        }
    }
}

+ (void)cancelAllImageRequestOperations {
    for (AFImageRequestOperation *operation in [_operationQueue operations]) {
        if (!([operation isExecuting] || [operation isCancelled])) {
            [operation cancel];
        }
    }  
}

@end
