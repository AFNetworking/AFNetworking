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
@property (readwrite, nonatomic, strong) AFHTTPSessionManager *sessionManager;
@end

@interface AFURLSessionManager (Testing)

- (nonnull NSError *)serverTrustErrorForServerTrust:(SecTrustRef)serverTrust url:(NSURL *)url;

@end

@implementation AFHTTPSessionManagerTests

- (void)setUp {
    [super setUp];
    self.sessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:self.baseURL];
}

- (void)tearDown {
    [self.sessionManager invalidateSessionCancelingTasks:YES resetSession:NO];
    self.sessionManager = nil;
    [super tearDown];
}

#pragma mark - init
- (void)testSharedManagerIsNotEqualToInitedManager {
    XCTAssertFalse([[AFHTTPSessionManager manager] isEqual:self.sessionManager]);
}

#pragma mark - misc

- (void)testThatOperationInvokesCompletionHandlerWithResponseObjectOnSuccess {
    __block id blockResponseObject = nil;
    __block id blockError = nil;

    XCTestExpectation *expectation = [self expectationWithDescription:@"Request should succeed"];

    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/get" relativeToURL:self.baseURL]];
    NSURLSessionDataTask *task = [self.sessionManager dataTaskWithRequest:request uploadProgress:nil downloadProgress:nil
                                                 completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
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
    NSURLSessionDataTask *task = [self.sessionManager dataTaskWithRequest:request uploadProgress:nil downloadProgress:nil
                                                 completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
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

    NSURLRequest *redirectRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://httpbingo.org/redirect/1"]];
    NSURLSessionDataTask *redirectTask = [self.sessionManager dataTaskWithRequest:redirectRequest uploadProgress:nil downloadProgress:nil
                                                         completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
        blockError = error;
        [expectation fulfill];
    }];

    [self.sessionManager setTaskWillPerformHTTPRedirectionBlock:^NSURLRequest *(NSURLSession *session, NSURLSessionTask *task, NSURLResponse *response, NSURLRequest *request) {
        if (response) {
            success = YES;
        }

        return request;
    }];

    [redirectTask resume];

    [self waitForExpectationsWithTimeout:10.0 handler:nil];

    XCTAssertTrue(redirectTask.state == NSURLSessionTaskStateCompleted);
    XCTAssertNil(blockError);
    XCTAssertTrue(success);
}

- (void)testDownloadFileCompletionSpecifiesURLInCompletionWithManagerDidFinishBlock {
    __block BOOL managerDownloadFinishedBlockExecuted = NO;
    __block BOOL completionBlockExecuted = NO;
    __block NSURL *downloadFilePath = nil;
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request should succeed"];

    [self.sessionManager setDownloadTaskDidFinishDownloadingBlock:^NSURL *(NSURLSession *session, NSURLSessionDownloadTask *downloadTask, NSURL *location) {
        managerDownloadFinishedBlockExecuted = YES;
        NSURL *dirURL  = [[[NSFileManager defaultManager] URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask] lastObject];
        return [dirURL URLByAppendingPathComponent:@"t1.file"];
    }];

    NSURLSessionDownloadTask *downloadTask;
    downloadTask = [self.sessionManager
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

    NSURLSessionDownloadTask *downloadTask = [self.sessionManager downloadTaskWithRequest:[NSURLRequest requestWithURL:self.baseURL]
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

    [self.sessionManager.requestSerializer setQueryStringSerializationWithBlock:^NSString * _Nonnull(NSURLRequest * _Nonnull request, id  _Nonnull parameters, NSError * _Nullable __autoreleasing * _Nullable error) {
        if (error != NULL) {
            *error = [NSError errorWithDomain:@"Custom" code:-1 userInfo:nil];
        }
        return @"";
    }];

    NSURLSessionTask *nilTask;
    nilTask = [self.sessionManager
               GET:@"test"
               parameters:@{@"key":@"value"}
               headers:nil
               progress:nil
               success:nil
               failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                   XCTAssertNil(task);
                   [expectation fulfill];
               }];
    XCTAssertNil(nilTask);
    [self waitForExpectationsWithTimeout:10.0 handler:nil];
}

- (void)testSettingHTTPHeadersPerRequestCanReplaceTheDefaultValueSpecifiedInRequestSerializer {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request should succeed"];

    [self.sessionManager.requestSerializer setValue:@"foo value"
                                 forHTTPHeaderField:@"X-Foo"];
    [self.sessionManager.requestSerializer setValue:@"bar value"
                                 forHTTPHeaderField:@"X-Bar"];

    NSURLSessionDataTask *testTask =
        [self.sessionManager dataTaskWithHTTPMethod:@"GET"
                                          URLString:@"get"
                                         parameters:nil
                                            headers:@{ @"X-Foo": @"request value" }
                                     uploadProgress:nil
                                   downloadProgress:nil
                                            success:^(NSURLSessionDataTask * _Nonnull task, id _Nullable responseObject) {
        XCTAssertTrue([task.originalRequest.allHTTPHeaderFields[@"X-Foo"] isEqualToString:@"request value"]);
        XCTAssertTrue([task.originalRequest.allHTTPHeaderFields[@"X-Bar"] isEqualToString:@"bar value"]);
        [expectation fulfill];
    }
                                            failure:nil];

    [testTask resume];

    [self waitForExpectationsWithCommonTimeout];
}

#pragma mark - NSCoding

- (void)testSupportsSecureCoding {
    XCTAssertTrue([AFHTTPSessionManager supportsSecureCoding]);
}

- (void)testCanBeEncoded {
    NSData *data = [self archivedDataWithRootObject:self.sessionManager];
    XCTAssertNotNil(data);
}

- (void)testCanBeDecoded {
    NSData *data = [self archivedDataWithRootObject:self.sessionManager];
    AFHTTPSessionManager *newManager = [self unarchivedObjectOfClass:[AFHTTPSessionManager class] fromData:data];;
    XCTAssertNotNil(newManager.securityPolicy);
    XCTAssertNotNil(newManager.requestSerializer);
    XCTAssertNotNil(newManager.responseSerializer);
    XCTAssertNotNil(newManager.baseURL);
    XCTAssertNotNil(newManager.session);
    XCTAssertNotNil(newManager.session.configuration);
}

#pragma mark - NSCopying 

- (void)testCanBeCopied {
    AFHTTPSessionManager *copyManager = [self.sessionManager copy];
    XCTAssertNotNil(copyManager);
}

#pragma mark - Progress

- (void)testDownloadProgressIsReportedForGET {
    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"Progress Should equal 1.0"];
    [self.sessionManager
     GET:@"image"
     parameters:nil
     headers:nil
     progress:^(NSProgress * _Nonnull downloadProgress) {
         if (downloadProgress.fractionCompleted == 1.0) {
             [expectation fulfill];
         }
     }
     success:nil
     failure:nil];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)testUploadProgressIsReportedForPOST {
    NSMutableString *payload = [NSMutableString stringWithString:@"AFNetworking"];
    while ([payload lengthOfBytesUsingEncoding:NSUTF8StringEncoding] < 20000) {
        [payload appendString:@"AFNetworking"];
    }

    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"Progress Should equal 1.0"];

    [self.sessionManager
     POST:@"post"
     parameters:payload
     headers:nil
     progress:^(NSProgress * _Nonnull uploadProgress) {
         if (uploadProgress.fractionCompleted == 1.0) {
             [expectation fulfill];
         }
     }
     success:nil
     failure:nil];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)testUploadProgressIsReportedForStreamingPost {
    NSMutableString *payload = [NSMutableString stringWithString:@"AFNetworking"];
    while ([payload lengthOfBytesUsingEncoding:NSUTF8StringEncoding] < 20000) {
        [payload appendString:@"AFNetworking"];
    }

    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"Progress Should equal 1.0"];

    [self.sessionManager
     POST:@"post"
     parameters:nil
     headers:nil
     constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
         [formData appendPartWithFileData:[payload dataUsingEncoding:NSUTF8StringEncoding] name:@"AFNetworking" fileName:@"AFNetworking" mimeType:@"text/html"];
     }
     progress:^(NSProgress * _Nonnull uploadProgress) {
         if (uploadProgress.fractionCompleted == 1.0) {
             [expectation fulfill];
         }
     }
     success:nil
     failure:nil];
    [self waitForExpectationsWithCommonTimeout];
}

