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

#import "UIImage+AFNetworking.h"

const CGFloat kAFImageRequestJPEGQuality = 0.8;
const NSUInteger kAFImageRequestMaximumResponseSize = 8 * 1024 * 1024;
static inline CGSize kAFImageRequestRoundedCornerRadii(CGSize imageSize) {
    CGFloat dimension = fmaxf(imageSize.width, imageSize.height) * 0.1;
    return CGSizeMake(dimension, dimension);
}

@implementation AFImageRequestOperation
@synthesize callback = _callback;

+ (id)operationWithRequest:(NSURLRequest *)urlRequest callback:(AFImageRequestOperationCallback *)callback {
    return [[[self alloc] initWithRequest:urlRequest callback:callback] autorelease];
}

- (id)initWithRequest:(NSURLRequest *)urlRequest callback:(AFImageRequestOperationCallback *)callback {
	self = [super initWithRequest:urlRequest];
	if (!self) {
		return nil;
	}
	
	self.maximumResponseSize = kAFImageRequestMaximumResponseSize;
	
	NSMutableIndexSet *statusCodes = [NSMutableIndexSet indexSetWithIndex:0];
	[statusCodes addIndexesInRange:NSMakeRange(200, 100)];
	self.acceptableStatusCodes = statusCodes;
	self.acceptableContentTypes = [NSSet setWithObjects:@"image/png", @"image/jpeg", @"image/pjpeg", @"image/gif", @"application/x-0", nil];
	self.callback = callback;
	
	if (self.callback) {
		self.runLoopModes = [NSSet setWithObjects:NSRunLoopCommonModes, NSDefaultRunLoopMode, nil];
	}
	
	return self;
}

#pragma mark - QHTTPRequestOperation

// QHTTPRequestOperation requires this to return an NSHTTPURLResponse, but in certain circumstances, 
//  this method would otherwise return an instance of its superclass, NSURLResponse
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	if([response isKindOfClass:[NSHTTPURLResponse class]]) {
		[super connection:connection didReceiveResponse:response];
	} else {
		[super connection:connection didReceiveResponse:[[[NSHTTPURLResponse alloc] initWithURL:[response URL] MIMEType:[response MIMEType] expectedContentLength:[response expectedContentLength] textEncodingName:[response textEncodingName]] autorelease]];
	}
}

#pragma mark - QRunLoopOperation

- (void)finishWithError:(NSError *)error {
	[super finishWithError:error];
    
    if (error) {
        if (self.callback.errorBlock) {
			self.callback.errorBlock(error);
		}

        return;
    }
	
	UIImage *image = nil;    
	if ([[UIScreen mainScreen] scale] == 2.0) {
		CGImageRef imageRef = [UIImage imageWithData:self.responseBody].CGImage;
		image = [UIImage imageWithCGImage:imageRef scale:2.0 orientation:UIImageOrientationUp];
	} else {
		image = [UIImage imageWithData:self.responseBody]; 
	}
	    
    BOOL didProcessingOnImage = NO;
    
    if ((self.callback.options & AFImageRequestResize) && !(CGSizeEqualToSize(image.size, self.callback.imageSize) || CGSizeEqualToSize(self.callback.imageSize, CGSizeZero))) {
        image = [UIImage imageByScalingAndCroppingImage:image size:self.callback.imageSize];
        didProcessingOnImage = YES;
    }
	if ((self.callback.options & AFImageRequestRoundCorners)) {
        image = [UIImage imageByRoundingCornersOfImage:image corners:UIRectCornerAllCorners cornerRadii:kAFImageRequestRoundedCornerRadii(image.size)];
        didProcessingOnImage = YES;
    }
    
	
    if (self.callback.successBlock) {
        self.callback.successBlock(image);
    }
    
    if ((self.callback.options & AFImageCacheProcessedImage) && didProcessingOnImage) {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];			
        NSData *processedImageData = nil;
        if ((self.callback.options & AFImageRequestRoundCorners) || [[[[self.lastRequest URL] path] pathExtension] isEqualToString:@"png"]) {
            processedImageData = UIImagePNGRepresentation(image);
        } else {
            processedImageData = UIImageJPEGRepresentation(image, kAFImageRequestJPEGQuality);
        }
        NSURLResponse *response = [[[NSURLResponse alloc] initWithURL:[self.lastRequest URL] MIMEType:[self.lastResponse MIMEType] expectedContentLength:[processedImageData length] textEncodingName:[self.lastResponse textEncodingName]] autorelease];
        NSCachedURLResponse *cachedResponse = [[[NSCachedURLResponse alloc] initWithResponse:response data:processedImageData] autorelease];
        [[NSURLCache sharedURLCache] storeCachedResponse:cachedResponse forRequest:self.lastRequest];
        [pool drain];
    }
}

- (void) dealloc {
	[_callback release];

	[super dealloc];
}

@end

#pragma mark - AFHTTPOperationCallback

@implementation AFImageRequestOperationCallback : AFCallback
@synthesize options = _options;
@synthesize imageSize = _imageSize;
@dynamic successBlock, errorBlock;

+ (id)callbackWithSuccess:(AFImageRequestOperationSuccessBlock)success imageSize:(CGSize)imageSize options:(AFImageRequestOptions)options {
    id callback = [self callbackWithSuccess:success];
    [callback setImageSize:imageSize];
    [callback setOptions:options];
    
    return callback;
}

@end
