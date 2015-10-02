// AFImageDownloaderTests.m
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

#import <XCTest/XCTest.h>
#import <AFNetworking/AFImageDownloader.h>

@interface AFImageDownloaderTests : XCTestCase
@property (nonatomic, strong) NSURLRequest *pngRequest;
@property (nonatomic, strong) NSURLRequest *jpegRequest;
@end

@implementation AFImageDownloaderTests

- (void)setUp {
    [super setUp];
    [[AFImageDownloader defaultURLCache] removeAllCachedResponses];
    [[[AFImageDownloader defaultInstance] imageCache] removeAllImages];
    NSURL *pngURL = [NSURL URLWithString:@"https://httpbin.org/image/png"];
    self.pngRequest = [NSURLRequest requestWithURL:pngURL];
    NSURL *jpegURL = [NSURL URLWithString:@"https://httpbin.org/image/jpeg"];
    self.jpegRequest = [NSURLRequest requestWithURL:jpegURL];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
    self.pngRequest = nil;
}

- (void)testThatImageDownloaderSingletonCanBeInitialized {
    AFImageDownloader *downloader = [AFImageDownloader defaultInstance];
    XCTAssertNotNil(downloader, @"Downloader should not be nil");
}

- (void)testThatImageDownloaderCanBeInitializedAndDeinitializedWithActiveDownloads {
    AFImageDownloader *downloader = [[AFImageDownloader alloc] init];
    [downloader downloadImageForURLRequest:self.pngRequest
                                   success:nil
                                   failure:nil];
    downloader = nil;
    XCTAssertNil(downloader, @"Downloader should be nil");
}

- (void)testThatImageDownloaderCanDownloadImage {
    AFImageDownloader *downloader = [[AFImageDownloader alloc] init];
    XCTestExpectation *expectation = [self expectationWithDescription:@"image download should succeed"];

    __block NSHTTPURLResponse *urlResponse = nil;
    __block UIImage *responseImage = nil;
    
    [downloader
     downloadImageForURLRequest:self.pngRequest
     success:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, UIImage * _Nonnull responseObject) {
         urlResponse = response;
         responseImage = responseObject;
         [expectation fulfill];
     }
     failure:nil];

    [self waitForExpectationsWithTimeout:5.0 handler:nil];

    XCTAssertNotNil(urlResponse, @"HTTPURLResponse should not be nil");
    XCTAssertNotNil(responseImage, @"Response image should not be nil");
}

- (void)testThatItCanDownloadMultipleImagesSimultaneously {
    AFImageDownloader *downloader = [[AFImageDownloader alloc] init];
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"image 1 download should succeed"];
    __block NSHTTPURLResponse *urlResponse1 = nil;
    __block UIImage *responseImage1 = nil;

    [downloader
     downloadImageForURLRequest:self.pngRequest
     success:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, UIImage * _Nonnull responseObject) {
         urlResponse1 = response;
         responseImage1 = responseObject;
         [expectation1 fulfill];
     }
     failure:nil];

    XCTestExpectation *expectation2 = [self expectationWithDescription:@"image 2 download should succeed"];
    __block NSHTTPURLResponse *urlResponse2 = nil;
    __block UIImage *responseImage2 = nil;

    [downloader
     downloadImageForURLRequest:self.jpegRequest
     success:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, UIImage * _Nonnull responseObject) {
         urlResponse2 = response;
         responseImage2 = responseObject;
         [expectation2 fulfill];
     }
     failure:nil];

    [self waitForExpectationsWithTimeout:30.0 handler:nil];

    XCTAssertNotNil(urlResponse1, @"HTTPURLResponse should not be nil");
    XCTAssertNotNil(responseImage1, @"Respone image should not be nil");

    XCTAssertNotNil(urlResponse2, @"HTTPURLResponse should not be nil");
    XCTAssertNotNil(responseImage2, @"Respone image should not be nil");
}

