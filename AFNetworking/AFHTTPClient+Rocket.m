// AFHTTPClient+Rocket.m
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

#import "AFHTTPClient+Rocket.h"

@implementation AFHTTPClient (Rocket)

- (AFEventSource *)SUBSCRIBE:(NSString *)URLString
                  usingBlock:(void (^)(NSArray *operations, NSError *error))block
                       error:(NSError * __autoreleasing *)error
{
    NSMutableURLRequest *request = [self requestWithMethod:@"SUBSCRIBE" URLString:URLString parameters:nil];
    [request setValue:@"text/event-stream" forHTTPHeaderField:@"Accept"];

    return [self openEventSourceWithRequest:request serializer:[AFJSONPatchSerializer serializer] usingBlock:block error:error];
}

- (AFEventSource *)openEventSourceWithRequest:(NSURLRequest *)request
                                   serializer:(AFJSONPatchSerializer *)serializer
                                   usingBlock:(void (^)(NSArray *operations, NSError *error))block
                                        error:(NSError * __autoreleasing *)error
{
    AFEventSource *eventSource = [[AFEventSource alloc] initWithRequest:request];
    [eventSource addListenerForEvent:@"patch" usingBlock:^(AFServerSentEvent *event) {
        NSError *serializationError = nil;
        NSArray *operations = [serializer responseObjectForResponse:nil data:event.data error:&serializationError];
        if (block) {
            block(operations, serializationError);
        }
    }];

    [eventSource open:error];

    return eventSource;
}

@end
