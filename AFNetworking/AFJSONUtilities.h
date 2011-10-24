// AFJSONUtilities.h
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

#import <Foundation/Foundation.h>

#include <Availability.h>

#if defined(_AF_USE_JSONKIT)
#import "JSONKit.h"
#elif defined(_AF_USE_SBJSON)
#import "SBJSON.h"

static SBJsonParser * _SBJSONParser() {
    static SBJsonParser *_af_SBJSONParser = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _af_SBJSONParser = [[SBJsonParser alloc] init];
    });
    
    return _af_SBJSONParser;
}

static SBJsonWriter * _SBJSONWriter() {
    static SBJsonWriter *_af_SBJSONWriter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _af_SBJSONWriter = [[SBJsonWriter alloc] init];
    });
    
    return _af_SBJSONWriter;
}
#elif defined(_AF_USE_YAJL)
    #if __IPHONE_OS_VERSION_MIN_REQUIRED
    #import <YAJL/YAJL.h>
    #elif __MAC_OS_X_VERSION_MIN_REQUIRED 
    #import <YAJLiOS/YAJL.h>
    #endif
#endif

static inline NSData * AFJSONEncode(id object, NSError **error) {
#if defined(_AF_USE_JSONKIT)
    return [object JSONData];
#elif defined(_AF_USE_SBJSON)
    SBJsonWriter *writer = _SBJSONWriter();
    return [writer dataWithObject:object];
#elif defined(_AF_USE_YAJL)
    return [[object yajl_JSONString] dataUsingEncoding:NSUTF8StringEncoding]];
#else
    if ([NSJSONSerialization class]) {
        return [NSJSONSerialization dataWithJSONObject:object options:0 error:error];
    }    
#endif
    
    return nil;
}

static inline id AFJSONDecode(NSData *data, NSError **error) {
    
#if defined(_AF_USE_JSONKIT)
    return [[JSONDecoder decoder] objectWithData:data error:error];
#elif defined(_AF_USE_SBJSON)
    SBJsonParser *parser = _SBJsonParser();
    return [parser objectWithData:data];
#elif defined(_AF_USE_YAJL)
    return [data yajl_JSON];
#else
    if ([NSJSONSerialization class]) {
        return [NSJSONSerialization JSONObjectWithData:data options:0 error:error];
    }    
#endif
        
    return nil;
}
