// AFNetworkActivityManagerTests.m
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

#import <objc/runtime.h>

#import "AFTestCase.h"

#import "AFURLSessionManager.h"

@interface AFURLSessionManagerTests : AFTestCase
@property (readwrite, nonatomic, strong) AFURLSessionManager *localManager;
@property (readwrite, nonatomic, strong) AFURLSessionManager *backgroundManager;
@end


@implementation AFURLSessionManagerTests

- (void)setUp {
    [super setUp];
    self.localManager = [[AFURLSessionManager alloc] init];
    
    //Unfortunately, iOS 7 throws an exception when trying to create a background URL Session inside this test target, which means our tests here can only run on iOS 8+
    //Travis actually needs the try catch here. Just doing if ([NSURLSessionConfiguration respondsToSelector:@selector(backgroundSessionWithIdentifier)]) wasn't good enough.
    @try {
        NSString *identifier = [NSString stringWithFormat:@"com.afnetworking.tests.urlsession.%@", [[NSUUID UUID] UUIDString]];
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:identifier];
        self.backgroundManager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    }
    @catch (NSException *exception) {

    }
}

- (void)tearDown {
    [super tearDown];
    [self.localManager invalidateSessionCancelingTasks:YES];
    self.localManager = nil;
    
    [self.backgroundManager invalidateSessionCancelingTasks:YES];
    self.backgroundManager = nil;
}

#pragma mark -

- (void)testUploadTasksProgressBecomesPartOfCurrentProgress {
    NSProgress *overallProgress = [NSProgress progressWithTotalUnitCount:100];

    [overallProgress becomeCurrentWithPendingUnitCount:80];
    NSProgress *uploadProgress = nil;

    [self.localManager uploadTaskWithRequest:[NSURLRequest requestWithURL:self.baseURL]
                               fromData:[NSData data]
                                 progress:&uploadProgress
                        completionHandler:nil];
    [overallProgress resignCurrent];

    expect(overallProgress.fractionCompleted).to.equal(0);

    uploadProgress.totalUnitCount = 1;
    uploadProgress.completedUnitCount = 1;


    expect(overallProgress.fractionCompleted).to.equal(0.8);
}

- (void)testDownloadTasksProgressBecomesPartOfCurrentProgress {
    NSProgress *overallProgress = [NSProgress progressWithTotalUnitCount:100];

    [overallProgress becomeCurrentWithPendingUnitCount:80];
    NSProgress *downloadProgress = nil;

    [self.localManager downloadTaskWithRequest:[NSURLRequest requestWithURL:self.baseURL]
                                 progress:&downloadProgress
                              destination:nil
                        completionHandler:nil];
    [overallProgress resignCurrent];

    expect(overallProgress.fractionCompleted).to.equal(0);

    downloadProgress.totalUnitCount = 1;
    downloadProgress.completedUnitCount = 1;


    expect(overallProgress.fractionCompleted).to.equal(0.8);
}

#pragma mark - Issue #2702 Tests
// The following tests are all releated to issue #2702

- (void)testDidResumeNotificationIsReceivedByLocalDataTaskAfterResume {
    NSURLSessionDataTask *task = [self.localManager dataTaskWithRequest:[self _delayURLRequest]
                                                 completionHandler:nil];
    [self _testResumeNotificationForTask:task];
}

- (void)testDidSuspendNotificationIsReceivedByLocalDataTaskAfterSuspend {
    NSURLSessionDataTask *task = [self.localManager dataTaskWithRequest:[self _delayURLRequest]
                                                 completionHandler:nil];
    [self _testSuspendNotificationForTask:task];
}

- (void)testDidResumeNotificationIsReceivedByBackgroundDataTaskAfterResume {
    if (self.backgroundManager) {
        NSURLSessionDataTask *task = [self.backgroundManager dataTaskWithRequest:[self _delayURLRequest]
                                                               completionHandler:nil];
        [self _testResumeNotificationForTask:task];
    }
}

- (void)testDidSuspendNotificationIsReceivedByBackgroundDataTaskAfterSuspend {
    if (self.backgroundManager) {
        NSURLSessionDataTask *task = [self.backgroundManager dataTaskWithRequest:[self _delayURLRequest]
                                                               completionHandler:nil];
        [self _testSuspendNotificationForTask:task];
    }
}

- (void)testDidResumeNotificationIsReceivedByLocalUploadTaskAfterResume {
    NSURLSessionUploadTask *task = [self.localManager uploadTaskWithRequest:[self _delayURLRequest]
                                                              fromData:[NSData data]
                                                              progress:nil
                                                     completionHandler:nil];
    [self _testResumeNotificationForTask:task];
}

- (void)testDidSuspendNotificationIsReceivedByLocalUploadTaskAfterSuspend {
    NSURLSessionUploadTask *task = [self.localManager uploadTaskWithRequest:[self _delayURLRequest]
                                                              fromData:[NSData data]
                                                              progress:nil
                                                     completionHandler:nil];
    [self _testSuspendNotificationForTask:task];
}

