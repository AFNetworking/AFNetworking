// AFImageDownloaderTests.m
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
#import "AFImageDownloader.h"

@interface MockAFAutoPurgingImageCache : AFAutoPurgingImageCache
@property (nonatomic, strong) BOOL(^shouldCache)(UIImage*, NSURLRequest*, NSString*);
@property (nonatomic, strong) void(^addCache)(UIImage*, NSString*);
@end

@interface AFImageDownloaderTests : AFTestCase
@property (nonatomic, strong) NSURLRequest *pngRequest;
@property (nonatomic, strong) NSURLRequest *jpegRequest;
@property (nonatomic, strong) AFImageDownloader *downloader;
@end

@implementation AFImageDownloaderTests

- (void)setUp {
    [super setUp];
    self.downloader = [[AFImageDownloader alloc] init];
    [[AFImageDownloader defaultURLCache] removeAllCachedResponses];
    [[[AFImageDownloader defaultInstance] imageCache] removeAllImages];
    self.pngRequest = [NSURLRequest requestWithURL:self.pngURL];
    self.jpegRequest = [NSURLRequest requestWithURL:self.jpegURL];
}

- (void)tearDown {
    [self.downloader.sessionManager invalidateSessionCancelingTasks:YES];
    self.downloader = nil;
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
    self.pngRequest = nil;
}

#pragma mark - Image Download

- (void)testThatImageDownloaderSingletonCanBeInitialized {
    AFImageDownloader *downloader = [AFImageDownloader defaultInstance];
    XCTAssertNotNil(downloader, @"Downloader should not be nil");
}

- (void)testThatImageDownloaderCanBeInitializedAndDeinitializedWithActiveDownloads {
    [self.downloader downloadImageForURLRequest:self.pngRequest
                                   success:nil
                                   failure:nil];
    self.downloader = nil;
    XCTAssertNil(self.downloader, @"Downloader should be nil");
}

- (void)testThatImageDownloaderReturnsNilWithInvalidURL
{
    NSMutableURLRequest *mutableURLRequest = [NSMutableURLRequest requestWithURL:self.pngURL];
    [mutableURLRequest setURL:nil];
    /** NSURLRequest nor NSMutableURLRequest can be initialized with a nil URL, 
     *  but NSMutableURLRequest can have its URL set to nil 
     **/
    NSURLRequest *invalidRequest = [mutableURLRequest copy];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request should fail"];
    AFImageDownloadReceipt *downloadReceipt = [self.downloader
                                               downloadImageForURLRequest:invalidRequest
                                               success:nil
                                               failure:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, NSError * _Nonnull error) {
                                                   XCTAssertNotNil(error);
                                                   XCTAssertTrue([error.domain isEqualToString:NSURLErrorDomain]);
                                                   XCTAssertTrue(error.code == NSURLErrorBadURL);
                                                   [expectation fulfill];
                                               }];
    [self waitForExpectationsWithCommonTimeout];
    XCTAssertNil(downloadReceipt, @"downloadReceipt should be nil");
}

- (void)testThatImageDownloaderCanDownloadImage {
    XCTestExpectation *expectation = [self expectationWithDescription:@"image download should succeed"];

    __block NSHTTPURLResponse *urlResponse = nil;
    __block UIImage *responseImage = nil;
    
    [self.downloader
     downloadImageForURLRequest:self.pngRequest
     success:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, UIImage * _Nonnull responseObject) {
         urlResponse = response;
         responseImage = responseObject;
         [expectation fulfill];
     }
     failure:nil];

    [self waitForExpectationsWithCommonTimeout];

    XCTAssertNotNil(urlResponse, @"HTTPURLResponse should not be nil");
    XCTAssertNotNil(responseImage, @"Response image should not be nil");
}

