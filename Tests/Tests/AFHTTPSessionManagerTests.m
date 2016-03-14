// AFHTTPSessionManagerTests.m
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

#import "AFHTTPSessionManager.h"
#import "AFSecurityPolicy.h"

@interface AFHTTPSessionManagerTests : AFTestCase
@property (readwrite, nonatomic, strong) AFHTTPSessionManager *manager;
@end

@implementation AFHTTPSessionManagerTests

- (void)setUp {
    [super setUp];
    self.manager = [[AFHTTPSessionManager alloc] initWithBaseURL:self.baseURL];
}

- (void)tearDown {
    [self.manager invalidateSessionCancelingTasks:YES];
    [super tearDown];
}

#pragma mark - init
- (void)testSharedManagerIsNotEqualToInitdManager {
    XCTAssertFalse([[AFHTTPSessionManager manager] isEqual:self.manager]);
}

#pragma mark - misc

- (void)testThatOperationInvokesCompletionHandlerWithResponseObjectOnSuccess {
    __block id blockResponseObject = nil;
    __block id blockError = nil;

    XCTestExpectation *expectation = [self expectationWithDescription:@"Request should succeed"];

    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/get" relativeToURL:self.baseURL]];
    NSURLSessionDataTask *task = [self.manager dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
        blockResponseObject = responseObject;
        blockError = error;
        [expectation fulfill];
    }];

    [task resume];

    [self waitForExpectationsWithTimeout:10.0 handler:nil];

    XCTAssertTrue(task.state == NSURLSessionTaskStateCompleted);
    XCTAssertNil(blockError);
    XCTAssertNotNil(blockResponseObject);
}

- (void)testThatOperationInvokesFailureCompletionBlockWithErrorOnFailure {
    __block id blockError = nil;

    XCTestExpectation *expectation = [self expectationWithDescription:@"Request should succeed"];

    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/status/404" relativeToURL:self.baseURL]];
    NSURLSessionDataTask *task = [self.manager dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
        blockError = error;
        [expectation fulfill];
    }];

    [task resume];

    [self waitForExpectationsWithTimeout:10.0 handler:nil];

    XCTAssertTrue(task.state == NSURLSessionTaskStateCompleted);
    XCTAssertNotNil(blockError);
}

- (void)testThatRedirectBlockIsCalledWhen302IsEncountered {
    __block BOOL success;
    __block NSError *blockError = nil;

    XCTestExpectation *expectation = [self expectationWithDescription:@"Request should succeed"];

    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/redirect/1" relativeToURL:self.baseURL]];
    NSURLSessionDataTask *task = [self.manager dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
        blockError = error;
        [expectation fulfill];
    }];

    [self.manager setTaskWillPerformHTTPRedirectionBlock:^NSURLRequest *(NSURLSession *session, NSURLSessionTask *task, NSURLResponse *response, NSURLRequest *request) {
        if (response) {
            success = YES;
        }

        return request;
    }];

    [task resume];

    [self waitForExpectationsWithTimeout:10.0 handler:nil];

    XCTAssertTrue(task.state == NSURLSessionTaskStateCompleted);
    XCTAssertNil(blockError);
    XCTAssertTrue(success);
}

- (void)testDownloadFileCompletionSpecifiesURLInCompletionWithManagerDidFinishBlock {
    __block BOOL managerDownloadFinishedBlockExecuted = NO;
    __block BOOL completionBlockExecuted = NO;
    __block NSURL *downloadFilePath = nil;
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request should succeed"];

    [self.manager setDownloadTaskDidFinishDownloadingBlock:^NSURL *(NSURLSession *session, NSURLSessionDownloadTask *downloadTask, NSURL *location) {
        managerDownloadFinishedBlockExecuted = YES;
        NSURL *dirURL  = [[[NSFileManager defaultManager] URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask] lastObject];
        return [dirURL URLByAppendingPathComponent:@"t1.file"];
    }];

    NSURLSessionDownloadTask *downloadTask;
    downloadTask = [self.manager
                    downloadTaskWithRequest:[NSURLRequest requestWithURL:self.baseURL]
                    progress:nil
                    destination:nil
                    completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
                        downloadFilePath = filePath;
                        completionBlockExecuted = YES;
                        [expectation fulfill];
                    }];
    [downloadTask resume];
    [self waitForExpectationsWithTimeout:10.0 handler:nil];
    XCTAssertTrue(completionBlockExecuted);
    XCTAssertTrue(managerDownloadFinishedBlockExecuted);
    XCTAssertNotNil(downloadFilePath);
}

