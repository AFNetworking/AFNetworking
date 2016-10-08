// AFURLSessionManagerTests.m
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

#import <XCTest/XCTest.h>
#import "AFTestCase.h"
#import "AFURLResponseSerialization.h"

@interface AFCompoundResponseSerializerTests : AFTestCase

@end

@implementation AFCompoundResponseSerializerTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

#pragma mark - Compound Serializers

- (void)testCompoundSerializerProperlySerializesResponse {

    AFImageResponseSerializer *imageSerializer = [AFImageResponseSerializer serializer];
    AFJSONResponseSerializer *jsonSerializer = [AFJSONResponseSerializer serializer];
    AFCompoundResponseSerializer *compoundSerializer = [AFCompoundResponseSerializer compoundSerializerWithResponseSerializers:@[imageSerializer, jsonSerializer]];

    NSData *data = [NSJSONSerialization dataWithJSONObject:@{@"key":@"value"} options:(NSJSONWritingOptions)0 error:nil];
    NSURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"http://test.com"]
                                                          statusCode:200
                                                         HTTPVersion:@"1.1"
                                                        headerFields:@{@"Content-Type":@"application/json"}];

    NSError *error = nil;
    id responseObject = [compoundSerializer responseObjectForResponse:response data:data error:&error];

    XCTAssertTrue([responseObject isKindOfClass:[NSDictionary class]]);
    XCTAssertNil(error);
}

- (void)testCompoundSerializerCanBeCopied {
    AFImageResponseSerializer *imageSerializer = [AFImageResponseSerializer serializer];
    AFJSONResponseSerializer *jsonSerializer = [AFJSONResponseSerializer serializer];
    AFCompoundResponseSerializer *compoundSerializer = [AFCompoundResponseSerializer compoundSerializerWithResponseSerializers:@[imageSerializer, jsonSerializer]];
    [compoundSerializer setAcceptableStatusCodes:[NSIndexSet indexSetWithIndex:100]];
    [compoundSerializer setAcceptableContentTypes:[NSSet setWithObject:@"test/type"]];

    AFCompoundResponseSerializer *copiedSerializer = [compoundSerializer copy];
    XCTAssertNotNil(copiedSerializer);
    XCTAssertNotEqual(compoundSerializer, copiedSerializer);
    XCTAssertTrue(compoundSerializer.responseSerializers.count == copiedSerializer.responseSerializers.count);
    XCTAssertTrue([NSStringFromClass([[copiedSerializer.responseSerializers objectAtIndex:0] class]) isEqualToString:NSStringFromClass([AFImageResponseSerializer class])]);
    XCTAssertTrue([NSStringFromClass([[copiedSerializer.responseSerializers objectAtIndex:1] class]) isEqualToString:NSStringFromClass([AFJSONResponseSerializer class])]);
    XCTAssertEqual(compoundSerializer.acceptableStatusCodes, copiedSerializer.acceptableStatusCodes);
    XCTAssertEqual(compoundSerializer.acceptableContentTypes, copiedSerializer.acceptableContentTypes);
}

- (void)testCompoundSerializerCanBeArchivedAndUnarchived {
    AFImageResponseSerializer *imageSerializer = [AFImageResponseSerializer serializer];
    AFJSONResponseSerializer *jsonSerializer = [AFJSONResponseSerializer serializer];
    AFCompoundResponseSerializer *compoundSerializer = [AFCompoundResponseSerializer compoundSerializerWithResponseSerializers:@[imageSerializer, jsonSerializer]];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:compoundSerializer];
    XCTAssertNotNil(data);
    AFCompoundResponseSerializer *unarchivedSerializer = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    XCTAssertNotNil(unarchivedSerializer);
    XCTAssertNotEqual(unarchivedSerializer, compoundSerializer);
    XCTAssertTrue(compoundSerializer.responseSerializers.count == compoundSerializer.responseSerializers.count);
    XCTAssertTrue([NSStringFromClass([[unarchivedSerializer.responseSerializers objectAtIndex:0] class]) isEqualToString:NSStringFromClass([AFImageResponseSerializer class])]);
    XCTAssertTrue([NSStringFromClass([[unarchivedSerializer.responseSerializers objectAtIndex:1] class]) isEqualToString:NSStringFromClass([AFJSONResponseSerializer class])]);
}

@end
