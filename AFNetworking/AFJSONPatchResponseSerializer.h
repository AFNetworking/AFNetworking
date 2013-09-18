// AFJSONPatchSerializer.h
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

#import "AFURLResponseSerialization.h"

/**
 `AFJSONPatchOperationType` represent the possible JSON Patch operation types.
 */
typedef NS_ENUM(NSUInteger, AFJSONPatchOperationType) {
    AFJSONAddOperationType = 1,
    AFJSONRemoveOperationType = 2,
    AFJSONReplaceOperationType = 3,
    AFJSONMoveOperationType = 4,
    AFJSONCopyOperationType = 5,
    AFJSONTestOperationType = 6,
};

/**
 `AFJSONPatchOperation` objects represent component operations of a JSON Patch document. JSON Patch (RFC 6902) describes a common format to represent changes in structured data.
 
 A patch is comprised by an array of operations, like in the following example:
 
    [
            { "op": "add", "path": "/a/b/c", "value": [ "foo", "bar" ] },
            { "op": "remove", "path": "/a/b/c" },
            { "op": "replace", "path": "/a/b/c", "value": 42 },
            { "op": "move", "from": "/a/b/c", "path": "/a/b/d" },
            { "op": "copy", "from": "/a/b/d", "path": "/a/b/e" },
            { "op": "test", "path": "/a/b/c", "value": "foo" }
    ]
 
 Each operation object encodes the `type` of operation (`add`, `remove`, `replace`, `move`, `copy`, or `test` for existence) on a particular `path`, and any associated `value`. `copy` and `move` operations additionally contain a `from` value.

 @see http://tools.ietf.org/html/rfc6902
 */
@interface AFJSONPatchOperation : NSObject

/**
 The type of operation. Possible values correspond to the operation types defined by the JSON Patch specification (`add`, `remove`, `replace`, `move`, `copy`, or `test` for existence), and are described in "AFJSONPatchOperationType".
 */
@property (readonly, nonatomic, assign) AFJSONPatchOperationType type;

/**
 The path of the resource.
 */
@property (readonly, nonatomic, copy) NSString *path;

/**
 For `move` and `copy` operations, the originating path.
 */
@property (readonly, nonatomic, copy) NSString *from;

/**
 The value associated with the operation.
 */
@property (readonly, nonatomic, strong) id value;

///-------------------------------------
/// @name Creating JSON Patch Operations
///-------------------------------------

/**
 Create and return an `add` operation with the specified path and value.
 */
+ (instancetype)addOperationWithPath:(NSString *)path
                               value:(id)value;

/**
 Create and return a `remove` operation with the specified path.
 */
+ (instancetype)removeOperationWithPath:(NSString *)path;

/**
 Create and return a `replace` operation with the specified path and value.
 */
+ (instancetype)replaceOperationWithPath:(NSString *)path
                                   value:(id)value;

/**
 Create and return a `move` operation, with a specified origin and destination.
 */
+ (instancetype)moveOperationFrom:(NSString *)fromPath
                               to:(NSString *)toPath;

/**
 Create and return a `copy` operation, with a specified origin and destination.
 */
+ (instancetype)copyOperationFrom:(NSString *)fromPath
                               to:(NSString *)toPath;

/**
 Create and return a `test` operation, with a specified path and value.
 */
+ (instancetype)testOperationWithPath:(NSString *)path
                                value:(id)value;

///

/**
 Creates and returns an operation from a dictionary.

 @param dictionary The fields defining the operation.
 @param error The error that occurred while attempting construct a JSON Patch operation.

 @return A JSON Patch operation.
 */
+ (instancetype)operationWithDictionary:(NSDictionary *)dictionary
                                  error:(NSError * __autoreleasing *)error;

@end

#pragma mark -

/**
 `AFServerSentEventSerializer` is a subclass of `AFHTTPSerializer` that validates and decodes server sent event messages.

 By default, `AFServerSentEventSerializer` accepts responses with a MIME type of `application/json-patch+json`.
 */
@interface AFJSONPatchResponseSerializer : AFJSONResponseSerializer

@end
