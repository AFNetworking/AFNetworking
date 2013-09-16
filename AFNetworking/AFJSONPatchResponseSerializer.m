// AFJSONPatchSerializer.m
// 
// Copyright (c) 2013 AFNetworking (http://afnetworking.com)
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

#import "AFJSONPatchResponseSerializer.h"
#import "AFHTTPRequestOperation.h"

@implementation AFJSONPatchResponseSerializer

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }

    self.acceptableContentTypes = [NSSet setWithObjects:@"application/json-patch+json", nil];

    return self;
}

#pragma mark - AFURLResponseSerialization

- (id)responseObjectForResponse:(NSURLResponse *)response
                           data:(NSData *)data
                          error:(NSError *__autoreleasing *)error
{
    id JSON = [super responseObjectForResponse:response data:data error:error];
    if ([JSON isKindOfClass:[NSArray class]]) {
        NSMutableArray *mutableOperations = [NSMutableArray arrayWithCapacity:[JSON count]];
        for (NSDictionary *dictionary in JSON) {
            AFJSONPatchOperation *operation = [AFJSONPatchOperation operationWithDictionary:dictionary error:nil];
            if (operation) {
                [mutableOperations addObject:operation];
            }
        }

        return mutableOperations;
    }

    return nil;
}

@end

#pragma mark -

@interface AFJSONPatchOperation ()
@property (readwrite, nonatomic, assign) AFJSONPatchOperationType type;
@property (readwrite, nonatomic, copy) NSString *path;
@property (readwrite, nonatomic, copy) NSString *from;
@property (readwrite, nonatomic, strong) id value;
@end

@implementation AFJSONPatchOperation

+ (instancetype)operationWithDictionary:(NSDictionary *)dictionary
                                  error:(NSError * __autoreleasing *)error
{
    @try {
        NSString *op = dictionary[@"op"];
        if ([op isEqualToString:@"add"]) {
            return [AFJSONPatchOperation addOperationWithPath:dictionary[@"path"] value:dictionary[@"value"]];
        } else if ([op isEqualToString:@"remove"]) {
            return [AFJSONPatchOperation removeOperationWithPath:dictionary[@"path"]];
        } else if ([op isEqualToString:@"replace"]) {
            return [AFJSONPatchOperation replaceOperationWithPath:dictionary[@"path"] value:dictionary[@"value"]];
        } else if ([op isEqualToString:@"move"]) {
            return [AFJSONPatchOperation moveOperationFrom:dictionary[@"from"] to:dictionary[@"path"]];
        } else if ([op isEqualToString:@"copy"]) {
            return [AFJSONPatchOperation copyOperationFrom:dictionary[@"from"] to:dictionary[@"path"]];
        } else if ([op isEqualToString:@"test"]) {
            return [AFJSONPatchOperation testOperationWithPath:dictionary[@"path"] value:dictionary[@"value"]];
        } else {
            return nil;
        }
    } @catch (NSException *exception) {
        if (error) {
            NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:exception.userInfo];
            userInfo[NSLocalizedDescriptionKey] = exception.name;
            userInfo[NSLocalizedFailureReasonErrorKey] = exception.reason;
            *error = [[NSError alloc] initWithDomain:AFNetworkingErrorDomain code:0 userInfo:userInfo];
        }

        return nil;
    }
}


+ (instancetype)addOperationWithPath:(NSString *)path
                               value:(id)value
{
    NSParameterAssert(path);

    AFJSONPatchOperation *operation = [[self alloc] init];
    operation.type = AFJSONAddOperationType;
    operation.path = path;
    operation.value = value;

    return operation;
}

+ (instancetype)removeOperationWithPath:(NSString *)path {
    NSParameterAssert(path);

    AFJSONPatchOperation *operation = [[self alloc] init];
    operation.type = AFJSONRemoveOperationType;
    operation.path = path;

    return operation;
}

+ (instancetype)replaceOperationWithPath:(NSString *)path
                                   value:(id)value
{
    NSParameterAssert(path);

    AFJSONPatchOperation *operation = [[self alloc] init];
    operation.type = AFJSONReplaceOperationType;
    operation.path = path;
    operation.value = value;

    return operation;
}

+ (instancetype)moveOperationFrom:(NSString *)fromPath
                               to:(NSString *)toPath
{
    NSParameterAssert(fromPath);
    NSParameterAssert(toPath);

    AFJSONPatchOperation *operation = [[self alloc] init];
    operation.type = AFJSONMoveOperationType;
    operation.from = fromPath;
    operation.path = toPath;

    return operation;
}

+ (instancetype)copyOperationFrom:(NSString *)fromPath
                               to:(NSString *)toPath
{
    NSParameterAssert(fromPath);
    NSParameterAssert(toPath);

    AFJSONPatchOperation *operation = [[self alloc] init];
    operation.type = AFJSONCopyOperationType;
    operation.from = fromPath;
    operation.path = toPath;

    return operation;
}

+ (instancetype)testOperationWithPath:(NSString *)path
                                value:(id)value
{
    NSParameterAssert(path);

    AFJSONPatchOperation *operation = [[self alloc] init];
    operation.type = AFJSONTestOperationType;
    operation.path = path;
    operation.value = value;

    return operation;
}

@end
