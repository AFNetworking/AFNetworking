// AFAutoPurgingImageCacheTests.m
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
#import "AFAutoPurgingImageCache.h"

@interface AFAutoPurgingImageCacheTests : XCTestCase
@property (nonatomic, strong) AFAutoPurgingImageCache *cache;
@property (nonatomic, strong) UIImage *testImage;
@end

@implementation AFAutoPurgingImageCacheTests

- (void)setUp {
    [super setUp];
    self.cache = [[AFAutoPurgingImageCache alloc] initWithMemoryCapacity:100 * 1024 * 1024
                                                 preferredMemoryCapacity:60 * 1024 * 1024];

    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"logo" ofType:@"png"];
    self.testImage = [UIImage imageWithContentsOfFile:path];


}

- (void)tearDown {
    [self.cache removeAllImages];
    self.cache = nil;
    self.testImage = nil;
    [super tearDown];
}

#pragma mark - Cache Return Images

- (void)testImageIsReturnedFromCacheForIdentifier {
    NSString *identifier = @"logo";
    [self.cache addImage:self.testImage withIdentifier:identifier];

    UIImage *cachedImage = [self.cache imageWithIdentifier:identifier];
    XCTAssertEqual(self.testImage, cachedImage, @"Cached image should equal original image");
}

- (void)testImageIsReturnedFromCacheForURLRequest {
    NSURL *url = [NSURL URLWithString:@"http://test.com/image"];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
    [self.cache addImage:self.testImage forRequest:request withAdditionalIdentifier:nil];

    UIImage *cachedImage = [self.cache imageforRequest:request withAdditionalIdentifier:nil];
    XCTAssertEqual(self.testImage, cachedImage, @"Cached image should equal original image");
}

- (void)testImageIsReturnedFromCacheForURLRequestWithAdditionalIdentifier {
    NSURL *url = [NSURL URLWithString:@"http://test.com/image"];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
    NSString *additionalIdentifier = @"filter";
    [self.cache addImage:self.testImage forRequest:request withAdditionalIdentifier:additionalIdentifier];

    UIImage *cachedImage = [self.cache imageforRequest:request withAdditionalIdentifier:additionalIdentifier];
    XCTAssertEqual(self.testImage, cachedImage, @"Cached image should equal original image");
}

- (void)testImageIsNotReturnedWhenAdditionalIdentifierIsNotSet {
    NSURL *url = [NSURL URLWithString:@"http://test.com/image"];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
    NSString *additionalIdentifier = @"filter";
    [self.cache addImage:self.testImage forRequest:request withAdditionalIdentifier:additionalIdentifier];

    UIImage *cachedImage = [self.cache imageforRequest:request withAdditionalIdentifier:nil];
    XCTAssertNil(cachedImage, @"cached image should be nil");
}

- (void)testImageIsNotReturnedWhenURLDoesntMatch {
    NSURL *url = [NSURL URLWithString:@"http://test.com/image"];
    NSURLRequest *originalRequest = [[NSURLRequest alloc] initWithURL:url];
    [self.cache addImage:self.testImage forRequest:originalRequest withAdditionalIdentifier:nil];

    NSURL *newURL = [NSURL URLWithString:@"http://test.com/differentImage"];
    NSURLRequest *newRequest = [[NSURLRequest alloc] initWithURL:newURL];
    UIImage *cachedImage = [self.cache imageforRequest:newRequest withAdditionalIdentifier:nil];
    XCTAssertNil(cachedImage, @"cached image should be nil");
}

- (void)testDuplicateImageAddedToCacheIsReturned {
    NSURL *url = [NSURL URLWithString:@"http://test.com/image"];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
    [self.cache addImage:self.testImage forRequest:request withAdditionalIdentifier:nil];

    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"logo" ofType:@"png"];
    UIImage *newImage = [UIImage imageWithContentsOfFile:path];

    [self.cache addImage:newImage forRequest:request withAdditionalIdentifier:nil];

    UIImage *cachedImage = [self.cache imageforRequest:request withAdditionalIdentifier:nil];
    XCTAssertEqual(cachedImage, newImage);
    XCTAssertNotEqual(cachedImage, self.testImage);
}

#pragma mark - Remove Image Tests

- (void)testImageIsRemovedWithIdentifier {
    NSString *identifier = @"logo";
    [self.cache addImage:self.testImage withIdentifier:identifier];
    XCTAssertTrue([self.cache removeImageWithIdentifier:identifier], @"image should be reported as removed");
    XCTAssertFalse([self.cache removeImageWithIdentifier:identifier], @"image should be reported as removed the second time");
    UIImage *cachedImage = [self.cache imageWithIdentifier:identifier];
    XCTAssertNil(cachedImage, @"cached image should be nil");
}

- (void)testImageIsRemovedWithURLRequest {
    NSURL *url = [NSURL URLWithString:@"http://test.com/image"];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
    [self.cache addImage:self.testImage forRequest:request withAdditionalIdentifier:nil];
    XCTAssertTrue([self.cache removeImageforRequest:request withAdditionalIdentifier:nil], @"image should be reported as removed");
    XCTAssertFalse([self.cache removeImageforRequest:request withAdditionalIdentifier:nil], @"image should be reported as removed the second time");
    UIImage *cachedImage = [self.cache imageforRequest:request withAdditionalIdentifier:nil];
    XCTAssertNil(cachedImage, @"cached image should be nil");
}