- (void)testThatSimultaneouslyRequestsForTheSameAssetReceiveSameResponse {
    AFImageDownloader *downloader = [[AFImageDownloader alloc] init];
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"image 1 download should succeed"];
    __block NSHTTPURLResponse *urlResponse1 = nil;
    __block UIImage *responseImage1 = nil;

    [downloader
     downloadImageForURLRequest:self.pngRequest
     success:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, UIImage * _Nonnull responseObject) {
         urlResponse1 = response;
         responseImage1 = responseObject;
         [expectation1 fulfill];
     }
     failure:nil];

    XCTestExpectation *expectation2 = [self expectationWithDescription:@"image 2 download should succeed"];
    __block NSHTTPURLResponse *urlResponse2 = nil;
    __block UIImage *responseImage2 = nil;

    [downloader
     downloadImageForURLRequest:self.pngRequest
     success:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, UIImage * _Nonnull responseObject) {
         urlResponse2 = response;
         responseImage2 = responseObject;
         [expectation2 fulfill];
     }
     failure:nil];

    [self waitForExpectationsWithTimeout:30.0 handler:nil];

    XCTAssertEqual(urlResponse1, urlResponse2, @"responses should be equal");
    XCTAssertEqual(responseImage2, responseImage2, @"responses should be equal");
}

#pragma mark - Cancellation

- (void)testThatCancellingDownloadCallsCompletionWithCancellationError {
    AFImageDownloader *downloader = [[AFImageDownloader alloc] init];
    AFImageDownloadReceipt *receipt;
    XCTestExpectation *expectation = [self expectationWithDescription:@"image download should fail"];
    __block NSError *responseError = nil;
    receipt = [downloader
               downloadImageForURLRequest:self.pngRequest
               success:nil
               failure:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, NSError * _Nonnull error) {
                   responseError = error;
                   [expectation fulfill];
               }];
    [downloader cancelTaskForImageDownloadReceipt:receipt];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];

    XCTAssertTrue(responseError.code == NSURLErrorCancelled);
    XCTAssertTrue([responseError.domain isEqualToString:NSURLErrorDomain]);
}

- (void)testThatCancellingDownloadWithMultipleResponseHandlersCancelsFirstYetAllowsSecondToComplete {
    AFImageDownloader *downloader = [[AFImageDownloader alloc] init];
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"image 1 download should succeed"];
    __block NSHTTPURLResponse *urlResponse = nil;
    __block UIImage *responseImage = nil;

    [downloader
     downloadImageForURLRequest:self.pngRequest
     success:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, UIImage * _Nonnull responseObject) {
         urlResponse = response;
         responseImage = responseObject;
         [expectation1 fulfill];
     }
     failure:nil];

    XCTestExpectation *expectation2 = [self expectationWithDescription:@"image 2 download should fail"];
    __block NSError *responseError = nil;
    AFImageDownloadReceipt *receipt;
    receipt = [downloader
               downloadImageForURLRequest:self.pngRequest
               success:nil
               failure:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, NSError * _Nonnull error) {
                   responseError = error;
                   [expectation2 fulfill];
               }];
    [downloader cancelTaskForImageDownloadReceipt:receipt];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];

    XCTAssertTrue(responseError.code == NSURLErrorCancelled);
    XCTAssertTrue([responseError.domain isEqualToString:NSURLErrorDomain]);
    XCTAssertNotNil(urlResponse);
    XCTAssertNotNil(responseImage);
}

#pragma mark - Threading
- (void)testThatItAlwaysCallsTheSuccessHandlerOnTheMainQueue {
    AFImageDownloader *downloader = [[AFImageDownloader alloc] init];
    XCTestExpectation *expectation = [self expectationWithDescription:@"image download should succeed"];
    __block BOOL successIsOnMainThread = false;
    [downloader
     downloadImageForURLRequest:self.pngRequest
     success:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, UIImage * _Nonnull responseObject) {
         successIsOnMainThread = [[NSThread currentThread] isMainThread];
         [expectation fulfill];
     }
     failure:nil];
    [self waitForExpectationsWithTimeout:10.0 handler:nil];
    XCTAssertTrue(successIsOnMainThread);
}

- (void)testThatItAlwaysCallsTheFailureHandlerOnTheMainQueue {
    AFImageDownloader *downloader = [[AFImageDownloader alloc] init];
    NSURL *url = [NSURL URLWithString:@"https://httpbin.org/status/404"];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    XCTestExpectation *expectation = [self expectationWithDescription:@"image download should fail"];
    __block BOOL failureIsOnMainThread = false;
    [downloader
     downloadImageForURLRequest:request
     success:nil
     failure:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, NSError * _Nonnull error) {
         failureIsOnMainThread = [[NSThread currentThread] isMainThread];
         [expectation fulfill];
     }];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
    XCTAssertTrue(failureIsOnMainThread);
}

@end
