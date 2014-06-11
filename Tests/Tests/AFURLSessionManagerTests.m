// AFNetworkActivityManagerTests.m
//
// Copyright (c) 2013-2014 AFNetworking (http://afnetworking.com)
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

#import "AFURLSessionManager.h"

@interface AFURLSessionManagerTests : AFTestCase
@property (readwrite, nonatomic, strong) AFURLSessionManager *manager;
@end

@implementation AFURLSessionManagerTests

- (void)setUp {
    [super setUp];
    self.manager = [[AFURLSessionManager alloc] init];
}

#pragma mark -

- (void)testUploadTasksProgressBecomesPartOfCurrentProgress {
    NSProgress *overallProgress = [NSProgress progressWithTotalUnitCount:100];
    
    [overallProgress becomeCurrentWithPendingUnitCount:80];
    NSProgress *uploadProgress = nil;
    
    [self.manager downloadTaskWithRequest:[NSURLRequest requestWithURL:self.baseURL]
                                 progress:&uploadProgress
                              destination:nil
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
    
    [self.manager downloadTaskWithRequest:[NSURLRequest requestWithURL:self.baseURL]
                                 progress:&downloadProgress
                              destination:nil
                        completionHandler:nil];
    [overallProgress resignCurrent];
    
    expect(overallProgress.fractionCompleted).to.equal(0);
    
    downloadProgress.totalUnitCount = 1;
    downloadProgress.completedUnitCount = 1;
    
    
    expect(overallProgress.fractionCompleted).to.equal(0.8);
}

@end