- (void)testImageIsRemovedWithURLRequestWithAdditionalIdentifier {
    NSURL *url = [NSURL URLWithString:@"http://test.com/image"];
    NSString *identifier = @"filter";
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
    [self.cache addImage:self.testImage forRequest:request withAdditionalIdentifier:identifier];
    XCTAssertTrue([self.cache removeImageforRequest:request withAdditionalIdentifier:identifier], @"image should be reported as removed");
    XCTAssertFalse([self.cache removeImageforRequest:request withAdditionalIdentifier:identifier], @"image should be reported as removed the second time");
    UIImage *cachedImage = [self.cache imageforRequest:request withAdditionalIdentifier:identifier];
    XCTAssertNil(cachedImage, @"cached image should be nil");
}

- (void)testImageIsNotRemovedWithURLRequestAndNilIdentifier {
    NSURL *url = [NSURL URLWithString:@"http://test.com/image"];
    NSString *identifier = @"filter";
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
    [self.cache addImage:self.testImage forRequest:request withAdditionalIdentifier:identifier];
    XCTAssertFalse([self.cache removeImageforRequest:request withAdditionalIdentifier:nil], @"image should not be reported as removed");
    UIImage *cachedImage = [self.cache imageforRequest:request withAdditionalIdentifier:identifier];
    XCTAssertNotNil(cachedImage, @"cached image should be nil");
}

- (void)testImageIsNotRemovedWithURLRequestAndIncorrectIdentifier {
    NSURL *url = [NSURL URLWithString:@"http://test.com/image"];
    NSString *identifier = @"filter";
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
    [self.cache addImage:self.testImage forRequest:request withAdditionalIdentifier:identifier];
    NSString *differentIdentifier = @"nofilter";
    XCTAssertFalse([self.cache removeImageforRequest:request withAdditionalIdentifier:differentIdentifier], @"image should not be reported as removed");
    UIImage *cachedImage = [self.cache imageforRequest:request withAdditionalIdentifier:identifier];
    XCTAssertNotNil(cachedImage, @"cached image should be nil");
}

#pragma mark - Memory Usage 
- (void)testThatMemoryUsageIncreasesWhenAddingImage {
    NSString *identifier = @"logo";
    XCTAssertTrue(self.cache.memoryUsage == 0);
    [self.cache addImage:self.testImage withIdentifier:identifier];
    XCTAssertTrue(self.cache.memoryUsage == 1020000);
}

- (void)testThatMemoryUsageDecreasesWhenRemovingImage {
    NSString *identifier = @"logo";
    [self.cache addImage:self.testImage withIdentifier:identifier];
    UInt64 currentUsage = self.cache.memoryUsage;
    [self.cache removeImageWithIdentifier:identifier];
    XCTAssertTrue(currentUsage > self.cache.memoryUsage);
}

#pragma mark - Purging
- (void)testThatImagesArePurgedWhenCapcityIsReached {
    UInt64 imageSize = 1020000;
    UInt64 numberOfImages = 10;
    UInt64 numberOfImagesAfterPurge = 6;
    self.cache = [[AFAutoPurgingImageCache alloc] initWithMemoryCapacity:numberOfImages * imageSize preferredMemoryCapacity:numberOfImagesAfterPurge * imageSize];
    NSUInteger index = 1;
    while (YES) {
        NSString * identifier = [NSString stringWithFormat:@"image-%ld",(long)index];
        [self.cache addImage:self.testImage withIdentifier:identifier];
        if (index <= numberOfImages) {
            XCTAssertTrue(self.cache.memoryUsage == index * imageSize);
        } else {
            XCTAssertTrue(self.cache.memoryUsage == numberOfImagesAfterPurge * imageSize);
            break;
        }
        index++;
    }
}

- (void)testThatPrioritizedImagesWithOldestLastAccessDatesAreRemovedDuringPurge {
    UInt64 imageSize = 1020000;
    UInt64 numberOfImages = 10;
    UInt64 numberOfImagesAfterPurge = 6;
    self.cache = [[AFAutoPurgingImageCache alloc] initWithMemoryCapacity:numberOfImages * imageSize preferredMemoryCapacity:numberOfImagesAfterPurge * imageSize];
    for (NSUInteger index = 0; index < numberOfImages; index ++) {
        NSString * identifier = [NSString stringWithFormat:@"image-%ld",(long)index];
        [self.cache addImage:self.testImage withIdentifier:identifier];
    }

    NSString * firstIdentifier = [NSString stringWithFormat:@"image-%ld",(long)0];
    UIImage *firstImage = [self.cache imageWithIdentifier:firstIdentifier];
    XCTAssertNotNil(firstImage, @"first image should not be nil");
    UInt64 prePurgeMemoryUsage = self.cache.memoryUsage;
    [self.cache addImage:self.testImage withIdentifier:[NSString stringWithFormat:@"image-%ld",(long)10]];
    UInt64 postPurgeMemoryUsage = self.cache.memoryUsage;
    XCTAssertTrue(postPurgeMemoryUsage < prePurgeMemoryUsage);

    for (NSUInteger index = 0; index <= numberOfImages ; index++) {
        NSString * identifier = [NSString stringWithFormat:@"image-%ld",(long)index];
        UIImage *cachedImage = [self.cache imageWithIdentifier:identifier];
        if (index == 0 || index >= 6) {
            XCTAssertNotNil(cachedImage, @"Image for %@ should be cached", identifier);
        } else {
            XCTAssertNil(cachedImage, @"Image for %@ should not be cached", identifier);
        }
    }
}

@end