- (void)testDidResumeNotificationIsReceivedByBackgroundUploadTaskAfterResume {
    if (self.backgroundManager) {
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wnonnull"
        NSURLSessionUploadTask *task = [self.backgroundManager uploadTaskWithRequest:[self _delayURLRequest]
                                                                            fromFile:nil
                                                                            progress:nil
                                                                   completionHandler:nil];
#pragma clang diagnostic pop
        [self _testResumeNotificationForTask:task];
    }
}

- (void)testDidSuspendNotificationIsReceivedByBackgroundUploadTaskAfterSuspend {
    if (self.backgroundManager) {
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wnonnull"
        NSURLSessionUploadTask *task = [self.backgroundManager uploadTaskWithRequest:[self _delayURLRequest]
                                                                            fromFile:nil
                                                                            progress:nil
                                                                   completionHandler:nil];
#pragma clang diagnostic pop
        [self _testSuspendNotificationForTask:task];
    }
}

- (void)testDidResumeNotificationIsReceivedByLocalDownloadTaskAfterResume {
    NSURLSessionDownloadTask *task = [self.localManager downloadTaskWithRequest:[self _delayURLRequest]
                                                                progress:nil
                                                             destination:nil
                                                       completionHandler:nil];
    [self _testResumeNotificationForTask:task];
}

- (void)testDidSuspendNotificationIsReceivedByLocalDownloadTaskAfterSuspend {
    NSURLSessionDownloadTask *task = [self.localManager downloadTaskWithRequest:[self _delayURLRequest]
                                                                progress:nil
                                                             destination:nil
                                                       completionHandler:nil];
    [self _testSuspendNotificationForTask:task];
}

- (void)testDidResumeNotificationIsReceivedByBackgroundDownloadTaskAfterResume {
    if (self.backgroundManager) {
        NSURLSessionDownloadTask *task = [self.backgroundManager downloadTaskWithRequest:[self _delayURLRequest]
                                                                                progress:nil
                                                                             destination:nil
                                                                       completionHandler:nil];
        [self _testResumeNotificationForTask:task];
    }
}

- (void)testDidSuspendNotificationIsReceivedByBackgroundDownloadTaskAfterSuspend {
    if (self.backgroundManager) {
        NSURLSessionDownloadTask *task = [self.backgroundManager downloadTaskWithRequest:[self _delayURLRequest]
                                                                                progress:nil
                                                                             destination:nil
                                                                       completionHandler:nil];
        [self _testSuspendNotificationForTask:task];
    }
}

- (void)testSwizzlingIsProperlyConfiguredForDummyClass {
    IMP originalAFResumeIMP = [self _originalAFResumeImplementation];
    IMP originalAFSuspendIMP = [self _originalAFSuspendImplementation];
    XCTAssert(originalAFResumeIMP, @"Swizzled af_resume Method Not Found");
    XCTAssert(originalAFSuspendIMP, @"Swizzled af_suspend Method Not Found");
    XCTAssertNotEqual(originalAFResumeIMP, originalAFSuspendIMP, @"af_resume and af_suspend should not be equal");
}

- (void)testSwizzlingIsWorkingAsExpectedForForegroundDataTask {
    NSURLSessionTask *task = [self.localManager dataTaskWithRequest:[self _delayURLRequest]
                                             completionHandler:nil];
    [self _testSwizzlingForTask:task];
    [task cancel];
}

- (void)testSwizzlingIsWorkingAsExpectedForForegroundUpload {
    NSURLSessionTask *task = [self.localManager uploadTaskWithRequest:[self _delayURLRequest]
                                                        fromData:[NSData data]
                                                        progress:nil
                                               completionHandler:nil];
    [self _testSwizzlingForTask:task];
    [task cancel];
}

- (void)testSwizzlingIsWorkingAsExpectedForForegroundDownload {
    NSURLSessionTask *task = [self.localManager downloadTaskWithRequest:[self _delayURLRequest]
                                                          progress:nil
                                                       destination:nil
                                                 completionHandler:nil];
    [self _testSwizzlingForTask:task];
    [task cancel];
}

- (void)testSwizzlingIsWorkingAsExpectedForBackgroundDataTask {
    //iOS 7 doesn't let us use a background manager in these tests, so reference these
    //classes directly. There are tests below to confirm background manager continues
    //to return the exepcted classes going forward. If those fail in a future iOS version,
    //it should point us to a problem here.
    [self _testSwizzlingForTaskClass:NSClassFromString(@"__NSCFBackgroundDataTask")];
}

- (void)testSwizzlingIsWorkingAsExpectedForBackgroundUploadTask {
    //iOS 7 doesn't let us use a background manager in these tests, so reference these
    //classes directly. There are tests below to confirm background manager continues
    //to return the exepcted classes going forward. If those fail in a future iOS version,
    //it should point us to a problem here.
    [self _testSwizzlingForTaskClass:NSClassFromString(@"__NSCFBackgroundUploadTask")];
}

- (void)testSwizzlingIsWorkingAsExpectedForBackgroundDownloadTask {
    //iOS 7 doesn't let us use a background manager in these tests, so reference these
    //classes directly. There are tests below to confirm background manager continues
    //to return the exepcted classes going forward. If those fail in a future iOS version,
    //it should point us to a problem here.
    [self _testSwizzlingForTaskClass:NSClassFromString(@"__NSCFBackgroundDownloadTask")];
}