# pragma mark - HTTP Status Codes

- (void)testThatSuccessBlockIsCalledFor200 {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request should succeed"];
    [self.sessionManager
     GET:@"status/200"
     parameters:nil
     headers:nil
     progress:nil
     success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
         [expectation fulfill];
     }
     failure:nil];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)testThatFailureBlockIsCalledFor404 {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request should succeed"];
    [self.sessionManager
     GET:@"status/404"
     parameters:nil
     headers:nil
     progress:nil
     success:nil
     failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nullable error) {
         [expectation fulfill];
     }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)testThatResponseObjectIsEmptyFor204 {
    __block id urlResponseObject = nil;
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request should succeed"];
    [self.sessionManager
     GET:@"status/204"
     parameters:nil
     headers:nil
     progress:nil
     success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
         urlResponseObject = responseObject;
         [expectation fulfill];
     }
     failure:nil];
    [self waitForExpectationsWithCommonTimeout];
    XCTAssertNil(urlResponseObject);
}

#pragma mark - Rest Interface 

- (void)testGET {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request should succeed"];
    [self.sessionManager
     GET:@"get"
     parameters:nil
     headers:nil
     progress:nil
     success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
         XCTAssertNotNil(responseObject);
         [expectation fulfill];
     }
     failure:nil];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)testHEAD {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request should succeed"];
    [self.sessionManager
     HEAD:@"get"
     parameters:nil
     headers:nil
     success:^(NSURLSessionDataTask * _Nonnull task) {
         XCTAssertNotNil(task);
         [expectation fulfill];
     }
     failure:nil];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)testPOST {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request should succeed"];
    [self.sessionManager.requestSerializer setValue:@"default value"
                                 forHTTPHeaderField:@"field"];
    [self.sessionManager
     POST:@"post"
     parameters:@{@"key":@"value"}
     headers:@{@"field":@"value"}
     progress:nil
     success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
         XCTAssertTrue([task.originalRequest.allHTTPHeaderFields[@"field"] isEqualToString:@"value"]);
         XCTAssertTrue([responseObject[@"form"][@"key"] isEqualToString:@"value"]);
         [expectation fulfill];
     }
     failure:nil];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)testPOSTWithConstructingBody {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request should succeed"];
    [self.sessionManager.requestSerializer setValue:@"default value"
                                 forHTTPHeaderField:@"field"];
    [self.sessionManager
     POST:@"post"
     parameters:@{@"key":@"value"}
     headers:@{@"field":@"value"}
     constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
         [formData appendPartWithFileData:[@"Data" dataUsingEncoding:NSUTF8StringEncoding]
                                     name:@"DataName"
                                 fileName:@"DataFileName"
                                 mimeType:@"data"];
     }
     progress:nil
     success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
         XCTAssertTrue([task.originalRequest.allHTTPHeaderFields[@"field"] isEqualToString:@"value"]);
         XCTAssertTrue([responseObject[@"files"][@"DataName"] isEqualToString:@"Data"]);
         XCTAssertTrue([responseObject[@"form"][@"key"] isEqualToString:@"value"]);
         [expectation fulfill];
     }
     failure:nil];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)testPUT {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request should succeed"];
    [self.sessionManager.requestSerializer setValue:@"default value"
                                 forHTTPHeaderField:@"field"];
    [self.sessionManager
     PUT:@"put"
     parameters:@{@"key":@"value"}
     headers:@{@"field":@"value"}
     success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
         XCTAssertTrue([task.originalRequest.allHTTPHeaderFields[@"field"] isEqualToString:@"value"]);
         XCTAssertTrue([responseObject[@"form"][@"key"] isEqualToString:@"value"]);
         [expectation fulfill];
     }
     failure:nil];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)testDELETE {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request should succeed"];
    [self.sessionManager.requestSerializer setValue:@"default value"
                                 forHTTPHeaderField:@"field"];
    [self.sessionManager
     DELETE:@"delete"
     parameters:@{@"key":@"value"}
     headers:@{@"field":@"value"}
     success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
         XCTAssertTrue([task.originalRequest.allHTTPHeaderFields[@"field"] isEqualToString:@"value"]);
         XCTAssertTrue([responseObject[@"args"][@"key"] isEqualToString:@"value"]);
         [expectation fulfill];
     }
     failure:nil];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)testPATCH {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request should succeed"];
    [self.sessionManager.requestSerializer setValue:@"default value"
                                 forHTTPHeaderField:@"field"];
    [self.sessionManager
     PATCH:@"patch"
     parameters:@{@"key":@"value"}
     headers:@{@"field":@"value"}
     success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
         XCTAssertTrue([task.originalRequest.allHTTPHeaderFields[@"field"] isEqualToString:@"value"]);
         XCTAssertTrue([responseObject[@"form"][@"key"] isEqualToString:@"value"]);
         [expectation fulfill];
     }
     failure:nil];

    [self waitForExpectationsWithCommonTimeout];
}

