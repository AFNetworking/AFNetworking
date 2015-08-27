// AFUIImageViewTests.h
// Copyright (c) 2011–2015 Alamofire Software Foundation (http://alamofire.org/)
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

#import "AFTestCase.h"
#import <AFNetworking/UIImageView+AFNetworking.h>
#import <OCMock/OCMock.h>

@interface AFUIImageViewTests : AFTestCase
@property (nonatomic, strong) UIImage *cachedImage;
@property (nonatomic, strong) NSURLRequest *cachedImageRequest;
@property (nonatomic, strong) UIImageView *imageView;
@end

@implementation AFUIImageViewTests

- (void)setUp {
    [super setUp];
    self.imageView = [UIImageView new];
    [self setUpSharedImageCache];
}

- (void)tearDown {
    [self tearDownSharedImageCache];
    [super tearDown];
}

- (void)setUpSharedImageCache {
    NSString *resourcePath = [[NSBundle bundleForClass:[self class]] resourcePath];
    NSString *imagePath = [resourcePath stringByAppendingPathComponent:@"Icon.png"];
    self.cachedImage = [UIImage imageWithContentsOfFile:imagePath];
    self.cachedImageRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://foo.bar/image"]];
    
    id<AFImageCache> mockImageCache = [OCMockObject mockForProtocol:@protocol(AFImageCache)];
    [[[(OCMockObject *)mockImageCache stub] andReturn:self.cachedImage] cachedImageForRequest:self.cachedImageRequest];
    [UIImageView setSharedImageCache:mockImageCache];
}

- (void)tearDownSharedImageCache {
    [UIImageView setSharedImageCache:nil];
}

- (void)testSetImageWithURLRequestUsesCachedImage {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Image view uses cached image"];
    typeof(self) __weak weakSelf = self;
    [self.imageView
     setImageWithURLRequest:self.cachedImageRequest
     placeholderImage:nil
     success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
         XCTAssertEqual(request, weakSelf.cachedImageRequest, @"URL requests do not match");
         XCTAssertNil(response, @"Response should be nil when image is returned from cache");
         XCTAssertEqual(image, weakSelf.cachedImage, @"Cached images do not match");
         [expectation fulfill];
     }
     failure:nil];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

@end
