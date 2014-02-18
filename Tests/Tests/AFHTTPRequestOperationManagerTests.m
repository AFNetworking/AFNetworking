// AFHTTPRequestOperationTests.m
//
// Copyright (c) 2014 AFNetworking (http://afnetworking.com)
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

- (void)testFailureOccursIfMultipartPOSTRequestTakesLongerThanTimeoutInterval {
	[Expecta setAsynchronousTestTimeout:2.0];

	__block id blockResponseObject = nil;
	__block id blockError = nil;

	AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
	
	AFHTTPRequestOperation *operation = [manager
		POST: [NSString stringWithFormat:@"%@/delay/10", [self.baseURL absoluteString]]
		parameters:nil
		timeoutInterval:0.1f
		constructingBodyWithBlock: nil
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

- (void)testMultipartPOSTRequestSucceedsIfWithinTimeoutInterval {
	[Expecta setAsynchronousTestTimeout:2.0];

	__block id blockResponseObject = nil;
	__block id blockError = nil;

	AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
	
	AFHTTPRequestOperation *operation = [manager
		POST: [NSString stringWithFormat:@"%@/post", [self.baseURL absoluteString]]
		parameters:nil
		constructingBodyWithBlock: nil
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

#pragma mark - PUT requests

- (void)testFailureOccursIfPUTRequestTakesLongerThanTimeoutInterval {
	[Expecta setAsynchronousTestTimeout:2.0];

	__block id blockResponseObject = nil;
	__block id blockError = nil;

	AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
	
	AFHTTPRequestOperation *operation = [manager
		PUT: [NSString stringWithFormat:@"%@/delay/10", [self.baseURL absoluteString]]
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

- (void)testPUTRequestSucceedsIfWithinTimeoutInterval {
	[Expecta setAsynchronousTestTimeout:2.0];

	__block id blockResponseObject = nil;
	__block id blockError = nil;

	AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
	
	AFHTTPRequestOperation *operation = [manager
		PUT: [NSString stringWithFormat:@"%@/put", [self.baseURL absoluteString]]
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

#pragma mark - PATCH requests

- (void)testFailureOccursIfPATCHRequestTakesLongerThanTimeoutInterval {
	[Expecta setAsynchronousTestTimeout:2.0];

	__block id blockResponseObject = nil;
	__block id blockError = nil;

	AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
	
	AFHTTPRequestOperation *operation = [manager
		PATCH: [NSString stringWithFormat:@"%@/delay/10", [self.baseURL absoluteString]]
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

- (void)testPATCHRequestSucceedsIfWithinTimeoutInterval {
	[Expecta setAsynchronousTestTimeout:2.0];

	__block id blockResponseObject = nil;
	__block id blockError = nil;

	AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
	
	AFHTTPRequestOperation *operation = [manager
		PATCH: [NSString stringWithFormat:@"%@/patch", [self.baseURL absoluteString]]
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

#pragma mark - DELETE requests

- (void)testFailureOccursIfDELETERequestTakesLongerThanTimeoutInterval {
	[Expecta setAsynchronousTestTimeout:2.0];

	__block id blockResponseObject = nil;
	__block id blockError = nil;

	AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
	
	AFHTTPRequestOperation *operation = [manager
		DELETE: [NSString stringWithFormat:@"%@/delay/10", [self.baseURL absoluteString]]
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

- (void)testDELETERequestSucceedsIfWithinTimeoutInterval {
	[Expecta setAsynchronousTestTimeout:2.0];

	__block id blockResponseObject = nil;
	__block id blockError = nil;

	AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
	
	AFHTTPRequestOperation *operation = [manager
		DELETE: [NSString stringWithFormat:@"%@/delete", [self.baseURL absoluteString]]
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