#pragma mark - Auth

- (void)testHiddenBasicAuthentication {
    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"Request should finish"];
    [self.sessionManager.requestSerializer setAuthorizationHeaderFieldWithUsername:@"user" password:@"password"];
    [self.sessionManager
     GET:@"hidden-basic-auth/user/password"
     parameters:nil
     headers:nil
     progress:nil
     success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
         [expectation fulfill];
     } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
         XCTFail(@"Request should succeed");
         [expectation fulfill];
     }];
    [self waitForExpectationsWithCommonTimeout];
}

# pragma mark - Security Policy

- (void)testValidSecureNoPinningSecurityPolicy {
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:@"https://example.com"]];
    AFSecurityPolicy *securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
    XCTAssertNoThrow(manager.securityPolicy = securityPolicy);
}

- (void)testValidInsecureNoPinningSecurityPolicy {
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:@"http://example.com"]];
    AFSecurityPolicy *securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
    XCTAssertNoThrow(manager.securityPolicy = securityPolicy);
}

- (void)testValidCertificatePinningSecurityPolicy {
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:@"https://example.com"]];
    AFSecurityPolicy *securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
    XCTAssertNoThrow(manager.securityPolicy = securityPolicy);
}

- (void)testInvalidCertificatePinningSecurityPolicy {
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:@"http://example.com"]];
    AFSecurityPolicy *securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
    XCTAssertThrowsSpecificNamed(manager.securityPolicy = securityPolicy, NSException, @"Invalid Security Policy");
}

