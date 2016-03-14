// AFUIImageViewTests.h
// Copyright (c) 2011–2016 Alamofire Software Foundation ( http://alamofire.org/ )
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
#import "UIImageView+AFNetworking.h"
#import "AFImageDownloader.h"

@interface AFUIImageViewTests : AFTestCase
@property (nonatomic, strong) UIImage *cachedImage;
@property (nonatomic, strong) NSURLRequest *cachedImageRequest;
@property (nonatomic, strong) UIImageView *imageView;

@property (nonatomic, strong) NSURL *error404URL;
@property (nonatomic, strong) NSURLRequest *error404URLRequest;

@property (nonatomic, strong) NSURL *jpegURL;
@property (nonatomic, strong) NSURLRequest *jpegURLRequest;

@end

@implementation AFUIImageViewTests

- (void)setUp {
    [super setUp];
    [[UIImageView sharedImageDownloader].imageCache removeAllImages];
    [[[[[[UIImageView sharedImageDownloader] sessionManager] session] configuration] URLCache] removeAllCachedResponses];
    [UIImageView setSharedImageDownloader:[[AFImageDownloader alloc] init]];

    self.imageView = [UIImageView new];

    self.jpegURL = [NSURL URLWithString:@"https://httpbin.org/image/jpeg"];
    self.jpegURLRequest = [NSURLRequest requestWithURL:self.jpegURL];

    self.error404URL = [NSURL URLWithString:@"https://httpbin.org/status/404"];
    self.error404URLRequest = [NSURLRequest requestWithURL:self.error404URL];

}

- (void)tearDown {
    self.imageView = nil;
    [super tearDown];

}

- (void)testThatImageCanBeDownloadedFromURL {
    XCTAssertNil(self.imageView.image);
    [self.imageView setImageWithURL:self.jpegURL];
    [self expectationForPredicate:[NSPredicate predicateWithFormat:@"image != nil"]
              evaluatedWithObject:self.imageView
                          handler:nil];
    [self waitForExpectationsWithCommonTimeoutUsingHandler:nil];
}

- (void)testThatImageDownloadSucceedsWhenDuplicateRequestIsSentToImageView {
    XCTAssertNil(self.imageView.image);
    [self.imageView setImageWithURL:self.jpegURL];
    [self.imageView setImageWithURL:self.jpegURL];
    [self expectationForPredicate:[NSPredicate predicateWithFormat:@"image != nil"]
              evaluatedWithObject:self.imageView
                          handler:nil];
    [self waitForExpectationsWithCommonTimeoutUsingHandler:nil];
}

- (void)testThatPlaceholderImageIsSetIfRequestFails {
    UIImage *placeholder = [UIImage imageNamed:@"logo"];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request should fail"];

    [self.imageView setImageWithURLRequest:self.error404URLRequest
                          placeholderImage:placeholder
                                   success:nil
                                   failure:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, NSError * _Nonnull error) {
                                       [expectation fulfill];
                                   }];
    [self waitForExpectationsWithCommonTimeoutUsingHandler:nil];
    XCTAssertEqual(self.imageView.image, placeholder);
}

- (void)testResponseIsNilWhenLoadedFromCache {
    AFImageDownloader *downloader = [UIImageView sharedImageDownloader];
    XCTestExpectation *cacheExpectation = [self expectationWithDescription:@"Cache request should succeed"];
    __block UIImage *downloadImage = nil;
    [downloader
     downloadImageForURLRequest:self.jpegURLRequest
     success:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, UIImage * _Nonnull responseObject) {
         downloadImage = responseObject;
         [cacheExpectation fulfill];
     }
     failure:nil];
    [self waitForExpectationsWithCommonTimeoutUsingHandler:nil];

    __block UIImage *cachedImage = nil;
    __block NSHTTPURLResponse *urlResponse;
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request should succeed"];
    [self.imageView
     setImageWithURLRequest:self.jpegURLRequest
     placeholderImage:nil
     success:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, UIImage * _Nonnull image) {
         urlResponse = response;
         cachedImage = image;
         [expectation fulfill];
     }
     failure:nil];
    [self waitForExpectationsWithCommonTimeoutUsingHandler:nil];
    XCTAssertNil(urlResponse);
    XCTAssertNotNil(cachedImage);
    XCTAssertEqual(cachedImage, downloadImage);
}

- (void)testThatImageCanBeCancelledAndDownloadedImmediately {
    //https://github.com/Alamofire/AlamofireImage/issues/55
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request should succeed"];
    [self.imageView setImageWithURL:self.jpegURL];
    [self.imageView cancelImageDownloadTask];
    __block UIImage *responseImage;
    [self.imageView
     setImageWithURLRequest:self.jpegURLRequest
     placeholderImage:nil
     success:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, UIImage * _Nonnull image) {
         responseImage = image;
         [expectation fulfill];
     }
     failure:nil];
    [self waitForExpectationsWithCommonTimeoutUsingHandler:nil];
    XCTAssertNotNil(responseImage);
}

- (void)testThatNilURLDoesntCrash {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    [self.imageView setImageWithURL:nil];
#pragma clang diagnostic pop

}



@end