- (void)testThatItCanDownloadMultipleImagesSimultaneously {
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"image 1 download should succeed"];
    __block NSHTTPURLResponse *urlResponse1 = nil;
    __block UIImage *responseImage1 = nil;

    [self.downloader
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

    [self.downloader
     downloadImageForURLRequest:self.jpegRequest
     success:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, UIImage * _Nonnull responseObject) {
         urlResponse2 = response;
         responseImage2 = responseObject;
         [expectation2 fulfill];
     }
     failure:nil];

    [self waitForExpectationsWithCommonTimeout];

    XCTAssertNotNil(urlResponse1, @"HTTPURLResponse should not be nil");
    XCTAssertNotNil(responseImage1, @"Respone image should not be nil");

    XCTAssertNotNil(urlResponse2, @"HTTPURLResponse should not be nil");
    XCTAssertNotNil(responseImage2, @"Respone image should not be nil");
}

- (void)testThatSimultaneouslyRequestsForTheSameAssetReceiveSameResponse {
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"image 1 download should succeed"];
    __block NSHTTPURLResponse *urlResponse1 = nil;
    __block UIImage *responseImage1 = nil;

    [self.downloader
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

    [self.downloader
     downloadImageForURLRequest:self.pngRequest
     success:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, UIImage * _Nonnull responseObject) {
         urlResponse2 = response;
         responseImage2 = responseObject;
         [expectation2 fulfill];
     }
     failure:nil];

    [self waitForExpectationsWithCommonTimeout];

    XCTAssertEqual(urlResponse1, urlResponse2, @"responses should be equal");
    XCTAssertEqual(responseImage2, responseImage2, @"responses should be equal");
}

- (void)testThatImageBehindRedirectCanBeDownloaded {
    XCTestExpectation *expectation = [self expectationWithDescription:@"image download should succeed"];
    NSURL *redirectURL = [self.jpegRequest URL];
    NSURLRequest *downloadRequest = [NSURLRequest requestWithURL:redirectURL];

    __block NSHTTPURLResponse *urlResponse = nil;
    __block UIImage *responseImage = nil;

    [self.downloader
     downloadImageForURLRequest:downloadRequest
     success:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, UIImage * _Nonnull responseObject) {
         urlResponse = response;
         responseImage = responseObject;
         [expectation fulfill];
     }
     failure:nil];
    [self waitForExpectationsWithCommonTimeout];
    XCTAssertNotNil(urlResponse);
    XCTAssertNotNil(responseImage);

}

#pragma mark - Caching
- (void)testThatResponseIsNilWhenReturnedFromCache {
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"image 1 download should succeed"];
    __block NSHTTPURLResponse *urlResponse1 = nil;
    __block UIImage *responseImage1 = nil;

    [self.downloader
     downloadImageForURLRequest:self.pngRequest
     success:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, UIImage * _Nonnull responseObject) {
         urlResponse1 = response;
         responseImage1 = responseObject;
         [expectation1 fulfill];
     }
     failure:nil];

    [self waitForExpectationsWithCommonTimeout];

    XCTestExpectation *expectation2 = [self expectationWithDescription:@"image 2 download should succeed"];
    __block NSHTTPURLResponse *urlResponse2 = nil;
    __block UIImage *responseImage2 = nil;

    [self.downloader
     downloadImageForURLRequest:self.pngRequest
     success:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, UIImage * _Nonnull responseObject) {
         urlResponse2 = response;
         responseImage2 = responseObject;
         [expectation2 fulfill];
     }
     failure:nil];

    [self waitForExpectationsWithCommonTimeout];

    XCTAssertNotNil(urlResponse1);
    XCTAssertNotNil(responseImage1);
    XCTAssertNil(urlResponse2);
    XCTAssertEqual(responseImage1, responseImage2);
}

