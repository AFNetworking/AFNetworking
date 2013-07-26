//
//  AFJSONSerializerTests.m
//  AFNetworking Tests
//
//  Created by Kevin Harwood on 7/26/13.
//  Copyright (c) 2013 AFNetworking. All rights reserved.
//

#import "AFNetworkingTests.h"

@interface AFJSONSerializerTests : XCTestCase
@property (readwrite, nonatomic, strong) AFHTTPClient *client;
@end

@implementation AFJSONSerializerTests

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

- (void)testJSONSerializerCanProcessApplicationJSONByDefault{
    AFJSONSerializer * serializer = [AFJSONSerializer serializer];
    NSHTTPURLResponse * response = [[NSHTTPURLResponse alloc]  initWithURL:[NSURL URLWithString:@"http://dummy.com"]
                                                                statusCode:200
                                                               HTTPVersion:@"1.0"
                                                              headerFields:@{@"Content-Type":@"application/json"}];;
    NSError * error = nil;
    NSData * fakeData = [@"test" dataUsingEncoding:NSUTF8StringEncoding];
    [serializer validateResponse:response data:fakeData error:&error];
    XCTAssertNil(error, @"AFJSONSerializer unable to process application/json by default");
}

- (void)testJSONSerializerCanValidateContentTypeTextJSONByDefault{
    AFJSONSerializer * serializer = [AFJSONSerializer serializer];
    NSHTTPURLResponse * response = [[NSHTTPURLResponse alloc]  initWithURL:[NSURL URLWithString:@"http://dummy.com"]
                                                                statusCode:200
                                                               HTTPVersion:@"1.0"
                                                              headerFields:@{@"Content-Type":@"text/json"}];;
    NSError * error;
    NSData * fakeData = [@"test" dataUsingEncoding:NSUTF8StringEncoding];
    [serializer validateResponse:response data:fakeData error:&error];
    XCTAssertNil(error, @"AFJSONSerializer unable to process text/json by default");
}

- (void)testJSONSerializerCanValidateContentTypeTextJavascriptByDefault{
    AFJSONSerializer * serializer = [AFJSONSerializer serializer];
    NSHTTPURLResponse * response = [[NSHTTPURLResponse alloc]  initWithURL:[NSURL URLWithString:@"http://dummy.com"]
                                                                statusCode:200
                                                               HTTPVersion:@"1.0"
                                                              headerFields:@{@"Content-Type":@"text/javascript"}];;
    NSError * error;
    NSData * fakeData = [@"test" dataUsingEncoding:NSUTF8StringEncoding];
    [serializer validateResponse:response data:fakeData error:&error];
    XCTAssertNil(error, @"AFJSONSerializer unable to process text/javascript by default");
}

- (void)testJSONSerializerCanNotValidateInvalidContentTypeByDefault{
    AFJSONSerializer * serializer = [AFJSONSerializer serializer];
    NSHTTPURLResponse * response = [[NSHTTPURLResponse alloc]  initWithURL:[NSURL URLWithString:@"http://dummy.com"]
                                                                statusCode:200
                                                               HTTPVersion:@"1.0"
                                                              headerFields:@{@"Content-Type":@"invalid/json"}];;
    NSError * error;
    NSData * fakeData = [@"test" dataUsingEncoding:NSUTF8StringEncoding];
    [serializer validateResponse:response data:fakeData error:&error];
    XCTAssertEquals(error.code, NSURLErrorCannotDecodeContentData, @"JSON Serializer should not be able to validate invalid/json");
}

- (void)testThatJSONResponseObjectIsNotNilWhenValidJSONIsReturned {
    [Expecta setAsynchronousTestTimeout:5.0];
    [self.client setResponseSerializers:@[[AFJSONSerializer serializer]]];
    __block id blockResponseObject;
    NSURLSessionDataTask * task = [self.client
                                   GET:@"/response-headers?Content-Type=application/json"
                                   parameters:nil
                                   success:^(NSHTTPURLResponse *response, id responseObject) {
                                       blockResponseObject = responseObject;
                                   }
                                   failure:nil];
    
    expect(task.state == NSURLSessionTaskStateCompleted).will.beTruthy();
    expect(blockResponseObject).willNot.beNil();
}

@end
