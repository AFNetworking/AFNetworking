// AFUIButtonTests.h
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

#import <XCTest/XCTest.h>
#import "AFTestCase.h"
#import "UIButton+AFNetworking.h"
#import "AFImageDownloader.h"

@interface AFUIButtonTests : AFTestCase
@property (nonatomic, strong) UIImage *cachedImage;
@property (nonatomic, strong) NSURLRequest *cachedImageRequest;
@property (nonatomic, strong) UIButton *button;

@property (nonatomic, strong) NSURL *error404URL;
@property (nonatomic, strong) NSURLRequest *error404URLRequest;

@property (nonatomic, strong) NSURL *jpegURL;
@property (nonatomic, strong) NSURLRequest *jpegURLRequest;
@end

@implementation AFUIButtonTests

- (void)setUp {
    [super setUp];
    [[UIButton sharedImageDownloader].imageCache removeAllImages];
    [[[[[[UIButton sharedImageDownloader] sessionManager] session] configuration] URLCache] removeAllCachedResponses];
    [UIButton setSharedImageDownloader:[[AFImageDownloader alloc] init]];

    self.button = [UIButton new];

    self.jpegURL = [NSURL URLWithString:@"https://httpbin.org/image/jpeg"];
    self.jpegURLRequest = [NSURLRequest requestWithURL:self.jpegURL];

    self.error404URL = [NSURL URLWithString:@"https://httpbin.org/status/404"];
    self.error404URLRequest = [NSURLRequest requestWithURL:self.error404URL];

}

- (void)tearDown {
    self.button = nil;
    [super tearDown];
    
}

- (void)testThatBackgroundImageChanges {
    XCTAssertNil([self.button backgroundImageForState:UIControlStateNormal]);
    [self.button setBackgroundImageForState:UIControlStateNormal withURL:self.jpegURL];
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(UIButton  * _Nonnull button, NSDictionary<NSString *,id> * _Nullable bindings) {
        return [button backgroundImageForState:UIControlStateNormal] != nil;
    }];
    
    [self expectationForPredicate:predicate
              evaluatedWithObject:self.button
                          handler:nil];
    
    [self waitForExpectationsWithCommonTimeoutUsingHandler:nil];
}

- (void)testThatForegroundImageCanBeCancelledAndDownloadedImmediately {
    //https://github.com/Alamofire/AlamofireImage/issues/55
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request should succeed"];
    [self.button setImageForState:UIControlStateNormal withURL:self.jpegURL];
    [self.button cancelImageDownloadTaskForState:UIControlStateNormal];
    __block UIImage *responseImage;
    [self.button
     setImageForState:UIControlStateNormal
     withURLRequest:self.jpegURLRequest
     placeholderImage:nil
     success:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, UIImage * _Nonnull image) {
         responseImage = image;
         [expectation fulfill];
     }
     failure:nil];
    [self waitForExpectationsWithCommonTimeoutUsingHandler:nil];
    XCTAssertNotNil(responseImage);
}

- (void)testThatBackgroundImageCanBeCancelledAndDownloadedImmediately {
    //https://github.com/Alamofire/AlamofireImage/issues/55
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request should succeed"];
    [self.button setBackgroundImageForState:UIControlStateNormal withURL:self.jpegURL];
    [self.button cancelBackgroundImageDownloadTaskForState:UIControlStateNormal];
    __block UIImage *responseImage;
    [self.button
     setBackgroundImageForState:UIControlStateNormal
     withURLRequest:self.jpegURLRequest
     placeholderImage:nil
     success:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, UIImage * _Nonnull image) {
         responseImage = image;
         [expectation fulfill];
     }
     failure:nil];
    [self waitForExpectationsWithCommonTimeoutUsingHandler:nil];
    XCTAssertNotNil(responseImage);
}

@end