- (void)testValidPublicKeyPinningSecurityPolicy {
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:@"https://example.com"]];
    AFSecurityPolicy *securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModePublicKey];
    XCTAssertNoThrow(manager.securityPolicy = securityPolicy);
}

- (void)testInvalidPublicKeyPinningSecurityPolicy {
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:@"http://example.com"]];
    AFSecurityPolicy *securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModePublicKey];
    XCTAssertThrowsSpecificNamed(manager.securityPolicy = securityPolicy, NSException, @"Invalid Security Policy");
}

- (void)testInvalidCertificatePinningSecurityPolicyWithoutBaseURL {
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] init];
    AFSecurityPolicy *securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
    XCTAssertThrowsSpecificNamed(manager.securityPolicy = securityPolicy, NSException, @"Invalid Security Policy");
}

- (void)testInvalidPublicKeyPinningSecurityPolicyWithoutBaseURL {
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] init];
    AFSecurityPolicy *securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModePublicKey];
    XCTAssertThrowsSpecificNamed(manager.securityPolicy = securityPolicy, NSException, @"Invalid Security Policy");
}

# pragma mark - Server Trust

- (void)testInvalidServerTrustProducesCorrectErrorForCertificatePinning {
    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"Request should fail with untrusted certificate error"];
    NSURL *googleCertificateURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"google.com" withExtension:@"cer"];
    NSData *googleCertificateData = [NSData dataWithContentsOfURL:googleCertificateURL];
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:@"https://apple.com/"]];
    [manager setResponseSerializer:[AFHTTPResponseSerializer serializer]];
    manager.securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate withPinnedCertificates:[NSSet setWithObject:googleCertificateData]];
    [manager
     GET:@""
     parameters:nil
     headers:nil
     progress:nil
     success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
         XCTFail(@"Request should fail");
         [expectation fulfill];
     }
     failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
         XCTAssertEqualObjects(error.domain, NSURLErrorDomain);
         XCTAssertEqual(error.code, NSURLErrorServerCertificateUntrusted);
         XCTAssertEqualObjects(error.localizedDescription, @"The certificate for this server is invalid. You might be connecting to a server that is pretending to be “apple.com” which could put your confidential information at risk.");
         [expectation fulfill];
     }];
    [self waitForExpectationsWithCommonTimeout];
    [manager invalidateSessionCancelingTasks:YES resetSession:NO];
}

- (void)testInvalidServerTrustProducesCorrectErrorForPublicKeyPinning {
    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"Request should fail with untrusted certificate error"];
    NSURL *googleCertificateURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"google.com" withExtension:@"cer"];
    NSData *googleCertificateData = [NSData dataWithContentsOfURL:googleCertificateURL];
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:@"https://apple.com/"]];
    [manager setResponseSerializer:[AFHTTPResponseSerializer serializer]];
    manager.securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModePublicKey withPinnedCertificates:[NSSet setWithObject:googleCertificateData]];
    [manager
     GET:@""
     parameters:nil
     headers:nil
     progress:nil
     success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
         XCTFail(@"Request should fail");
         [expectation fulfill];
     }
     failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
         XCTAssertEqualObjects(error.domain, NSURLErrorDomain);
         XCTAssertEqual(error.code, NSURLErrorServerCertificateUntrusted);
         XCTAssertEqualObjects(error.localizedDescription, @"The certificate for this server is invalid. You might be connecting to a server that is pretending to be “apple.com” which could put your confidential information at risk.");
         [expectation fulfill];
     }];
    [self waitForExpectationsWithCommonTimeout];
    [manager invalidateSessionCancelingTasks:YES resetSession:NO];
}

