// UIImageView+AFNetworking.m
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

#import "UIImageView+AFNetworking.h"

#import <objc/runtime.h>

#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)

#import "AFHTTPImageLoader.h"

#pragma mark -

@implementation UIImageView (AFNetworking)
@dynamic imageLoader;

- (AFHTTPImageLoader*)imageLoader {
    static AFHTTPImageLoader* _af_defaultImageLoader = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _af_defaultImageLoader = [[AFHTTPImageLoader alloc] init];
    });
	
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wgnu"
    return objc_getAssociatedObject(self, @selector(imageLoader)) ?: _af_defaultImageLoader;
#pragma clang diagnostic pop
}

- (void)setImageLoader:(AFHTTPImageLoader *)imageLoader {
    objc_setAssociatedObject(self, @selector(imageLoader), imageLoader, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark -

- (void)setImageWithURL:(NSURL *)url {
    [self setImageWithURL:url placeholderImage:nil];
}

- (void)setImageWithURL:(NSURL *)url
       placeholderImage:(UIImage *)placeholderImage
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request addValue:@"image/*" forHTTPHeaderField:@"Accept"];

    [self setImageWithURLRequest:request placeholderImage:placeholderImage success:nil failure:nil];
}

- (void)setImageWithURLRequest:(NSURLRequest *)urlRequest
              placeholderImage:(UIImage *)placeholderImage
                       success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image))success
                       failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error))failure
{
	__weak typeof(self) weakSelf = self;
	
	self.image = placeholderImage;
	
	UIImage* image = [self.imageLoader imageWithURLRequest:urlRequest
												   success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
		if (success) {
			success(nil, nil, image);
		} else {
			weakSelf.image = image;
		}
	} failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
		if (failure) {
			failure(request, response, error);
		}
	}];
	
	if (image) {
		if (success) {
			success(nil, nil, image);
		} else {
			self.image = image;
		}
	}
}

- (void)cancelImageRequestOperation {
	[self.imageLoader cancelImageRequestOperation];
}

@end

#endif
