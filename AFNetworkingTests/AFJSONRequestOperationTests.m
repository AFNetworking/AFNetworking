//
//  AFJSONRequestOperationTests.m
//  AFNetworking
//
//  Created by Andy Mroczkowski on 2/11/13.
//  Copyright (c) 2013 AFNetworking. All rights reserved.
//

#import "AFJSONRequestOperationTests.h"
#import "AFJSONRequestOperation.h"

@implementation AFJSONRequestOperationTests

- (void)testCanProcessRequestTrueIfExtensionIsJSON
{
    NSURL *url = [NSURL URLWithString:@"http://test.com/pie.json"];
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url];
    BOOL const canProcess = [AFJSONRequestOperation canProcessRequest:urlRequest];;
    STAssertTrue(canProcess, @"should be able to process URL: %@", url);
}

- (void)testCanProcessRequestTrueIfExtensionIsJS
{
    NSURL *url = [NSURL URLWithString:@"http://test.com/pie.js"];
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url];
    BOOL const canProcess = [AFJSONRequestOperation canProcessRequest:urlRequest];;
    STAssertFalse(canProcess, @"should not be able to process URL: %@", url);
}

@end