- (void)testDownloadFileCompletionSpecifiesURLInCompletionBlock {
    __block BOOL destinationBlockExecuted = NO;
    __block BOOL completionBlockExecuted = NO;
    __block NSURL *downloadFilePath = nil;
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request should succeed"];

    NSURLSessionDownloadTask *downloadTask = [self.manager downloadTaskWithRequest:[NSURLRequest requestWithURL:self.baseURL]
                                                                          progress:nil
                                                                       destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
                                                                           destinationBlockExecuted = YES;
                                                                           NSURL *dirURL  = [[[NSFileManager defaultManager] URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask] lastObject];
                                                                           return [dirURL URLByAppendingPathComponent:@"t1.file"];
                                                                       }
                                                                 completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
                                                                     downloadFilePath = filePath;
                                                                     completionBlockExecuted = YES;
                                                                     [expectation fulfill];
                                                                 }];
    [downloadTask resume];
    [self waitForExpectationsWithTimeout:10.0 handler:nil];
    XCTAssertTrue(completionBlockExecuted);
    XCTAssertTrue(destinationBlockExecuted);
    XCTAssertNotNil(downloadFilePath);
}

- (void)testThatSerializationErrorGeneratesErrorAndNullTaskForGET {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Serialization should fail"];

    [self.manager.requestSerializer setQueryStringSerializationWithBlock:^NSString * _Nonnull(NSURLRequest * _Nonnull request, id  _Nonnull parameters, NSError * _Nullable __autoreleasing * _Nullable error) {
        *error = [NSError errorWithDomain:@"Custom" code:-1 userInfo:nil];
        return @"";
    }];

    NSURLSessionTask *nilTask;
    nilTask = [self.manager
               GET:@"test"
               parameters:@{@"key":@"value"}
               progress:nil
               success:nil
               failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                   XCTAssertNil(task);
                   [expectation fulfill];
               }];
    XCTAssertNil(nilTask);
    [self waitForExpectationsWithTimeout:10.0 handler:nil];
}

#pragma mark - NSCoding

- (void)testSupportsSecureCoding {
    XCTAssertTrue([AFHTTPSessionManager supportsSecureCoding]);
}

- (void)testCanBeEncoded {
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self.manager];
    XCTAssertNotNil(data);
}

- (void)testCanBeDecoded {
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self.manager];
    AFHTTPSessionManager *newManager = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    XCTAssertNotNil(newManager.securityPolicy);
    XCTAssertNotNil(newManager.requestSerializer);
    XCTAssertNotNil(newManager.responseSerializer);
    XCTAssertNotNil(newManager.baseURL);
    XCTAssertNotNil(newManager.session);
    XCTAssertNotNil(newManager.session.configuration);
}

#pragma mark - NSCopying 

- (void)testCanBeCopied {
    AFHTTPSessionManager *copyManager = [self.manager copy];
    XCTAssertNotNil(copyManager);
}

#pragma mark - Progress

- (void)testDownloadProgressIsReportedForGET {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Progress Should equal 1.0"];
    [self.manager
     GET:@"image"
     parameters:nil
     progress:^(NSProgress * _Nonnull downloadProgress) {
         if (downloadProgress.fractionCompleted == 1.0) {
             [expectation fulfill];
         }
     }
     success:nil
     failure:nil];
    [self waitForExpectationsWithCommonTimeoutUsingHandler:nil];
}

- (void)testUploadProgressIsReportedForPOST {
    NSMutableString *payload = [NSMutableString stringWithString:@"AFNetworking"];
    while ([payload lengthOfBytesUsingEncoding:NSUTF8StringEncoding] < 20000) {
        [payload appendString:@"AFNetworking"];
    }

    __weak __block XCTestExpectation *expectation = [self expectationWithDescription:@"Progress Should equal 1.0"];

    [self.manager
     POST:@"post"
     parameters:payload
     progress:^(NSProgress * _Nonnull uploadProgress) {
         if (uploadProgress.fractionCompleted == 1.0) {
             [expectation fulfill];
             expectation = nil;
         }
     }
     success:nil
     failure:nil];
    [self waitForExpectationsWithCommonTimeoutUsingHandler:nil];
}

