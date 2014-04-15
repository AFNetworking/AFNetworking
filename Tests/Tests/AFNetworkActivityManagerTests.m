//
//  AFNetworkActivityManagerTests.m
//  AFNetworking Tests
//
//  Created by Dave Weston on 4/13/14.
//  Copyright (c) 2014 AFNetworking. All rights reserved.
//

#import "AFTestCase.h"

#import "AFNetworkActivityIndicatorManager.h"
#import "AFHTTPRequestOperation.h"

@interface UIApplicationFake : NSObject

@property (nonatomic, assign, getter = isNetworkActivityIndicatorVisible) BOOL networkActivityIndicatorVisible;

@end

@implementation UIApplicationFake

@end

@interface AFNetworkActivityManagerTests : AFTestCase

@property (nonatomic, strong) AFNetworkActivityIndicatorManager *target;

@end

@implementation AFNetworkActivityManagerTests

- (void)setUp
{
    [super setUp];
    self.target = [[AFNetworkActivityIndicatorManager alloc] init];
    [self.target setEnabled:YES];
}

- (void)tearDown
{
    [super tearDown];
    self.target = nil;
}

- (void)testThatNetworkActivityIndicatorTurnsOffIndicatorWhenOperationCompletesSuccessfully
{
    __block BOOL finished = NO;
    UIApplicationFake *fakeApp = [[UIApplicationFake alloc] init];
    
    id mockTarget = [OCMockObject partialMockForObject:self.target];
    [[[mockTarget stub] andReturn:fakeApp] sharedApplication];

    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/get" relativeToURL:self.baseURL]];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        expect([fakeApp isNetworkActivityIndicatorVisible]).will.beFalsy();
        finished = YES;
    } failure:nil];
    
    [operation start];

    expect([fakeApp isNetworkActivityIndicatorVisible]).will.beTruthy();
    expect(finished).will.beTruthy();
}

- (void)testThatNetworkActivityIndicatorTurnsOffIndicatorWhenOperationFails
{
    __block BOOL finished = NO;
    UIApplicationFake *fakeApp = [[UIApplicationFake alloc] init];
    
    id mockTarget = [OCMockObject partialMockForObject:self.target];
    [[[mockTarget stub] andReturn:fakeApp] sharedApplication];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/status/500" relativeToURL:self.baseURL]];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:nil failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        expect([fakeApp isNetworkActivityIndicatorVisible]).will.beFalsy();
        finished = YES;
    }];
    
    [operation start];
    
    expect([fakeApp isNetworkActivityIndicatorVisible]).will.beTruthy();
    expect(finished).will.beTruthy();
}

- (void)testThatNetworkActivityIsNotTouchedWhenManagerDisabled
{
    [self.target setEnabled:NO];
    
    __block BOOL finished = NO;
    
    id mockApp = [OCMockObject niceMockForClass:[UIApplication class]];
    [[mockApp reject] setNetworkActivityIndicatorVisible:YES];
    [[mockApp reject] setNetworkActivityIndicatorVisible:NO];
    
    id mockTarget = [OCMockObject partialMockForObject:self.target];
    [[[mockTarget stub] andReturn:mockApp] sharedApplication];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/get" relativeToURL:self.baseURL]];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        finished = YES;
    } failure:nil];
    
    [operation start];
    
    expect(finished).will.beTruthy();
}

@end