- (void)testBackgroundManagerReturnsExpectedClassForDataTask {
    if (self.backgroundManager) {
        NSURLSessionTask *task = [self.backgroundManager dataTaskWithRequest:[self _delayURLRequest]
                                                           completionHandler:nil];
        XCTAssert([NSStringFromClass([task class]) isEqualToString:@"__NSCFBackgroundDataTask"]);
    } else {
        NSLog(@"Unable to run %@ because self.backgroundManager is nil", NSStringFromSelector(_cmd));
    }
}

- (void)testBackgroundManagerReturnsExpectedClassForUploadTask {
    if (self.backgroundManager) {
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wnonnull"
        NSURLSessionTask *task = [self.backgroundManager uploadTaskWithRequest:[self _delayURLRequest]
                                                                      fromFile:nil
                                                                      progress:nil
                                                             completionHandler:nil];
#pragma clang diagnostic pop
        XCTAssert([NSStringFromClass([task class]) isEqualToString:@"__NSCFBackgroundUploadTask"]);
    } else {
        NSLog(@"Unable to run %@ because self.backgroundManager is nil", NSStringFromSelector(_cmd));
    }
}

- (void)testBackgroundManagerReturnsExpectedClassForDownloadTask {
    if (self.backgroundManager) {
        NSURLSessionTask *task = [self.backgroundManager downloadTaskWithRequest:[self _delayURLRequest]
                                                                        progress:nil
                                                                     destination:nil
                                                               completionHandler:nil];
        XCTAssert([NSStringFromClass([task class]) isEqualToString:@"__NSCFBackgroundDownloadTask"]);
    } else {
        NSLog(@"Unable to run %@ because self.backgroundManager is nil", NSStringFromSelector(_cmd));
    }
}

#pragma mark - private

- (void)_testResumeNotificationForTask:(NSURLSessionTask *)task {
    [self expectationForNotification:AFNetworkingTaskDidResumeNotification
                              object:nil
                             handler:nil];
    [task resume];
    [task suspend];
    [task resume];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    [task cancel];
}

- (void)_testSuspendNotificationForTask:(NSURLSessionTask *)task {
    [self expectationForNotification:AFNetworkingTaskDidSuspendNotification
                              object:nil
                             handler:nil];
    [task resume];
    [task suspend];
    [task resume];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    [task cancel];
}

- (NSURLRequest *)_delayURLRequest {
    return [NSURLRequest requestWithURL:[self.baseURL URLByAppendingPathComponent:@"delay/1"]];
}

- (IMP)_implementationForTask:(NSURLSessionTask  *)task selector:(SEL)selector {
    return [self _implementationForClass:[task class] selector:selector];
}

- (IMP)_implementationForClass:(Class)class selector:(SEL)selector {
    return method_getImplementation(class_getInstanceMethod(class, selector));
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
- (IMP)_originalAFResumeImplementation {
    return method_getImplementation(class_getInstanceMethod(NSClassFromString(@"_AFURLSessionTaskSwizzling"), @selector(af_resume)));
}

- (IMP)_originalAFSuspendImplementation {
    return method_getImplementation(class_getInstanceMethod(NSClassFromString(@"_AFURLSessionTaskSwizzling"), @selector(af_suspend)));
}

- (void)_testSwizzlingForTask:(NSURLSessionTask *)task {
    [self _testSwizzlingForTaskClass:[task class]];
}

- (void)_testSwizzlingForTaskClass:(Class)class {
    IMP originalAFResumeIMP = [self _originalAFResumeImplementation];
    IMP originalAFSuspendIMP = [self _originalAFSuspendImplementation];
    
    IMP taskResumeImp = [self _implementationForClass:class selector:@selector(resume)];
    IMP taskSuspendImp = [self _implementationForClass:class selector:@selector(suspend)];
    XCTAssertEqual(originalAFResumeIMP, taskResumeImp, @"resume has not been properly swizzled for %@", NSStringFromClass(class));
    XCTAssertEqual(originalAFSuspendIMP, taskSuspendImp, @"suspend has not been properly swizzled for %@", NSStringFromClass(class));
    
    IMP taskAFResumeImp = [self _implementationForClass:class selector:@selector(af_resume)];
    IMP taskAFSuspendImp = [self _implementationForClass:class selector:@selector(af_suspend)];
    XCTAssert(taskAFResumeImp != NULL, @"af_resume is nil. Something has not been been swizzled right for %@", NSStringFromClass(class));
    XCTAssertNotEqual(taskAFResumeImp, taskResumeImp, @"af_resume has not been properly swizzled for %@", NSStringFromClass(class));
    XCTAssert(taskAFSuspendImp != NULL, @"af_suspend is nil. Something has not been been swizzled right for %@", NSStringFromClass(class));
    XCTAssertNotEqual(taskAFSuspendImp, taskSuspendImp, @"af_suspend has not been properly swizzled for %@", NSStringFromClass(class));
}
#pragma clang diagnostic pop

@end