# pragma mark - Custom Authentication Challenge Handler

- (void)testAuthenticationChallengeHandlerCredentialResult {
    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"Request succeed with provided credentials"];
    self.sessionManager.responseSerializer = [AFHTTPResponseSerializer serializer];
    [self.sessionManager setAuthenticationChallengeHandler:^id _Nonnull(NSURLSession * _Nonnull session, NSURLSessionTask * _Nonnull task, NSURLAuthenticationChallenge * _Nonnull challenge, void (^ _Nonnull completionHandler)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable)) {
        if ([challenge.protectionSpace.realm isEqualToString:@"Fake Realm"]) {
            return [NSURLCredential credentialWithUser:@"user" password:@"passwd" persistence:NSURLCredentialPersistenceNone];
        }
        return @(NSURLSessionAuthChallengePerformDefaultHandling);
    }];
    [self.sessionManager
     GET:@"basic-auth/user/passwd"
     parameters:nil
     headers:nil
     progress:nil
     success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
         [expectation fulfill];
     }
     failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
         XCTFail(@"Request should succeed");
         [expectation fulfill];
     }];
    [self waitForExpectationsWithCommonTimeoutUsingHandler:nil];
}

- (void)testThatServerTrustErrorIsCreatedWithProperUserInfoWithAllParameters {
    NSURL *url = [NSURL URLWithString:@"https://httpbin.org/get"];
    SecTrustRef trust = AFUTTrustChainForCertsInDirectory([[[NSBundle bundleForClass:[self class]] resourcePath]
                                                           stringByAppendingPathComponent:@"HTTPBinOrgServerTrustChain"]);
    NSError *error = [self.sessionManager serverTrustErrorForServerTrust:trust url:url];

    XCTAssertNotNil(error);
    XCTAssertNotNil(error.userInfo[NSURLErrorFailingURLPeerTrustErrorKey]);
    XCTAssertEqual(error.userInfo[NSURLErrorFailingURLErrorKey], url);
    XCTAssertEqual(error.userInfo[NSURLErrorFailingURLStringErrorKey], url.absoluteString);
}

- (void)testThatServerTrustErrorIsCreatedWithProperUserInfoWhenTrustIsNil {
    NSURL *url = [NSURL URLWithString:@"https://httpbin.org/get"];
    NSError *error = [self.sessionManager serverTrustErrorForServerTrust:nil url:url];

    XCTAssertNotNil(error);
    XCTAssertNil(error.userInfo[NSURLErrorFailingURLPeerTrustErrorKey]);
    XCTAssertEqual(error.userInfo[NSURLErrorFailingURLErrorKey], url);
    XCTAssertEqual(error.userInfo[NSURLErrorFailingURLStringErrorKey], url.absoluteString);
}

- (void)testThatServerTrustErrorIsCreatedWithProperUserInfoWhenURLIsNil {
    SecTrustRef trust = AFUTTrustChainForCertsInDirectory([[[NSBundle bundleForClass:[self class]] resourcePath]
                                                           stringByAppendingPathComponent:@"HTTPBinOrgServerTrustChain"]);
    NSError *error = [self.sessionManager serverTrustErrorForServerTrust:trust url:nil];

    XCTAssertNotNil(error);
    XCTAssertNotNil(error.userInfo[NSURLErrorFailingURLPeerTrustErrorKey]);
    XCTAssertNil(error.userInfo[NSURLErrorFailingURLErrorKey]);
    XCTAssertNil(error.userInfo[NSURLErrorFailingURLStringErrorKey]);
}

- (void)testThatServerTrustErrorIsCreatedWithProperUserInfoAllParametersAreNil {
    NSError *error = [self.sessionManager serverTrustErrorForServerTrust:nil url:nil];

    XCTAssertNotNil(error);
    XCTAssertNil(error.userInfo[NSURLErrorFailingURLPeerTrustErrorKey]);
    XCTAssertNil(error.userInfo[NSURLErrorFailingURLErrorKey]);
    XCTAssertNil(error.userInfo[NSURLErrorFailingURLStringErrorKey]);
}

@end
