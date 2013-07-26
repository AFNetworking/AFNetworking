//
//  AFHTTPSerializerTests.m
//  AFNetworking Tests
//
//  Created by Kevin Harwood on 7/26/13.
//  Copyright (c) 2013 AFNetworking. All rights reserved.
//

#import "AFNetworkingTests.h"

@interface AFHTTPSerializerTests : XCTestCase
@property (readwrite, nonatomic, strong) AFHTTPClient *client;
@end

@implementation AFHTTPSerializerTests

- (void)setUp
{
    [super setUp];
    self.client = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:AFNetworkingTestsBaseURLString]];
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}

- (void)testAuthorizationHeaderWithValidUsernamePassword {
    [Expecta setAsynchronousTestTimeout:5.0];
    
    AFHTTPSerializer * serializer = [AFHTTPSerializer serializer];
    [serializer setAuthorizationHeaderFieldWithUsername:@"username" password:@"password"];
    [self.client setRequestSerializer:serializer];
    
    __block NSHTTPURLResponse *blockResponse = nil;
    
    [self.client
     GET:@"/basic-auth/username/password"
     parameters:nil
     success:^(NSHTTPURLResponse *response, id responseObject) {
         blockResponse = response;
     }
     failure:^(NSError *error) {
         NSLog(@"%@",error);
     }];
    
    expect(blockResponse.statusCode).will.equal(200);
}

- (void)testAuthorizationHeaderWithInvalidUsernamePassword {
    [Expecta setAsynchronousTestTimeout:5.0];

    AFHTTPSerializer * serializer = [AFHTTPSerializer serializer];
    [serializer setAuthorizationHeaderFieldWithUsername:nil password:nil];
    [self.client setRequestSerializer:serializer];
    
    __block NSHTTPURLResponse *response = nil;
    [self.client GET:@"/basic-auth/username/password"
          parameters:nil
             success:nil
             failure:^(NSError *error) {
                 response = [error.userInfo objectForKey:AFNetworkingOperationFailingURLResponseErrorKey];
             }];
    expect(response.statusCode).will.equal(401);
}

- (void)testThatClientClearsAuthorizationHeader {
    AFHTTPSerializer * serializer = [AFHTTPSerializer serializer];
    [serializer setAuthorizationHeaderFieldWithUsername:@"username" password:@"password"];
    [serializer clearAuthorizationHeader];

    __block NSHTTPURLResponse *response = nil;
    [self.client GET:@"/basic-auth/username/password"
          parameters:nil
             success:nil
             failure:^(NSError *error) {
                 response = [error.userInfo objectForKey:AFNetworkingOperationFailingURLResponseErrorKey];
             }];
    expect(response.statusCode).will.equal(401);
}





@end
