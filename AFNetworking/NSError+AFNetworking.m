// NSError+AFNetworking.m
//
// Copyright (c) 2013-2015 AFNetworking (http://afnetworking.com)
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

#import "NSError+AFNetworking.h"
#import "AFURLRequestSerialization.h"
#import "AFURLResponseSerialization.h"

@implementation NSError (AFNetworking)

- (NSInteger)networkStatusCode
{
    NSURLResponse* response = [self response];
    
    if ([response isKindOfClass:[NSHTTPURLResponse class]])
    {
        NSHTTPURLResponse* urlResponse = (NSHTTPURLResponse *)response;
        
        return urlResponse.statusCode;
    }
    
    return 0;
}

- (NSURLRequest *)request
{
    return [self objectInUserInfo:AFNetworkingOperationFailingURLRequestErrorKey withError:self];
}

- (NSURLResponse *)response
{
    return [self objectInUserInfo:AFNetworkingOperationFailingURLResponseErrorKey withError:self];
}

- (NSData *)responseData
{
    return [self objectInUserInfo:AFNetworkingOperationFailingURLResponseDataErrorKey withError:self];
}

- (NSString *)responseString
{
    return [[NSString alloc] initWithData:[self objectInUserInfo:AFNetworkingOperationFailingURLResponseDataErrorKey withError:self] encoding:NSUTF8StringEncoding];
}

- (NSString *)requestURL
{
    NSURLResponse* response = [self response];
    
    if ([response isKindOfClass:[NSHTTPURLResponse class]])
    {
        NSHTTPURLResponse* urlResponse = (NSHTTPURLResponse *)response;
        
        return urlResponse.URL.absoluteString;
    }
    else
    {
        return (self.originalError.userInfo[NSURLErrorFailingURLStringErrorKey]) ? self.originalError.userInfo[NSURLErrorFailingURLStringErrorKey] : nil;
    }
}

#pragma mark - Helpers

- (id)objectInUserInfo:(NSString *)key withError:(NSError *)error
{
    if (error.userInfo[key])
    {
        return error.userInfo[key];
    }
    
    //
    // Check for underlying error
    //
    
    NSError* underlyingError = error.userInfo[NSUnderlyingErrorKey];
    
    return (underlyingError.userInfo[key]) ? underlyingError.userInfo[key] : nil;
}

@end
