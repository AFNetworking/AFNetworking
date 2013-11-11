// AFHTTPRequestOperation.h
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

#import "NSURLRequest+JLPURLSubscripting.h"

@implementation NSURLRequest (JLPURLSubscripting)

- (id)objectForKeyedSubscript:(id <NSCopying>)key {
    NSParameterAssert([(id <NSObject>)key isKindOfClass:[NSString class]]);

    return [self valueForHTTPHeaderField:(NSString *)key];
}

@end


@implementation NSMutableURLRequest (JLPMutableURLSubscripting)

- (void)setObject:(id)obj forKeyedSubscript:(id <NSCopying>)key {
    NSParameterAssert([(id <NSObject>)key isKindOfClass:[NSString class]]);

    NSString * httpHeader = (NSString *)key;
    NSString * httpValue;
    id <NSFastEnumeration> httpValueCollection;
    if ([obj isKindOfClass:[NSString class]]) {
        httpValue = obj;
    } else if ([obj conformsToProtocol:@protocol(NSFastEnumeration)]) {
        httpValueCollection = obj;
    } else if (!httpValue && !httpValueCollection) {
        NSParameterAssert(([obj isKindOfClass:[NSString class]])||([obj conformsToProtocol:@protocol(NSFastEnumeration)])); //only do the assert after we've attempted the assignment. no point in wasting cycles on an assert otherwise.
    }

    if (httpValueCollection) {
        [self setValue:nil forHTTPHeaderField:httpHeader];
        for (NSString * value in httpValueCollection) {
            [self addValue:value forHTTPHeaderField:httpHeader];
        }
    }

    if (httpValue) {
        [self setValue:httpValue forHTTPHeaderField:httpHeader];
    }

    return;
}

@end