- (void)testUploadProgressIsReportedForStreamingPost {
    NSMutableString *payload = [NSMutableString stringWithString:@"AFNetworking"];
    while ([payload lengthOfBytesUsingEncoding:NSUTF8StringEncoding] < 20000) {
        [payload appendString:@"AFNetworking"];
    }

    __block __weak XCTestExpectation *expectation = [self expectationWithDescription:@"Progress Should equal 1.0"];

    [self.manager
     POST:@"post"
     parameters:nil
     constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
         [formData appendPartWithFileData:[payload dataUsingEncoding:NSUTF8StringEncoding] name:@"AFNetworking" fileName:@"AFNetworking" mimeType:@"text/html"];
     }
     progress:^(NSProgress * _Nonnull uploadProgress) {
         if (uploadProgress.fractionCompleted == 1.0) {
             [expectation fulfill];
             expectation = nil;
         }
     }
     success:nil
     failure:nil];
    [self waitForExpectationsWithCommonTimeoutUsingHandler:nil];
}

# pragma mark - HTTP Status Codes

- (void)testThatSuccessBlockIsCalledFor200 {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request should succeed"];
    [self.manager
     GET:@"status/200"
     parameters:nil
     progress:nil
     success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
         [expectation fulfill];
     }
     failure:nil];
    [self waitForExpectationsWithCommonTimeoutUsingHandler:nil];
}

- (void)testThatFailureBlockIsCalledFor404 {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request should succeed"];
    [self.manager
     GET:@"status/404"
     parameters:nil
     progress:nil
     success:nil
     failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nullable error) {
         [expectation fulfill];
     }];
    [self waitForExpectationsWithCommonTimeoutUsingHandler:nil];
}

- (void)testThatResponseObjectIsEmptyFor204 {
    __block id urlResponseObject = nil;
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request should succeed"];
    [self.manager
     GET:@"status/204"
     parameters:nil
     progress:nil
     success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
         urlResponseObject = responseObject;
         [expectation fulfill];
     }
     failure:nil];
    [self waitForExpectationsWithCommonTimeoutUsingHandler:nil];
    XCTAssertNil(urlResponseObject);
}

#pragma mark - Rest Interface 

- (void)testGET {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request should succeed"];
    [self.manager
     GET:@"get"
     parameters:nil
     progress:nil
     success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
         XCTAssertNotNil(responseObject);
         [expectation fulfill];
     }
     failure:nil];
    [self waitForExpectationsWithCommonTimeoutUsingHandler:nil];
}

- (void)testHEAD {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request should succeed"];
    [self.manager
     HEAD:@"get"
     parameters:nil
     success:^(NSURLSessionDataTask * _Nonnull task) {
         XCTAssertNotNil(task);
         [expectation fulfill];
     }
     failure:nil];
    [self waitForExpectationsWithCommonTimeoutUsingHandler:nil];
}

- (void)testPOST {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request should succeed"];
    [self.manager
     POST:@"post"
     parameters:@{@"key":@"value"}
     progress:nil
     success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
         XCTAssertTrue([responseObject[@"form"][@"key"] isEqualToString:@"value"]);
         [expectation fulfill];
     }
     failure:nil];
    [self waitForExpectationsWithCommonTimeoutUsingHandler:nil];
}

- (void)testPOSTWithConstructingBody {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request should succeed"];
    [self.manager
     POST:@"post"
     parameters:@{@"key":@"value"}
     constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
         [formData appendPartWithFileData:[@"Data" dataUsingEncoding:NSUTF8StringEncoding]
                                     name:@"DataName"
                                 fileName:@"DataFileName"
                                 mimeType:@"data"];
     }
     progress:nil
     success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
         XCTAssertTrue([responseObject[@"files"][@"DataName"] isEqualToString:@"Data"]);
         XCTAssertTrue([responseObject[@"form"][@"key"] isEqualToString:@"value"]);
         [expectation fulfill];
     }
     failure:nil];
    [self waitForExpectationsWithCommonTimeoutUsingHandler:nil];
}