- (void)testThatImageCacheIsPromptedShouldCache {
    XCTestExpectation *expectation3 = [self expectationWithDescription:@"image 1 shouldCache called"];
    XCTestExpectation *expectation4 = [self expectationWithDescription:@"image 1 addCache called"];
    
    MockAFAutoPurgingImageCache *mock = [[MockAFAutoPurgingImageCache alloc] init];
    mock.shouldCache = ^BOOL(UIImage *img, NSURLRequest *req, NSString *iden) {
        [expectation3 fulfill];
        return YES;
    };
    mock.addCache = ^(UIImage *img, NSString *ident) {
        [expectation4 fulfill];
    };
    self.downloader.imageCache = mock;
    
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"image 1 download should succeed"];
    __block NSHTTPURLResponse *urlResponse1 = nil;
    __block UIImage *responseImage1 = nil;
    
    [self.downloader
     downloadImageForURLRequest:self.pngRequest
     success:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, UIImage * _Nonnull responseObject) {
         urlResponse1 = response;
         responseImage1 = responseObject;
         [expectation1 fulfill];
     }
     failure:nil];
    
    [self waitForExpectationsWithCommonTimeout];
    
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"image 2 download should succeed"];
    __block NSHTTPURLResponse *urlResponse2 = nil;
    __block UIImage *responseImage2 = nil;
    
    [self.downloader
     downloadImageForURLRequest:self.pngRequest
     success:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, UIImage * _Nonnull responseObject) {
         urlResponse2 = response;
         responseImage2 = responseObject;
         [expectation2 fulfill];
     }
     failure:nil];
    
    [self waitForExpectationsWithCommonTimeout];
    
    XCTAssertNotNil(urlResponse1);
    XCTAssertNotNil(responseImage1);
    XCTAssertNil(urlResponse2);
    XCTAssertEqual(responseImage1, responseImage2);
}

- (void)testThatImageCacheIsPromptedShouldCacheNot {
    XCTestExpectation *expectation3 = [self expectationWithDescription:@"image 1 shouldCache called"];
    
    MockAFAutoPurgingImageCache *mock = [[MockAFAutoPurgingImageCache alloc] init];
    mock.shouldCache = ^BOOL(UIImage *img, NSURLRequest *req, NSString *iden) {
        [expectation3 fulfill];
        return NO;
    };
    mock.addCache = ^(UIImage *img, NSString *ident) {
        XCTFail(@"Not expected");
    };
    self.downloader.imageCache = mock;
    
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"image 1 download should succeed"];
    __block NSHTTPURLResponse *urlResponse1 = nil;
    __block UIImage *responseImage1 = nil;
    
    [self.downloader
     downloadImageForURLRequest:self.pngRequest
     success:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, UIImage * _Nonnull responseObject) {
         urlResponse1 = response;
         responseImage1 = responseObject;
         [expectation1 fulfill];
     }
     failure:nil];
    
    [self waitForExpectationsWithCommonTimeout];
    
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"image 2 download should succeed"];
    __block NSHTTPURLResponse *urlResponse2 = nil;
    __block UIImage *responseImage2 = nil;
    
    XCTestExpectation *expectation5 = [self expectationWithDescription:@"image 2 shouldCache called"];
    
    mock.shouldCache = ^BOOL(UIImage *img, NSURLRequest *req, NSString *iden) {
        [expectation5 fulfill];
        return NO;
    };
    
    [self.downloader
     downloadImageForURLRequest:self.pngRequest
     success:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, UIImage * _Nonnull responseObject) {
         urlResponse2 = response;
         responseImage2 = responseObject;
         [expectation2 fulfill];
     }
     failure:nil];
    
    [self waitForExpectationsWithCommonTimeout];
    
    XCTAssertNotNil(urlResponse1);
    XCTAssertNotNil(responseImage1);
    XCTAssertNotNil(urlResponse2);
    XCTAssertNotEqual(responseImage1, responseImage2);
}

- (void)testThatImageDownloadReceiptIsNilForCachedImage {
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"image 1 download should succeed"];
    AFImageDownloadReceipt *receipt1;
    receipt1 = [self.downloader
                downloadImageForURLRequest:self.pngRequest
                success:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, UIImage * _Nonnull responseObject) {
                    [expectation1 fulfill];
                }
                failure:nil];

    [self waitForExpectationsWithCommonTimeout];

    XCTestExpectation *expectation2 = [self expectationWithDescription:@"image 2 download should succeed"];

    AFImageDownloadReceipt *receipt2;
    receipt2 = [self.downloader
                downloadImageForURLRequest:self.pngRequest
                success:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, UIImage * _Nonnull responseObject) {
                    [expectation2 fulfill];
                }
                failure:nil];

    [self waitForExpectationsWithCommonTimeout];

    XCTAssertNotNil(receipt1);
    XCTAssertNil(receipt2);
}

