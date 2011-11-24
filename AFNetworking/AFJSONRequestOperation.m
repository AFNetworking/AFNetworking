// AFJSONRequestOperation.m
//
// Copyright (c) 2011 Gowalla (http://gowalla.com/)
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

#import "AFJSONRequestOperation.h"
#import "AFJSONUtilities.h"

@interface AFJSONRequestOperation ()
@property (readwrite, nonatomic, retain) id responseJSON;
@property (readwrite, nonatomic, retain) NSError *JSONError;

+ (NSSet *)defaultAcceptableContentTypes;
+ (NSSet *)defaultAcceptablePathExtensions;

@end

@implementation AFJSONRequestOperation
@synthesize responseJSON = _responseJSON;
@synthesize JSONError = _JSONError;

+ (AFJSONRequestOperation *)JSONRequestOperationWithRequest:(NSURLRequest *)urlRequest
                                                    success:(AFJSONResponseSuccessBlock) success
                                                    failure:(AFJSONResponseFailureBlock) failure
{
    AFJSONRequestOperation *requestOperation = [[[self alloc] initWithRequest:urlRequest] autorelease];

    requestOperation.finishedBlock = ^{
        if (requestOperation.error) {
            if (failure) {
                failure(requestOperation.request,requestOperation.response,requestOperation.error,requestOperation.responseJSON);
            }
        }
        else 
        {
            if (success) {
                success(requestOperation.request,requestOperation.response,requestOperation.responseJSON);
            }
        }
    };
    
    return requestOperation;
}

+ (NSSet *)defaultAcceptableContentTypes {
    return [NSSet setWithObjects:@"application/json", @"text/json", nil];
}

+ (NSSet *)defaultAcceptablePathExtensions {
    return [NSSet setWithObjects:@"json", nil];
}

+ (BOOL)canProcessRequest:(NSURLRequest *)request {
    return [[self defaultAcceptableContentTypes] containsObject:[request valueForHTTPHeaderField:@"Accept"]] || [[self defaultAcceptablePathExtensions] containsObject:[[request URL] pathExtension]];
}

- (id)initWithRequest:(NSURLRequest *)urlRequest {
    
    self = [super initWithRequest:urlRequest];
    if (!self) {
        return nil;
    }
    
    __block AFJSONRequestOperation *blockSelf = self;
    [self addExecutionBlock:^{
        NSError *error = nil;
        if ([blockSelf.responseData length] == 0) {
            blockSelf.responseJSON = nil;
        } else {
            blockSelf.responseJSON = AFJSONDecode(blockSelf.responseData, &error);
        }
        blockSelf.JSONError = error;
    }];
    
    self.acceptableContentTypes = [[self class] defaultAcceptableContentTypes];
    
    return self;
}

- (void)dealloc {
    [_responseJSON release];
    [_JSONError release];
    [super dealloc];
}

- (id)responseObject {
    return [self responseJSON];
}

- (NSError *)error {
    if (_JSONError) {
        return [[_JSONError retain] autorelease];
    } else {
        return [super error];
    }
}

@end

