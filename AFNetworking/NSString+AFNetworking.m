// NSString+AFNetworking.m
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

#import "NSString+AFNetworking.h"

#ifndef __has_attribute         // Optional of course.
#define __has_attribute(x) 0    // Compatibility with non-clang compilers.
#endif

//This isn't really recommended so don't borrow this pattern because it's hell.
//It works because this file is small so support both doing ARC and non-ARC is ok.
#if __has_attribute(objc_arc)
#define ARC_RETAIN(x) x
#define ARC_RELEASE(x) x
#define ARC_AUTORELEASE(x) x
#else
#define ARC_RETAIN(x) [x retain]
#define ARC_RELEASE(x) [x release]
#define ARC_AUTORELEASE(x) [x autorelease]
#endif

#ifndef __bridge_retain    // exists in Clang
#define __bridge_retain    // exists in Clang
#endif

#ifndef __bridge_transfer  // exists in Clang
#define __bridge_transfer  // exists in Clang
#endif

#ifndef __bridge           // exists in Clang
#define __bridge           // exists in Clang
#endif



@implementation NSString (AFNetworking_URL)

- (NSString *)stringByEscapingForURL {
    return [NSString stringByEscapingForURLFromString:self];
}

- (NSString *)stringByEscapingForURLWithEncoding:(NSStringEncoding)encoding {
    return [NSString stringByEscapingForURLFromString:self withEncoding:encoding];
}

+ (NSString *)stringByEscapingForURLFromString:(NSString *)string {
    return [self stringByEscapingForURLFromString:string withEncoding:NSUTF8StringEncoding];
}

+ (NSString *)stringByEscapingForURLFromString:(NSString *)string withEncoding:(NSStringEncoding)encoding 
{
    return ARC_AUTORELEASE((__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                                                 (__bridge CFStringRef)string, NULL, (CFStringRef)@":/?#[]@!$ &'()*+,;=\"<>%{}|\\^~`",CFStringConvertNSStringEncodingToEncoding(encoding)));
}

@end

@implementation NSString (AFNetworking_URLParams)

- (NSString *)stringByEscapingForURLParameter {
    return [NSString stringByEscapingForURLParameterFromString:self];
}

- (NSString *)stringByEscapingForURLParameterWithEncoding:(NSStringEncoding)encoding {
    return [NSString stringByEscapingForURLParameterFromString:self withEncoding:encoding];
}

+ (NSString *)stringByEscapingForURLParameterFromString:(NSString *)param {
    return [self stringByEscapingForURLParameterFromString:param withEncoding:NSUTF8StringEncoding];
}

+ (NSString *)stringByEscapingForURLParameterFromString:(NSString *)param withEncoding:(NSStringEncoding)encoding 
{
    return ARC_AUTORELEASE((__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                                                 (__bridge CFStringRef)param, NULL, (CFStringRef)@"!*'\"();:@&=+$,/?%#[]% ",CFStringConvertNSStringEncodingToEncoding(encoding)));
}

@end


@implementation NSString (AFNetworking_Legacy)

/* decrepated for better naming convention */
- (NSString*)urlEncodedString { 
	return [self urlEncodedStringWithEncoding:NSUTF8StringEncoding];
}

/* decrepated for better naming convention */
// See http://github.com/pokeb/asi-http-request/raw/master/Classes/ASIFormDataRequest.m
- (NSString *)urlEncodedStringWithEncoding:(NSStringEncoding)encoding { 
	NSString *urlEncodedString = ARC_AUTORELEASE((__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (__bridge CFStringRef)self, NULL, (CFStringRef)@":/?#[]@!$ &'()*+,;=\"<>%{}|\\^~`", CFStringConvertNSStringEncodingToEncoding(encoding)));
                                                  
    return urlEncodedString ? urlEncodedString : @"";
}


@end
