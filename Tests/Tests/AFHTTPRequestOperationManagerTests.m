//
//  AFHTTPRequestOperationManagerTests.m
//  AFNetworking Tests
//
//  Created by Yavuz Nuzumlali on 13/09/15.
//  Copyright © 2015 AFNetworking. All rights reserved.
//

#import <OHHTTPStubs/OHHTTPStubs.h>
#import "AFHTTPRequestOperationManager.h"
#import "AFTestCase.h"

@interface AFHTTPRequestOperationManagerTests : AFTestCase

@property (nonatomic, strong) AFHTTPRequestOperationManager *requestManager;
@end

@implementation AFHTTPRequestOperationManagerTests

- (void)setUp {
    [super setUp];
	[Expecta setAsynchronousTestTimeout:10.0];

	[OHHTTPStubs removeAllStubs];
	self.requestManager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:self.baseURL];
	self.requestManager.requestSerializer = [AFJSONRequestSerializer serializer];
	self.requestManager.responseSerializer = [AFJSONResponseSerializer serializer];
}

- (void)tearDown {
    [super tearDown];
	[OHHTTPStubs removeAllStubs];
	[Expecta setAsynchronousTestTimeout:5.0];
}

- (BOOL)isArraySorted:(NSArray*)array {
	for (int i = 0; i < array.count - 2; i++) {
		if ([array[i] integerValue] > [array[i+1] integerValue]) {
			NSString *arrayStr = [[array subarrayWithRange:NSMakeRange(0, i+1)] componentsJoinedByString:@","];
			@throw [NSException exceptionWithName:[NSString stringWithFormat:@"Order is corrupted. Subarray : %@", arrayStr] reason:@"" userInfo:nil];
		}
	}
	return YES;
}

- (void)testThatUsingDefaultCompletionProcessingQueueWillCauseToLoseOrder {
	// Stub all requests and return a response containing all HTTP headers of the corresponding request
	[OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest * __nonnull request) {
		return YES;
	} withStubResponse:^OHHTTPStubsResponse * __nonnull(NSURLRequest * __nonnull request) {
		return [OHHTTPStubsResponse responseWithData:[NSData data] statusCode:200 headers:[request allHTTPHeaderFields]];
	}];

	// Configure operationQueue to process requests serially.
	self.requestManager.operationQueue.maxConcurrentOperationCount = 1;

	int requestCount = 5000;
	// This will hold ids of the requests in their completion order.
	NSMutableArray *orderArray = [NSMutableArray array];
	for (int i = 0; i < requestCount; i++) {
		// Generate dummy requests and set their order number as an HTTP header value having key 'id'
		[self.requestManager.requestSerializer setValue:[NSString stringWithFormat:@"%d",i] forHTTPHeaderField:@"id"];
		[self.requestManager POST:@""
					   parameters:nil
						  success:^(AFHTTPRequestOperation * __nonnull operation, id  __nonnull responseObject) {
							  // Add id of the request to orderArray
							  [orderArray addObject:[operation.response allHeaderFields][@"id"]];
						  }
						  failure:^(AFHTTPRequestOperation * __nonnull operation, NSError * __nonnull error) {
						  }
		 ];
	}
	expect(orderArray.count).will.equal(@(requestCount));
	expect(^{[self isArraySorted:orderArray];}).will.raiseAny();
}

- (void)testThatUsingSerialCompletionProcessingQueueDoesNotLoseOrder {
	// Stub all requests and return a response containing all HTTP headers of the corresponding request
	[OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest * __nonnull request) {
		return YES;
	} withStubResponse:^OHHTTPStubsResponse * __nonnull(NSURLRequest * __nonnull request) {
		return [OHHTTPStubsResponse responseWithData:[NSData data] statusCode:200 headers:[request allHTTPHeaderFields]];
	}];

	// Configure operationQueue to process requests serially.
	self.requestManager.operationQueue.maxConcurrentOperationCount = 1;
	// Set a serial queue for 'completionProcessingQueue'
	self.requestManager.completionProcessingQueue = dispatch_queue_create("com.alamofire.serialCompletionProcessingQueue", DISPATCH_QUEUE_SERIAL);

	int requestCount = 5000;
	// This will hold ids of the requests in their completion order.
	NSMutableArray *orderArray = [NSMutableArray array];
	for (int i = 0; i < requestCount; i++) {
		// Generate dummy requests and set their order number as an HTTP header value having key 'id'
		[self.requestManager.requestSerializer setValue:[NSString stringWithFormat:@"%d",i] forHTTPHeaderField:@"id"];
		[self.requestManager POST:@""
					   parameters:nil
						  success:^(AFHTTPRequestOperation * __nonnull operation, id  __nonnull responseObject) {
							  // Add id of the request to orderArray
							  [orderArray addObject:[operation.response allHeaderFields][@"id"]];
						  }
						  failure:^(AFHTTPRequestOperation * __nonnull operation, NSError * __nonnull error) {
						  }
		 ];
	}
	expect(orderArray.count).will.equal(@(requestCount));
	expect(^{[self isArraySorted:orderArray];}).willNot.raiseAny();
}


@end
