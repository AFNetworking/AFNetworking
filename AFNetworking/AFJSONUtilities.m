// AFJSONUtilities.m
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

#import "AFJSONUtilities.h"

NSData * AFJSONEncode(id object, NSError **error) {
    NSData *data = nil;
    
    SEL _JSONKitSelector = NSSelectorFromString(@"JSONDataWithOptions:error:"); 
    SEL _SBJSONSelector = NSSelectorFromString(@"JSONRepresentation");
    SEL _YAJLSelector = NSSelectorFromString(@"yajl_JSONString");
    
    id _NSJSONSerializationClass = NSClassFromString(@"NSJSONSerialization");
    SEL _NSJSONSerializationSelector = NSSelectorFromString(@"dataWithJSONObject:options:error:");
    
#ifdef _AFNETWORKING_PREFER_NSJSONSERIALIZATION_
    if (_NSJSONSerializationClass && [_NSJSONSerializationClass respondsToSelector:_NSJSONSerializationSelector]) {
        goto _af_nsjson_encode;
    }
#endif
    
    if (_JSONKitSelector && [object respondsToSelector:_JSONKitSelector]) {
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[object methodSignatureForSelector:_JSONKitSelector]];
        invocation.target = object;
        invocation.selector = _JSONKitSelector;
        
        NSUInteger serializeOptionFlags = 0;
        [invocation setArgument:&serializeOptionFlags atIndex:2]; // arguments 0 and 1 are self and _cmd respectively, automatically set by NSInvocation
        [invocation setArgument:error atIndex:3];
        
        [invocation invoke];
        [invocation getReturnValue:&data];
    } else if (_SBJSONSelector && [object respondsToSelector:_SBJSONSelector]) {
        NSString *JSONString = nil;
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[object methodSignatureForSelector:_SBJSONSelector]];
        invocation.target = object;
        invocation.selector = _SBJSONSelector;
        
        [invocation invoke];
        [invocation getReturnValue:&JSONString];
        
        data = [JSONString dataUsingEncoding:NSUTF8StringEncoding];
    } else if (_YAJLSelector && [object respondsToSelector:_YAJLSelector]) {
        @try {
            NSString *JSONString = nil;
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[object methodSignatureForSelector:_YAJLSelector]];
            invocation.target = object;
            invocation.selector = _YAJLSelector;
            
            [invocation invoke];
            [invocation getReturnValue:&JSONString];
            
            data = [JSONString dataUsingEncoding:NSUTF8StringEncoding];
        }
        @catch (NSException *exception) {
            *error = [[[NSError alloc] initWithDomain:NSStringFromClass([exception class]) code:0 userInfo:[exception userInfo]] autorelease];
        }
    } else if (_NSJSONSerializationClass && [_NSJSONSerializationClass respondsToSelector:_NSJSONSerializationSelector]) {
#ifdef _AFNETWORKING_PREFER_NSJSONSERIALIZATION_
    _af_nsjson_encode:
#endif
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[_NSJSONSerializationClass methodSignatureForSelector:_NSJSONSerializationSelector]];
        invocation.target = _NSJSONSerializationClass;
        invocation.selector = _NSJSONSerializationSelector;

        [invocation setArgument:&object atIndex:2]; // arguments 0 and 1 are self and _cmd respectively, automatically set by NSInvocation
        NSUInteger writeOptions = 0;
        [invocation setArgument:&writeOptions atIndex:3];
        [invocation setArgument:error atIndex:4];

        [invocation invoke];
        [invocation getReturnValue:&data];
    } else {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:NSLocalizedString(@"Please either target a platform that supports NSJSONSerialization or add one of the following libraries to your project: JSONKit, SBJSON, or YAJL", nil) forKey:NSLocalizedRecoverySuggestionErrorKey];
        [[NSException exceptionWithName:NSInternalInconsistencyException reason:NSLocalizedString(@"No JSON generation functionality available", nil) userInfo:userInfo] raise];
    }

    return data;
}

id AFJSONDecode(NSData *data, NSError **error) {    
    id JSON = nil;
    
    SEL _JSONKitSelector = NSSelectorFromString(@"objectFromJSONDataWithParseOptions:error:"); 
    SEL _SBJSONSelector = NSSelectorFromString(@"JSONValue");
    SEL _YAJLSelector = NSSelectorFromString(@"yajl_JSONWithOptions:error:");
    
    id _NSJSONSerializationClass = NSClassFromString(@"NSJSONSerialization");
    SEL _NSJSONSerializationSelector = NSSelectorFromString(@"JSONObjectWithData:options:error:");

    
#ifdef _AFNETWORKING_PREFER_NSJSONSERIALIZATION_
    if (_NSJSONSerializationClass && [_NSJSONSerializationClass respondsToSelector:_NSJSONSerializationSelector]) {
        goto _af_nsjson_decode;
    }
#endif
    
    if (_JSONKitSelector && [data respondsToSelector:_JSONKitSelector]) {
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[data methodSignatureForSelector:_JSONKitSelector]];
        invocation.target = data;
        invocation.selector = _JSONKitSelector;
        
        NSUInteger parseOptionFlags = 0;
        [invocation setArgument:&parseOptionFlags atIndex:2]; // arguments 0 and 1 are self and _cmd respectively, automatically set by NSInvocation
        [invocation setArgument:error atIndex:3];
        
        [invocation invoke];
        [invocation getReturnValue:&JSON];
    } else if (_SBJSONSelector && [NSString instancesRespondToSelector:_SBJSONSelector]) {
        // Create a string representation of JSON, to use SBJSON -`JSONValue` category method
        NSString *string = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[string methodSignatureForSelector:_SBJSONSelector]];
        invocation.target = string;
        invocation.selector = _SBJSONSelector;
        
        [invocation invoke];
        [invocation getReturnValue:&JSON];
    } else if (_YAJLSelector && [data respondsToSelector:_YAJLSelector]) {
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[data methodSignatureForSelector:_YAJLSelector]];
        invocation.target = data;
        invocation.selector = _YAJLSelector;
        
        NSUInteger yajlParserOptions = 0;
        [invocation setArgument:&yajlParserOptions atIndex:2]; // arguments 0 and 1 are self and _cmd respectively, automatically set by NSInvocation
        [invocation setArgument:error atIndex:3];
        
        [invocation invoke];
        [invocation getReturnValue:&JSON];
    } else if (_NSJSONSerializationClass && [_NSJSONSerializationClass respondsToSelector:_NSJSONSerializationSelector]) {
#ifdef _AFNETWORKING_PREFER_NSJSONSERIALIZATION_
    _af_nsjson_decode:
#endif
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[_NSJSONSerializationClass methodSignatureForSelector:_NSJSONSerializationSelector]];
        invocation.target = _NSJSONSerializationClass;
        invocation.selector = _NSJSONSerializationSelector;

        [invocation setArgument:&data atIndex:2]; // arguments 0 and 1 are self and _cmd respectively, automatically set by NSInvocation
        NSUInteger readOptions = 0;
        [invocation setArgument:&readOptions atIndex:3];
        [invocation setArgument:error atIndex:4];

        [invocation invoke];
        [invocation getReturnValue:&JSON];
    } else {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:NSLocalizedString(@"Please either target a platform that supports NSJSONSerialization or add one of the following libraries to your project: JSONKit, SBJSON, or YAJL", nil) forKey:NSLocalizedRecoverySuggestionErrorKey];
        [[NSException exceptionWithName:NSInternalInconsistencyException reason:NSLocalizedString(@"No JSON parsing functionality available", nil) userInfo:userInfo] raise];
    }
        
    return JSON;
}