- (void)testPUT {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request should succeed"];
    [self.manager
     PUT:@"put"
     parameters:@{@"key":@"value"}
     success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
         XCTAssertTrue([responseObject[@"form"][@"key"] isEqualToString:@"value"]);
         [expectation fulfill];
     }
     failure:nil];
    [self waitForExpectationsWithCommonTimeoutUsingHandler:nil];
}

- (void)testDELETE {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request should succeed"];
    [self.manager
     DELETE:@"delete"
     parameters:@{@"key":@"value"}
     success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
         XCTAssertTrue([responseObject[@"args"][@"key"] isEqualToString:@"value"]);
         [expectation fulfill];
     }
     failure:nil];
    [self waitForExpectationsWithCommonTimeoutUsingHandler:nil];
}

- (void)testPATCH {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request should succeed"];
    [self.manager
     PATCH:@"patch"
     parameters:@{@"key":@"value"}
     success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
         XCTAssertTrue([responseObject[@"form"][@"key"] isEqualToString:@"value"]);
         [expectation fulfill];
     }
     failure:nil];

    [self waitForExpectationsWithCommonTimeoutUsingHandler:nil];
}

#pragma mark - Deprecated Rest Interface

- (void)testDeprecatedGET {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request should succeed"];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [self.manager
     GET:@"get"
     parameters:nil
     success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
         XCTAssertNotNil(responseObject);
         [expectation fulfill];
     }
     failure:nil];
#pragma clang diagnostic pop
    [self waitForExpectationsWithCommonTimeoutUsingHandler:nil];
}

- (void)testDeprecatedPOST {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request should succeed"];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [self.manager
     POST:@"post"
     parameters:@{@"key":@"value"}
     success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
         XCTAssertTrue([responseObject[@"form"][@"key"] isEqualToString:@"value"]);
         [expectation fulfill];
     }
     failure:nil];
#pragma clang diagnostic pop
    [self waitForExpectationsWithCommonTimeoutUsingHandler:nil];
}

- (void)testDeprecatedPOSTWithConstructingBody {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request should succeed"];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [self.manager
     POST:@"post"
     parameters:@{@"key":@"value"}
     constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
         [formData appendPartWithFileData:[@"Data" dataUsingEncoding:NSUTF8StringEncoding]
                                     name:@"DataName"
                                 fileName:@"DataFileName"
                                 mimeType:@"data"];
     }
     success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
         XCTAssertTrue([responseObject[@"files"][@"DataName"] isEqualToString:@"Data"]);
         XCTAssertTrue([responseObject[@"form"][@"key"] isEqualToString:@"value"]);
         [expectation fulfill];
     }
     failure:nil];
#pragma clang diagnostic pop    
    [self waitForExpectationsWithCommonTimeoutUsingHandler:nil];
}

#pragma mark - Auth

- (void)testHiddenBasicAuthentication {
    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"Request should finish"];
    [self.manager.requestSerializer setAuthorizationHeaderFieldWithUsername:@"user" password:@"password"];
    [self.manager
     GET:@"hidden-basic-auth/user/password"
     parameters:nil
     progress:nil
     success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
         [expectation fulfill];
     } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
         XCTFail(@"Request should succeed");
         [expectation fulfill];
     }];
    [self waitForExpectationsWithCommonTimeoutUsingHandler:nil];
}

# pragma mark - Server Trust

- (void)testInvalidServerTrustProducesCorrectError {
    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"Request should fail"];
    NSURL *googleCertificateURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"google.com" withExtension:@"cer"];
    NSData *googleCertificateData = [NSData dataWithContentsOfURL:googleCertificateURL];
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:@"https://apple.com/"]];
    [manager setResponseSerializer:[AFHTTPResponseSerializer serializer]];
    manager.securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate withPinnedCertificates:[NSSet setWithObject:googleCertificateData]];
    [manager
     GET:@"AFNetworking/AFNetworking"
     parameters:nil
     progress:nil
     success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
         XCTFail(@"Request should fail");
         [expectation fulfill];
     }
     failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
         XCTAssertEqualObjects(error.domain, NSURLErrorDomain);
         XCTAssertEqual(error.code, NSURLErrorServerCertificateUntrusted);
         [expectation fulfill];
     }];
    [self waitForExpectationsWithCommonTimeoutUsingHandler:nil];
    [manager invalidateSessionCancelingTasks:YES];
}

@end