- (void)testThatCacheIsIgnoredIfCacheIgnoredInRequest {
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"image 1 download should succeed"];

    __block NSHTTPURLResponse *urlResponse1 = nil;
    __block UIImage *responseImage1 = nil;
    AFImageDownloadReceipt *receipt1;
    receipt1 = [self.downloader
                downloadImageForURLRequest:self.pngRequest
                success:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, UIImage * _Nonnull responseObject) {
                    urlResponse1 = response;
                    responseImage1 = responseObject;
                    [expectation1 fulfill];
                }
                failure:nil];

    [self waitForExpectationsWithCommonTimeout];

    XCTestExpectation *expectation2 = [self expectationWithDescription:@"image 2 download should succeed"];
    NSMutableURLRequest *alteredRequest = [self.pngRequest mutableCopy];
    alteredRequest.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;

    AFImageDownloadReceipt *receipt2;
    __block NSHTTPURLResponse *urlResponse2 = nil;
    __block UIImage *responseImage2 = nil;
    receipt2 = [self.downloader
                downloadImageForURLRequest:alteredRequest
                success:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, UIImage * _Nonnull responseObject) {
                    urlResponse2 = response;
                    responseImage2 = responseObject;
                    [expectation2 fulfill];
                }
                failure:nil];

    [self waitForExpectationsWithCommonTimeout];

    XCTAssertNotNil(receipt1);
    XCTAssertNotNil(receipt2);
    XCTAssertNotEqual(receipt1, receipt2);

    XCTAssertNotNil(urlResponse1);
    XCTAssertNotNil(responseImage1);

    XCTAssertNotNil(urlResponse2);
    XCTAssertNotNil(responseImage2);

    XCTAssertNotEqual(responseImage1, responseImage2);
}

#pragma mark - Cancellation

- (void)testThatCancellingDownloadCallsCompletionWithCancellationError {
    AFImageDownloadReceipt *receipt;
    XCTestExpectation *expectation = [self expectationWithDescription:@"image download should fail"];
    __block NSError *responseError = nil;
    receipt = [self.downloader
               downloadImageForURLRequest:self.pngRequest
               success:nil
               failure:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, NSError * _Nonnull error) {
                   responseError = error;
                   [expectation fulfill];
               }];
    [self.downloader cancelTaskForImageDownloadReceipt:receipt];
    [self waitForExpectationsWithCommonTimeout];

    XCTAssertTrue(responseError.code == NSURLErrorCancelled);
    XCTAssertTrue([responseError.domain isEqualToString:NSURLErrorDomain]);
}

- (void)testThatCancellingDownloadWithMultipleResponseHandlersCancelsFirstYetAllowsSecondToComplete {
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"image 1 download should succeed"];
    __block NSHTTPURLResponse *urlResponse = nil;
    __block UIImage *responseImage = nil;

    [self.downloader
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
    receipt = [self.downloader
               downloadImageForURLRequest:self.pngRequest
               success:nil
               failure:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, NSError * _Nonnull error) {
                   responseError = error;
                   [expectation2 fulfill];
               }];
    [self.downloader cancelTaskForImageDownloadReceipt:receipt];
    [self waitForExpectationsWithCommonTimeout];

    XCTAssertTrue(responseError.code == NSURLErrorCancelled);
    XCTAssertTrue([responseError.domain isEqualToString:NSURLErrorDomain]);
    XCTAssertNotNil(urlResponse);
    XCTAssertNotNil(responseImage);
}

