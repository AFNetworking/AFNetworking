// AFImageRequestOperationTests.m
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

#import "AFNetworkingTests.h"

@interface AFImageRequestOperationTests : SenTestCase
@property (readwrite, nonatomic, strong) NSURL *baseURL;
@end

@implementation AFImageRequestOperationTests

- (void)setUp {
    self.baseURL = [NSURL URLWithString:AFNetworkingTestsBaseURLString];
}

#pragma mark -

- (void)testThatImageRequestOperationAcceptsTIFFContentType {
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/response-headers?Content-Type=image/tiff" relativeToURL:self.baseURL]];
    AFImageRequestOperation *operation = [[AFImageRequestOperation alloc] initWithRequest:request];
    [operation start];

    expect([operation isFinished]).will.beTruthy();
    expect(operation.error).will.beNil();
}

- (void)testThatImageRequestOperationAcceptsJPEGContentType {
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/response-headers?Content-Type=image/jpeg" relativeToURL:self.baseURL]];
    AFImageRequestOperation *operation = [[AFImageRequestOperation alloc] initWithRequest:request];
    [operation start];

    expect([operation isFinished]).will.beTruthy();
    expect(operation.error).will.beNil();
}

- (void)testThatImageRequestOperationAcceptsGIFContentType {
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/response-headers?Content-Type=image/gif" relativeToURL:self.baseURL]];
    AFImageRequestOperation *operation = [[AFImageRequestOperation alloc] initWithRequest:request];
    [operation start];

    expect([operation isFinished]).will.beTruthy();
    expect(operation.error).will.beNil();
}

- (void)testThatImageRequestOperationAcceptsPNGContentType {
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/response-headers?Content-Type=image/png" relativeToURL:self.baseURL]];
    AFImageRequestOperation *operation = [[AFImageRequestOperation alloc] initWithRequest:request];
    [operation start];

    expect([operation isFinished]).will.beTruthy();
    expect(operation.error).will.beNil();
}

- (void)testThatImageRequestOperationAcceptsIconContentTypes {
    NSArray *acceptableIconContentTypes = @[@"image/ico", @"image/x-icon"];
    for (NSString *contentType in acceptableIconContentTypes) {
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"/response-headers?Content-Type=%@", contentType] relativeToURL:self.baseURL]];
        AFImageRequestOperation *operation = [[AFImageRequestOperation alloc] initWithRequest:request];
        [operation start];

        expect([operation isFinished]).will.beTruthy();
        expect(operation.error).will.beNil();
    }
}

- (void)testThatImageRequestOperationAcceptsBitmapContentTypes {
    NSArray *acceptableBitmapContentTypes = @[@"image/bmp", @"image/x-bmp", @"image/x-xbitmap", @"image/x-win-bitmap"];
    for (NSString *contentType in acceptableBitmapContentTypes) {
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"/response-headers?Content-Type=%@", contentType] relativeToURL:self.baseURL]];
        AFImageRequestOperation *operation = [[AFImageRequestOperation alloc] initWithRequest:request];
        [operation start];

        expect([operation isFinished]).will.beTruthy();
        expect(operation.error).will.beNil();
    }
}

- (void)testThatImageRequestOperationDoesNotAcceptInvalidFormatTypes {
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/response-headers?Content-Type=image/invalid" relativeToURL:self.baseURL]];
    AFImageRequestOperation *operation = [[AFImageRequestOperation alloc] initWithRequest:request];
    [operation start];

    expect([operation isFinished]).will.beTruthy();
    expect(operation.error).willNot.beNil();
}

- (void)testThatImageResponseIsNotNilWhenRequestSucceeds {
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/response-headers?Content-Type=image/png" relativeToURL:self.baseURL]];
    AFImageRequestOperation *operation = [[AFImageRequestOperation alloc] initWithRequest:request];
    [operation start];

    expect([operation isFinished]).will.beTruthy();
    expect(operation.responseImage).willNot.beNil();
}

- (void)testThatImageResponseIsNilWhenRequestFails {
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/status/404" relativeToURL:self.baseURL]];
    AFImageRequestOperation *operation = [[AFImageRequestOperation alloc] initWithRequest:request];
    [operation start];

    expect([operation isFinished]).will.beTruthy();
    expect(operation.responseImage).will.beNil();
}

- (void)testImageProcessingBlockIsRunOnSuccess {
    __block BOOL imageProcessingBlockExecuted = NO;

    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/response-headers?Content-Type=image/png" relativeToURL:self.baseURL]];
    AFImageRequestOperation *operation = [AFImageRequestOperation imageRequestOperationWithRequest:request imageProcessingBlock:^UIImage *(UIImage *image) {
        imageProcessingBlockExecuted = YES;
        return image;
    } success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
        return;
    } failure:nil];

    [operation start];
    expect([operation isFinished]).will.beTruthy();
    expect(operation.error).will.beNil();
    expect(imageProcessingBlockExecuted).will.beTruthy();
}

- (void)testImageProcessingBlockIsNotRunOnFailure {
    __block UIImage *blockImage = nil;
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/status/404" relativeToURL:self.baseURL]];

    AFImageRequestOperation *operation = [AFImageRequestOperation imageRequestOperationWithRequest:request imageProcessingBlock:^UIImage *(UIImage *image) {
        blockImage = [[UIImage alloc] init];
        return blockImage;
    } success:nil failure:nil];
    [operation start];

    expect([operation isFinished]).will.beTruthy();
    expect(operation.error).willNot.beNil();
    expect(blockImage).will.beNil();
}

@end
