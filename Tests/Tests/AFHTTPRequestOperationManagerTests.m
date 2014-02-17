//
//  AFHTTPRequestOperationManagerTests.m
//  AFNetworking Tests
//
//  Created by Benjamin Coe on 2/17/14.
//  Copyright (c) 2014 AFNetworking. All rights reserved.
//

#import "AFTestCase.h"

#import "AFHTTPRequestOperationManager.h"

@interface AFHTTPRequestOperationManagerTests : AFTestCase
@end

@implementation AFHTTPRequestOperationManagerTests


#pragma mark - GET requests

- (void)testFailureOccursIfGETRequestTakesLongerThanTimeoutInterval {
	[Expecta setAsynchronousTestTimeout:2.0];

	__block id blockResponseObject = nil;
	__block id blockError = nil;

	AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
	
	AFHTTPRequestOperation *operation = [manager
		GET: [NSString stringWithFormat:@"%@/delay/10", [self.baseURL absoluteString]]
		parameters:nil
		timeoutInterval:0.1f
		success:^(AFHTTPRequestOperation *operation, id responseObject) {
			blockResponseObject = responseObject;
		}
		failure:^(AFHTTPRequestOperation *operation, NSError *error) {
			blockError = error;
		}
	];

	[operation start];

	expect(blockResponseObject).will.beNil();
	expect(blockError).willNot.beNil();
}

- (void)testGETRequestSucceedsIfWithinTimeoutInterval {
	[Expecta setAsynchronousTestTimeout:2.0];

	__block id blockResponseObject = nil;
	__block id blockError = nil;

	AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
	
	AFHTTPRequestOperation *operation = [manager
		GET: [NSString stringWithFormat:@"%@/get", [self.baseURL absoluteString]]
		parameters:nil
		success:^(AFHTTPRequestOperation *operation, id responseObject) {
			blockResponseObject = responseObject;
		}
		failure:^(AFHTTPRequestOperation *operation, NSError *error) {
			blockError = error;
		}
	];

	[operation start];

	expect(blockError).will.beNil();
	expect(blockResponseObject).willNot.beNil();
}

#pragma mark - HEAD requests

- (void)testFailureOccursIfHEADRequestTakesLongerThanTimeoutInterval {
	[Expecta setAsynchronousTestTimeout:2.0];

	__block id blockOperation = nil;
	__block id blockError = nil;

	AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
	
	AFHTTPRequestOperation *operation = [manager
		HEAD: [NSString stringWithFormat:@"%@/delay/10", [self.baseURL absoluteString]]
		parameters:nil
		timeoutInterval:0.1f
		success:^(AFHTTPRequestOperation *operation) {
			blockOperation = operation;
		}
		failure:^(AFHTTPRequestOperation *operation, NSError *error) {
			blockError = error;
		}
	];

	[operation start];

	expect(blockOperation).will.beNil();
	expect(blockError).willNot.beNil();
}

- (void)testHEADRequestSucceedsIfWithinTimeoutInterval {
	[Expecta setAsynchronousTestTimeout:2.0];

	__block id blockOperation = nil;
	__block id blockError = nil;

	AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
	
	AFHTTPRequestOperation *operation = [manager
		HEAD: [NSString stringWithFormat:@"%@/get", [self.baseURL absoluteString]]
		parameters:nil
		success:^(AFHTTPRequestOperation *operation) {
			blockOperation = operation;
		}
		failure:^(AFHTTPRequestOperation *operation, NSError *error) {
			blockError = error;
		}
	];

	[operation start];

	expect(blockOperation).willNot.beNil();
	expect(blockError).will.beNil();
}

#pragma mark - POST requests

- (void)testFailureOccursIfPOSTRequestTakesLongerThanTimeoutInterval {
	[Expecta setAsynchronousTestTimeout:2.0];

	__block id blockResponseObject = nil;
	__block id blockError = nil;

	AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
	
	AFHTTPRequestOperation *operation = [manager
		POST: [NSString stringWithFormat:@"%@/delay/10", [self.baseURL absoluteString]]
		parameters:nil
		timeoutInterval:0.1f
		success:^(AFHTTPRequestOperation *operation, id responseObject) {
			blockResponseObject = responseObject;
		}
		failure:^(AFHTTPRequestOperation *operation, NSError *error) {
			blockError = error;
		}
	];

	[operation start];

	expect(blockResponseObject).will.beNil();
	expect(blockError).willNot.beNil();
}

- (void)testPOSTRequestSucceedsIfWithinTimeoutInterval {
	[Expecta setAsynchronousTestTimeout:2.0];

	__block id blockResponseObject = nil;
	__block id blockError = nil;

	AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
	
	AFHTTPRequestOperation *operation = [manager
		POST: [NSString stringWithFormat:@"%@/post", [self.baseURL absoluteString]]
		parameters:nil
		success:^(AFHTTPRequestOperation *operation, id responseObject) {
			blockResponseObject = responseObject;
		}
		failure:^(AFHTTPRequestOperation *operation, NSError *error) {
			blockError = error;
		}
	];

	[operation start];

	expect(blockError).will.beNil();
	expect(blockResponseObject).willNot.beNil();
}

@end