- (void)testThatItCanDownloadAndCancelAndDownloadAgain {
    NSArray *imageURLStrings = @[
                                 @"https://secure.gravatar.com/avatar/5a105e8b9d40e1329780d62ea2265d8a?d=identicon",
                                 @"https://secure.gravatar.com/avatar/6a105e8b9d40e1329780d62ea2265d8a?d=identicon",
                                 @"https://secure.gravatar.com/avatar/7a105e8b9d40e1329780d62ea2265d8a?d=identicon",
                                 @"https://secure.gravatar.com/avatar/8a105e8b9d40e1329780d62ea2265d8a?d=identicon",
                                 @"https://secure.gravatar.com/avatar/9a105e8b9d40e1329780d62ea2265d8a?d=identicon"
                                 ];

    for (NSString *imageURLString in imageURLStrings) {
        XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"Request %@ should be cancelled", imageURLString]];
        AFImageDownloadReceipt *receipt = [self.downloader
                                           downloadImageForURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:imageURLString]]
                                           success:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, UIImage * _Nonnull responseObject) {
                                               XCTFail(@"Request %@ succeeded when it should have failed", request);
                                           }
                                           failure:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, NSError * _Nonnull error) {
                                               XCTAssertTrue([error.domain isEqualToString:NSURLErrorDomain]);
                                               XCTAssertTrue([error code] == NSURLErrorCancelled);
                                               [expectation fulfill];
                                           }];
        [self.downloader cancelTaskForImageDownloadReceipt:receipt];
    }

    for (NSString *imageURLString in imageURLStrings) {
        XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"Request %@ should succeed", imageURLString]];
        [self.downloader
         downloadImageForURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:imageURLString]]
         success:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, UIImage * _Nonnull responseObject) {
             [expectation fulfill];
         } failure:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, NSError * _Nonnull error) {
             XCTFail(@"Request %@ failed with error %@", request, error);
         }];
    }

    [self waitForExpectationsWithCommonTimeout];
}

#pragma mark - Threading
- (void)testThatItAlwaysCallsTheSuccessHandlerOnTheMainQueue {
    XCTestExpectation *expectation = [self expectationWithDescription:@"image download should succeed"];
    __block BOOL successIsOnMainThread = false;
    [self.downloader
     downloadImageForURLRequest:self.pngRequest
     success:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, UIImage * _Nonnull responseObject) {
         successIsOnMainThread = [[NSThread currentThread] isMainThread];
         [expectation fulfill];
     }
     failure:nil];
    [self waitForExpectationsWithCommonTimeout];
    XCTAssertTrue(successIsOnMainThread);
}

- (void)testThatItAlwaysCallsTheFailureHandlerOnTheMainQueue {
    NSURLRequest *notFoundRequest = [NSURLRequest requestWithURL:[self URLWithStatusCode:404]];
    XCTestExpectation *expectation = [self expectationWithDescription:@"image download should fail"];
    __block BOOL failureIsOnMainThread = false;
    [self.downloader
     downloadImageForURLRequest:notFoundRequest
     success:nil
     failure:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, NSError * _Nonnull error) {
         failureIsOnMainThread = [[NSThread currentThread] isMainThread];
         [expectation fulfill];
     }];
    [self waitForExpectationsWithCommonTimeout];
    XCTAssertTrue(failureIsOnMainThread);
}

#pragma mark - misc

- (void)testThatReceiptIDMatchesReturnedID {
    NSUUID *receiptId = [NSUUID UUID];
    AFImageDownloadReceipt *receipt =  [self.downloader
                                        downloadImageForURLRequest:self.jpegRequest
                                        withReceiptID:receiptId
                                        success:nil
                                        failure:nil];
    XCTAssertEqual(receiptId, receipt.receiptID);
    [self.downloader cancelTaskForImageDownloadReceipt:receipt];
}

@end

#pragma mark -

@implementation MockAFAutoPurgingImageCache

-(BOOL)shouldCacheImage:(UIImage *)image forRequest:(NSURLRequest *)request withAdditionalIdentifier:(NSString *)identifier {
    if (self.shouldCache) {
        return self.shouldCache(image, request, identifier);
    }
    else {
        return [super shouldCacheImage:image forRequest:request withAdditionalIdentifier:identifier];
    }
}

-(void)addImage:(UIImage *)image withIdentifier:(NSString *)identifier{
    [super addImage:image withIdentifier:identifier];
    if (self.addCache) {
        self.addCache(image, identifier);
    }
}
@end
