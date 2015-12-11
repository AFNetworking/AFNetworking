// AFURLSessionManagerBackgroundUplTests.m
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
#import "AFHTTPSessionManager.h"


@interface AFURLSessionManagerBackgroundUplTests : AFTestCase

@property (readwrite,nonatomic, strong) AFHTTPSessionManager * sessionManager;
@property (readwrite,nonatomic, strong) NSMutableURLRequest * fileUploadRequest;
@property (nonatomic, strong) NSURL * localFileUrl;

@end

@implementation AFURLSessionManagerBackgroundUplTests

- (void)setUp {
    [super setUp];
    
    // Test case won't fail if the defaultSessionConfiguration is set rather than backgroundSessionConfigurationWithIdentifier
    // NSURLSessionConfiguration * config = [NSURLSessionConfiguration  defaultSessionConfiguration];
    NSURLSessionConfiguration * config = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier: @"testId"];
    _sessionManager = [[AFHTTPSessionManager alloc]initWithSessionConfiguration:config ];
    
    
    
    NSString * uploadUrl = [NSString stringWithFormat:@"%@/%@",AFNetworkingTestsBaseURLString,@"post"];
    
    NSData * fileData =  [NSData dataWithContentsOfURL:
                          [NSString stringWithFormat:@"%@/%@",AFNetworkingTestsBaseURLString,@"image/jpeg"]];
    
    NSString *pathToWrite = [NSTemporaryDirectory() stringByAppendingString:@"test.jpg"];
    
    self.localFileUrl = [NSURL fileURLWithPath:pathToWrite];
    
    NSError * writeError;
    [fileData writeToURL:self.localFileUrl options:NSDataWritingAtomic error:&writeError];
    NSDictionary * params = @{@"name" : @"demo"};
    self.fileUploadRequest = [[AFHTTPRequestSerializer serializer] multipartFormRequestWithMethod:@"POST" URLString:uploadUrl parameters:params constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        
        [formData appendPartWithFileURL:self.localFileUrl name:@"fileData" error:nil];
        
    } error:nil];
}

- (void)tearDown {
    [super tearDown];
    [self.sessionManager invalidateSessionCancelingTasks:YES];
    self.sessionManager = nil;
    self.fileUploadRequest = nil;
    self.localFileUrl = nil;
    
}

// Upload works with Default Configuration, but crashes with background configuration


// Same XCTAssert in both test cases :P

-(void)testUploadStreamedRequest{
    
    XCTestExpectation * expectation =  [self expectationWithDescription:@"Should upload an image"];
    
    NSURLSessionUploadTask * uploadTask =  [_sessionManager uploadTaskWithStreamedRequest:self.fileUploadRequest progress:^(NSProgress * _Nonnull uploadProgress) {
        
        NSLog(@"Uploading: %@", uploadProgress);
        
    } completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        XCTAssertNil(error);
        XCTAssertTrue([responseObject isKindOfClass:[NSDictionary class]]);
        XCTAssertNotNil([responseObject objectForKey:@"files"]);
        NSDictionary * fileDic = [responseObject objectForKey:@"files"];
        NSDictionary * formDic =[responseObject objectForKey:@"form"];
        XCTAssertNotNil(fileDic);
        XCTAssertNotNil(formDic);
        
        XCTAssertNotNil([fileDic objectForKey:@"fileData"]);
        XCTAssertTrue([[fileDic objectForKey:@"fileData"] length] > 0);
        
        XCTAssertNotNil([formDic objectForKey:@"name"]);
        XCTAssertTrue([[formDic objectForKey:@"name"] length] > 0);
        
        [expectation fulfill];
        
    }];
    [uploadTask resume];
    
    [self waitForExpectationsWithCommonTimeoutUsingHandler: nil];
}

-(void)testUploadTaskRequest{
    
    XCTestExpectation * expectation =  [self expectationWithDescription:@"Should upload an image"];
    
    // Seems like params passed in fileUploadRequest are ignored
    
    NSURLSessionUploadTask * uploadTask =  [_sessionManager uploadTaskWithRequest:self.fileUploadRequest fromFile: self.localFileUrl progress:^(NSProgress * _Nonnull uploadProgress) {
        
        NSLog(@"Uploading: %@", uploadProgress);
        
        
    } completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        
        XCTAssertNil(error);
        XCTAssertTrue([responseObject isKindOfClass:[NSDictionary class]]);
        XCTAssertNotNil([responseObject objectForKey:@"files"]);
        NSDictionary * fileDic = [responseObject objectForKey:@"files"];
        NSDictionary * formDic =[responseObject objectForKey:@"form"];
        XCTAssertNotNil(fileDic);
        XCTAssertNotNil(formDic);
        
        // Asset Fails. For some reason request params aren't included.
        
        XCTAssertNotNil([fileDic objectForKey:@"fileData"]);
        XCTAssertTrue([[fileDic objectForKey:@"fileData"] length] > 0);
        
        XCTAssertNotNil([formDic objectForKey:@"name"]);
        XCTAssertTrue([[formDic objectForKey:@"name"] length] > 0);
        
        [expectation fulfill];
        
    }];
    [uploadTask resume];
    
    [self waitForExpectationsWithCommonTimeoutUsingHandler: nil];
    
}
@end

