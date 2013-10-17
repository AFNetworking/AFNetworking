// AFSerialization.h
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

#import "AFURLRequestSerialization.h"

extern NSString * const AFNetworkingErrorDomain;

typedef NSString * (^AFQueryStringSerializationBlock)(NSURLRequest *request, NSDictionary *parameters, NSError *__autoreleasing *error);

static NSString * AFBase64EncodedStringFromString(NSString *string) {
    NSData *data = [NSData dataWithBytes:[string UTF8String] length:[string lengthOfBytesUsingEncoding:NSUTF8StringEncoding]];
    NSUInteger length = [data length];
    NSMutableData *mutableData = [NSMutableData dataWithLength:((length + 2) / 3) * 4];

    uint8_t *input = (uint8_t *)[data bytes];
    uint8_t *output = (uint8_t *)[mutableData mutableBytes];

    for (NSUInteger i = 0; i < length; i += 3) {
        NSUInteger value = 0;
        for (NSUInteger j = i; j < (i + 3); j++) {
            value <<= 8;
            if (j < length) {
                value |= (0xFF & input[j]);
            }
        }

        static uint8_t const kAFBase64EncodingTable[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

        NSUInteger idx = (i / 3) * 4;
        output[idx + 0] = kAFBase64EncodingTable[(value >> 18) & 0x3F];
        output[idx + 1] = kAFBase64EncodingTable[(value >> 12) & 0x3F];
        output[idx + 2] = (i + 1) < length ? kAFBase64EncodingTable[(value >> 6)  & 0x3F] : '=';
        output[idx + 3] = (i + 2) < length ? kAFBase64EncodingTable[(value >> 0)  & 0x3F] : '=';
    }

    return [[NSString alloc] initWithData:mutableData encoding:NSASCIIStringEncoding];
}

static NSString * const kAFCharactersToBeEscapedInQueryString = @":/?&=;+!@#$()',*";

static NSString * AFPercentEscapedQueryStringKeyFromStringWithEncoding(NSString *string, NSStringEncoding encoding) {
    static NSString * const kAFCharactersToLeaveUnescapedInQueryStringPairKey = @"[].";

	return (__bridge_transfer  NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (__bridge CFStringRef)string, (__bridge CFStringRef)kAFCharactersToLeaveUnescapedInQueryStringPairKey, (__bridge CFStringRef)kAFCharactersToBeEscapedInQueryString, CFStringConvertNSStringEncodingToEncoding(encoding));
}

static NSString * AFPercentEscapedQueryStringValueFromStringWithEncoding(NSString *string, NSStringEncoding encoding) {
	return (__bridge_transfer  NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (__bridge CFStringRef)string, NULL, (__bridge CFStringRef)kAFCharactersToBeEscapedInQueryString, CFStringConvertNSStringEncodingToEncoding(encoding));
}

#pragma mark -

@interface AFQueryStringPair : NSObject
@property (readwrite, nonatomic, strong) id field;
@property (readwrite, nonatomic, strong) id value;

- (id)initWithField:(id)field value:(id)value;

- (NSString *)URLEncodedStringValueWithEncoding:(NSStringEncoding)stringEncoding;
@end

@implementation AFQueryStringPair

- (id)initWithField:(id)field value:(id)value {
    self = [super init];
    if (!self) {
        return nil;
    }

    self.field = field;
    self.value = value;

    return self;
}

- (NSString *)URLEncodedStringValueWithEncoding:(NSStringEncoding)stringEncoding {
    if (!self.value || [self.value isEqual:[NSNull null]]) {
        return AFPercentEscapedQueryStringKeyFromStringWithEncoding([self.field description], stringEncoding);
    } else {
        return [NSString stringWithFormat:@"%@=%@", AFPercentEscapedQueryStringKeyFromStringWithEncoding([self.field description], stringEncoding), AFPercentEscapedQueryStringValueFromStringWithEncoding([self.value description], stringEncoding)];
    }
}

@end

#pragma mark -

extern NSArray * AFQueryStringPairsFromDictionary(NSDictionary *dictionary);
extern NSArray * AFQueryStringPairsFromKeyAndValue(NSString *key, id value);

static NSString * AFQueryStringFromParametersWithEncoding(NSDictionary *parameters, NSStringEncoding stringEncoding) {
    NSMutableArray *mutablePairs = [NSMutableArray array];
    for (AFQueryStringPair *pair in AFQueryStringPairsFromDictionary(parameters)) {
        [mutablePairs addObject:[pair URLEncodedStringValueWithEncoding:stringEncoding]];
    }

    return [mutablePairs componentsJoinedByString:@"&"];
}

NSArray * AFQueryStringPairsFromDictionary(NSDictionary *dictionary) {
    return AFQueryStringPairsFromKeyAndValue(nil, dictionary);
}

NSArray * AFQueryStringPairsFromKeyAndValue(NSString *key, id value) {
    NSMutableArray *mutableQueryStringComponents = [NSMutableArray array];

    if ([value isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dictionary = value;
        // Sort dictionary keys to ensure consistent ordering in query string, which is important when deserializing potentially ambiguous sequences, such as an array of dictionaries
        NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"description" ascending:YES selector:@selector(caseInsensitiveCompare:)];
        for (id nestedKey in [dictionary.allKeys sortedArrayUsingDescriptors:@[ sortDescriptor ]]) {
            id nestedValue = [dictionary objectForKey:nestedKey];
            if (nestedValue) {
                [mutableQueryStringComponents addObjectsFromArray:AFQueryStringPairsFromKeyAndValue((key ? [NSString stringWithFormat:@"%@[%@]", key, nestedKey] : nestedKey), nestedValue)];
            }
        }
    } else if ([value isKindOfClass:[NSArray class]]) {
        NSArray *array = value;
        for (id nestedValue in array) {
            [mutableQueryStringComponents addObjectsFromArray:AFQueryStringPairsFromKeyAndValue([NSString stringWithFormat:@"%@[]", key], nestedValue)];
        }
    } else if ([value isKindOfClass:[NSSet class]]) {
        NSSet *set = value;
        for (id obj in set) {
            [mutableQueryStringComponents addObjectsFromArray:AFQueryStringPairsFromKeyAndValue(key, obj)];
        }
    } else {
        [mutableQueryStringComponents addObject:[[AFQueryStringPair alloc] initWithField:key value:value]];
    }
    
    return mutableQueryStringComponents;
}

#pragma mark -

@interface AFStreamingMultipartFormData : NSObject <AFMultipartFormData>
- (instancetype)initWithURLRequest:(NSMutableURLRequest *)urlRequest
                    stringEncoding:(NSStringEncoding)encoding;

- (NSMutableURLRequest *)requestByFinalizingMultipartFormData;
@end

#pragma mark -

@interface AFHTTPRequestSerializer ()
@property (readwrite, nonatomic, strong) NSMutableDictionary *mutableHTTPRequestHeaders;
@property (readwrite, nonatomic, assign) AFHTTPRequestQueryStringSerializationStyle queryStringSerializationStyle;
@property (readwrite, nonatomic, copy) AFQueryStringSerializationBlock queryStringSerialization;
@end

@implementation AFHTTPRequestSerializer

+ (instancetype)serializer {
    return [[self alloc] init];
}

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }

    self.stringEncoding = NSUTF8StringEncoding;

    self.mutableHTTPRequestHeaders = [NSMutableDictionary dictionary];

    // Accept-Language HTTP Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.4
    NSMutableArray *acceptLanguagesComponents = [NSMutableArray array];
    [[NSLocale preferredLanguages] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        float q = 1.0f - (idx * 0.1f);
        [acceptLanguagesComponents addObject:[NSString stringWithFormat:@"%@;q=%0.1g", obj, q]];
        *stop = q <= 0.5f;
    }];
    [self setValue:[acceptLanguagesComponents componentsJoinedByString:@", "] forHTTPHeaderField:@"Accept-Language"];

    NSString *userAgent = nil;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wgnu"
#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
    // User-Agent Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.43
    userAgent = [NSString stringWithFormat:@"%@/%@ (%@; iOS %@; Scale/%0.2f)", [[[NSBundle mainBundle] infoDictionary] objectForKey:(__bridge NSString *)kCFBundleExecutableKey] ?: [[[NSBundle mainBundle] infoDictionary] objectForKey:(__bridge NSString *)kCFBundleIdentifierKey], (__bridge id)CFBundleGetValueForInfoDictionaryKey(CFBundleGetMainBundle(), kCFBundleVersionKey) ?: [[[NSBundle mainBundle] infoDictionary] objectForKey:(__bridge NSString *)kCFBundleVersionKey], [[UIDevice currentDevice] model], [[UIDevice currentDevice] systemVersion], ([[UIScreen mainScreen] respondsToSelector:@selector(scale)] ? [[UIScreen mainScreen] scale] : 1.0f)];
#elif defined(__MAC_OS_X_VERSION_MIN_REQUIRED)
    userAgent = [NSString stringWithFormat:@"%@/%@ (Mac OS X %@)", [[[NSBundle mainBundle] infoDictionary] objectForKey:(__bridge NSString *)kCFBundleExecutableKey] ?: [[[NSBundle mainBundle] infoDictionary] objectForKey:(__bridge NSString *)kCFBundleIdentifierKey], [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"] ?: [[[NSBundle mainBundle] infoDictionary] objectForKey:(__bridge NSString *)kCFBundleVersionKey], [[NSProcessInfo processInfo] operatingSystemVersionString]];
#endif
#pragma clang diagnostic pop
    if (userAgent) {
        if (![userAgent canBeConvertedToEncoding:NSASCIIStringEncoding]) {
            NSMutableString *mutableUserAgent = [userAgent mutableCopy];
            CFStringTransform((__bridge CFMutableStringRef)(mutableUserAgent), NULL, (__bridge CFStringRef)@"Any-Latin; Latin-ASCII; [:^ASCII:] Remove", false);
            userAgent = mutableUserAgent;
        }
        [self setValue:userAgent forHTTPHeaderField:@"User-Agent"];
    }

    // HTTP Method Definitions; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec9.html
    self.HTTPMethodsEncodingParametersInURI = [NSSet setWithObjects:@"GET", @"HEAD", @"DELETE", nil];

    return self;
}

#pragma mark -

- (NSDictionary *)HTTPRequestHeaders {
    return [NSDictionary dictionaryWithDictionary:self.mutableHTTPRequestHeaders];
}

- (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field {
	[self.mutableHTTPRequestHeaders setValue:value forKey:field];
}

- (void)setAuthorizationHeaderFieldWithUsername:(NSString *)username password:(NSString *)password {
	NSString *basicAuthCredentials = [NSString stringWithFormat:@"%@:%@", username, password];
    [self setValue:[NSString stringWithFormat:@"Basic %@", AFBase64EncodedStringFromString(basicAuthCredentials)] forHTTPHeaderField:@"Authorization"];
}

- (void)setAuthorizationHeaderFieldWithToken:(NSString *)token {
    [self setValue:[NSString stringWithFormat:@"Token token=\"%@\"", token] forHTTPHeaderField:@"Authorization"];
}

- (void)clearAuthorizationHeader {
	[self.mutableHTTPRequestHeaders removeObjectForKey:@"Authorization"];
}

#pragma mark -

- (void)setQueryStringSerializationWithStyle:(AFHTTPRequestQueryStringSerializationStyle)style {
    self.queryStringSerializationStyle = style;
    self.queryStringSerialization = nil;
}

- (void)setQueryStringSerializationWithBlock:(NSString *(^)(NSURLRequest *, NSDictionary *, NSError *__autoreleasing *))block {
    self.queryStringSerialization = block;
}

#pragma mark -

- (NSMutableURLRequest *)requestWithMethod:(NSString *)method
                                 URLString:(NSString *)URLString
                                parameters:(NSDictionary *)parameters
{
    NSParameterAssert(method);
    NSParameterAssert(URLString);

    NSURL *url = [NSURL URLWithString:URLString];

    NSParameterAssert(url);

    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request setHTTPMethod:method];

    request = [[self requestBySerializingRequest:request withParameters:parameters error:nil] mutableCopy];

	return request;
}

- (NSMutableURLRequest *)multipartFormRequestWithMethod:(NSString *)method
                                              URLString:(NSString *)URLString
                                             parameters:(NSDictionary *)parameters
                              constructingBodyWithBlock:(void (^)(id <AFMultipartFormData> formData))block
{
    NSParameterAssert(method);
    NSParameterAssert(![method isEqualToString:@"GET"] && ![method isEqualToString:@"HEAD"]);

    NSMutableURLRequest *request = [self requestWithMethod:method URLString:URLString parameters:nil];

    __block AFStreamingMultipartFormData *formData = [[AFStreamingMultipartFormData alloc] initWithURLRequest:request stringEncoding:NSUTF8StringEncoding];

    if (parameters) {
        for (AFQueryStringPair *pair in AFQueryStringPairsFromDictionary(parameters)) {
            NSData *data = nil;
            if ([pair.value isKindOfClass:[NSData class]]) {
                data = pair.value;
            } else if ([pair.value isEqual:[NSNull null]]) {
                data = [NSData data];
            } else {
                data = [[pair.value description] dataUsingEncoding:self.stringEncoding];
            }

            if (data) {
                [formData appendPartWithFormData:data name:[pair.field description]];
            }
        }
    }

    if (block) {
        block(formData);
    }

    return [formData requestByFinalizingMultipartFormData];
}

#pragma mark - AFURLRequestSerialization

- (NSURLRequest *)requestBySerializingRequest:(NSURLRequest *)request
                               withParameters:(NSDictionary *)parameters
                                        error:(NSError *__autoreleasing *)error
{
    NSParameterAssert(request);

    NSMutableURLRequest *mutableRequest = [request mutableCopy];

    [self.HTTPRequestHeaders enumerateKeysAndObjectsUsingBlock:^(id field, id value, BOOL * __unused stop) {
        if (![request valueForHTTPHeaderField:field]) {
            [mutableRequest setValue:value forHTTPHeaderField:field];
        }
    }];

    if (!parameters) {
        return mutableRequest;
    }

    NSString *query = nil;
    if (self.queryStringSerialization) {
        query = self.queryStringSerialization(request, parameters, error);
    } else {
        switch (self.queryStringSerializationStyle) {
            case AFHTTPRequestQueryStringDefaultStyle:
                query = AFQueryStringFromParametersWithEncoding(parameters, self.stringEncoding);
                break;
            default:
                break;
        }
    }

    if ([self.HTTPMethodsEncodingParametersInURI containsObject:[[request HTTPMethod] uppercaseString]]) {
        mutableRequest.URL = [NSURL URLWithString:[[mutableRequest.URL absoluteString] stringByAppendingFormat:mutableRequest.URL.query ? @"&%@" : @"?%@", AFQueryStringFromParametersWithEncoding(parameters, self.stringEncoding)]];
    } else {
        NSString *charset = (__bridge NSString *)CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(self.stringEncoding));
        [mutableRequest setValue:[NSString stringWithFormat:@"application/x-www-form-urlencoded; charset=%@", charset] forHTTPHeaderField:@"Content-Type"];
        [mutableRequest setHTTPBody:[query dataUsingEncoding:self.stringEncoding]];
    }

    return mutableRequest;
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [self init];
    if (!self) {
        return nil;
    }

    self.mutableHTTPRequestHeaders = [aDecoder decodeObjectForKey:@"mutableHTTPRequestHeaders"];
    self.queryStringSerializationStyle = (AFHTTPRequestQueryStringSerializationStyle)[aDecoder decodeIntegerForKey:@"queryStringSerializationStyle"];

    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.mutableHTTPRequestHeaders forKey:@"mutableHTTPRequestHeaders"];
    [aCoder encodeInteger:self.queryStringSerializationStyle forKey:@"queryStringSerializationStyle"];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    AFHTTPRequestSerializer *serializer = [[[self class] allocWithZone:zone] init];
    serializer.mutableHTTPRequestHeaders = [self.mutableHTTPRequestHeaders mutableCopyWithZone:zone];
    serializer.queryStringSerializationStyle = self.queryStringSerializationStyle;
    serializer.queryStringSerialization = self.queryStringSerialization;
    
    return serializer;
}

@end

#pragma mark -

static NSString * const kAFMultipartFormBoundary = @"Boundary+0xAbCdEfGbOuNdArY";

static NSString * const kAFMultipartFormCRLF = @"\r\n";

static NSInteger const kAFStreamToStreamBufferSize = 1024 * 1024; //1 meg default

static inline NSString * AFMultipartFormInitialBoundary() {
    return [NSString stringWithFormat:@"--%@%@", kAFMultipartFormBoundary, kAFMultipartFormCRLF];
}

static inline NSString * AFMultipartFormEncapsulationBoundary() {
    return [NSString stringWithFormat:@"%@--%@%@", kAFMultipartFormCRLF, kAFMultipartFormBoundary, kAFMultipartFormCRLF];
}

static inline NSString * AFMultipartFormFinalBoundary() {
    return [NSString stringWithFormat:@"%@--%@--%@", kAFMultipartFormCRLF, kAFMultipartFormBoundary, kAFMultipartFormCRLF];
}

static inline NSString * AFContentTypeForPathExtension(NSString *extension) {
#ifdef __UTTYPE__
    NSString *UTI = (__bridge_transfer NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)extension, NULL);
    NSString *contentType = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)UTI, kUTTagClassMIMEType);
    if (!contentType) {
        return @"application/octet-stream";
    } else {
        return contentType;
    }
#else
    return @"application/octet-stream";
#endif
}

NSUInteger const kAFUploadStream3GSuggestedPacketSize = 1024 * 16;
NSTimeInterval const kAFUploadStream3GSuggestedDelay = 0.2;

@interface AFHTTPBodyPart : NSObject
@property (nonatomic, assign) NSStringEncoding stringEncoding;
@property (nonatomic, strong) NSDictionary *headers;
@property (nonatomic, strong) id body;
@property (nonatomic, assign) unsigned long long bodyContentLength;
@property (nonatomic, strong) NSInputStream *inputStream;

@property (nonatomic, assign) BOOL hasInitialBoundary;
@property (nonatomic, assign) BOOL hasFinalBoundary;

@property (nonatomic, readonly, getter = hasBytesAvailable) BOOL bytesAvailable;
@property (nonatomic, readonly) unsigned long long contentLength;

- (NSInteger)read:(uint8_t *)buffer
        maxLength:(NSUInteger)length;
@end

@interface AFMultipartBodyStream : NSInputStream <NSStreamDelegate>
@property (nonatomic, assign) NSUInteger numberOfBytesInPacket;
@property (nonatomic, assign) NSTimeInterval delay;
@property (nonatomic, strong) NSInputStream *inputStream;
@property (nonatomic, readonly) unsigned long long contentLength;
@property (nonatomic, readonly, getter = isEmpty) BOOL empty;

- (id)initWithStringEncoding:(NSStringEncoding)encoding;
- (void)setInitialAndFinalBoundaries;
- (void)appendHTTPBodyPart:(AFHTTPBodyPart *)bodyPart;
@end

#pragma mark -

@interface AFStreamingMultipartFormData ()
@property (readwrite, nonatomic, copy) NSMutableURLRequest *request;
@property (readwrite, nonatomic, strong) AFMultipartBodyStream *bodyStream;
@property (readwrite, nonatomic, assign) NSStringEncoding stringEncoding;
@end

@implementation AFStreamingMultipartFormData

- (id)initWithURLRequest:(NSMutableURLRequest *)urlRequest
          stringEncoding:(NSStringEncoding)encoding
{
    self = [super init];
    if (!self) {
        return nil;
    }

    self.request = urlRequest;
    self.stringEncoding = encoding;
    self.bodyStream = [[AFMultipartBodyStream alloc] initWithStringEncoding:encoding];

    return self;
}

- (BOOL)appendPartWithFileURL:(NSURL *)fileURL
                         name:(NSString *)name
                        error:(NSError * __autoreleasing *)error
{
    NSParameterAssert(fileURL);
    NSParameterAssert(name);

    NSString *fileName = [fileURL lastPathComponent];
    NSString *mimeType = AFContentTypeForPathExtension([fileURL pathExtension]);

    return [self appendPartWithFileURL:fileURL name:name fileName:fileName mimeType:mimeType error:error];
}

- (BOOL)appendPartWithFileURL:(NSURL *)fileURL
                         name:(NSString *)name
                     fileName:(NSString *)fileName
                     mimeType:(NSString *)mimeType
                        error:(NSError * __autoreleasing *)error
{
    NSParameterAssert(fileURL);
    NSParameterAssert(name);
    NSParameterAssert(fileName);
    NSParameterAssert(mimeType);

    if (![fileURL isFileURL]) {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:NSLocalizedStringFromTable(@"Expected URL to be a file URL", @"AFNetworking", nil) forKey:NSLocalizedFailureReasonErrorKey];
        if (error != NULL) {
            *error = [[NSError alloc] initWithDomain:AFNetworkingErrorDomain code:NSURLErrorBadURL userInfo:userInfo];
        }

        return NO;
    } else if ([fileURL checkResourceIsReachableAndReturnError:error] == NO) {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:NSLocalizedStringFromTable(@"File URL not reachable.", @"AFNetworking", nil) forKey:NSLocalizedFailureReasonErrorKey];
        if (error != NULL) {
            *error = [[NSError alloc] initWithDomain:AFNetworkingErrorDomain code:NSURLErrorBadURL userInfo:userInfo];
        }

        return NO;
    }

    NSMutableDictionary *mutableHeaders = [NSMutableDictionary dictionary];
    [mutableHeaders setValue:[NSString stringWithFormat:@"form-data; name=\"%@\"; filename=\"%@\"", name, fileName] forKey:@"Content-Disposition"];
    [mutableHeaders setValue:mimeType forKey:@"Content-Type"];

    AFHTTPBodyPart *bodyPart = [[AFHTTPBodyPart alloc] init];
    bodyPart.stringEncoding = self.stringEncoding;
    bodyPart.headers = mutableHeaders;
    bodyPart.body = fileURL;

    NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[fileURL path] error:nil];
    bodyPart.bodyContentLength = [[fileAttributes objectForKey:NSFileSize] unsignedLongLongValue];

    [self.bodyStream appendHTTPBodyPart:bodyPart];

    return YES;
}


- (void)appendPartWithInputStream:(NSInputStream *)inputStream
                             name:(NSString *)name
                         fileName:(NSString *)fileName
                           length:(int64_t)length
                         mimeType:(NSString *)mimeType
{
    NSParameterAssert(name);
    NSParameterAssert(fileName);
    NSParameterAssert(mimeType);

    NSMutableDictionary *mutableHeaders = [NSMutableDictionary dictionary];
    [mutableHeaders setValue:[NSString stringWithFormat:@"form-data; name=\"%@\"; filename=\"%@\"", name, fileName] forKey:@"Content-Disposition"];
    [mutableHeaders setValue:mimeType forKey:@"Content-Type"];


    AFHTTPBodyPart *bodyPart = [[AFHTTPBodyPart alloc] init];
    bodyPart.stringEncoding = self.stringEncoding;
    bodyPart.headers = mutableHeaders;
    bodyPart.body = inputStream;

    bodyPart.bodyContentLength = length;

    [self.bodyStream appendHTTPBodyPart:bodyPart];
}

- (void)appendPartWithFileData:(NSData *)data
                          name:(NSString *)name
                      fileName:(NSString *)fileName
                      mimeType:(NSString *)mimeType
{
    NSParameterAssert(name);
    NSParameterAssert(fileName);
    NSParameterAssert(mimeType);

    NSMutableDictionary *mutableHeaders = [NSMutableDictionary dictionary];
    [mutableHeaders setValue:[NSString stringWithFormat:@"form-data; name=\"%@\"; filename=\"%@\"", name, fileName] forKey:@"Content-Disposition"];
    [mutableHeaders setValue:mimeType forKey:@"Content-Type"];

    [self appendPartWithHeaders:mutableHeaders body:data];
}

- (void)appendPartWithFormData:(NSData *)data
                          name:(NSString *)name
{
    NSParameterAssert(name);

    NSMutableDictionary *mutableHeaders = [NSMutableDictionary dictionary];
    [mutableHeaders setValue:[NSString stringWithFormat:@"form-data; name=\"%@\"", name] forKey:@"Content-Disposition"];

    [self appendPartWithHeaders:mutableHeaders body:data];
}

- (void)appendPartWithHeaders:(NSDictionary *)headers
                         body:(NSData *)body
{
    NSParameterAssert(body);

    AFHTTPBodyPart *bodyPart = [[AFHTTPBodyPart alloc] init];
    bodyPart.stringEncoding = self.stringEncoding;
    bodyPart.headers = headers;
    bodyPart.bodyContentLength = [body length];
    bodyPart.body = body;

    [self.bodyStream appendHTTPBodyPart:bodyPart];
}

- (void)throttleBandwidthWithPacketSize:(NSUInteger)numberOfBytes
                                  delay:(NSTimeInterval)delay
{
    self.bodyStream.numberOfBytesInPacket = numberOfBytes;
    self.bodyStream.delay = delay;
}

- (NSMutableURLRequest *)requestByFinalizingMultipartFormData {
    if ([self.bodyStream isEmpty]) {
        return self.request;
    }

    // Reset the initial and final boundaries to ensure correct Content-Length
    [self.bodyStream setInitialAndFinalBoundaries];

    [self.request setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", kAFMultipartFormBoundary] forHTTPHeaderField:@"Content-Type"];
    [self.request setValue:[NSString stringWithFormat:@"%llu", [self.bodyStream contentLength]] forHTTPHeaderField:@"Content-Length"];
    [self.request setHTTPBodyStream:self.bodyStream];

    return self.request;
}

@end

#pragma mark -

@interface AFMultipartBodyStream () <NSCopying>
@property (nonatomic, assign) NSStreamStatus streamStatus;
@property (nonatomic, strong) NSError *streamError;
@property (nonatomic, assign) NSStringEncoding stringEncoding;
@property (nonatomic, strong) NSMutableArray *HTTPBodyParts;
@property (nonatomic, strong) NSEnumerator *HTTPBodyPartEnumerator;
@property (nonatomic, strong) AFHTTPBodyPart *currentHTTPBodyPart;
@property (nonatomic, strong) NSOutputStream *outputStream;
@property (nonatomic, strong) NSMutableData *buffer;
@end

@implementation AFMultipartBodyStream

- (id)initWithStringEncoding:(NSStringEncoding)encoding {
    self = [super init];
    if (!self) {
        return nil;
    }

    self.stringEncoding = encoding;
    self.HTTPBodyParts = [NSMutableArray array];
    self.numberOfBytesInPacket = NSIntegerMax;

    return self;
}

- (void)setInitialAndFinalBoundaries {
    if ([self.HTTPBodyParts count] > 0) {
        for (AFHTTPBodyPart *bodyPart in self.HTTPBodyParts) {
            bodyPart.hasInitialBoundary = NO;
            bodyPart.hasFinalBoundary = NO;
        }

        [[self.HTTPBodyParts objectAtIndex:0] setHasInitialBoundary:YES];
        [[self.HTTPBodyParts lastObject] setHasFinalBoundary:YES];
    }
}

- (void)appendHTTPBodyPart:(AFHTTPBodyPart *)bodyPart {
    [self.HTTPBodyParts addObject:bodyPart];
}

- (BOOL)isEmpty {
    return [self.HTTPBodyParts count] == 0;
}

#pragma mark - NSInputStream

- (NSInteger)read:(uint8_t *)buffer
        maxLength:(NSUInteger)length
{
    if ([self streamStatus] == NSStreamStatusClosed) {
        return 0;
    }

    NSInteger totalNumberOfBytesRead = 0;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wgnu"
    while ((NSUInteger)totalNumberOfBytesRead < MIN(length, self.numberOfBytesInPacket)) {
        if (!self.currentHTTPBodyPart || ![self.currentHTTPBodyPart hasBytesAvailable]) {
            if (!(self.currentHTTPBodyPart = [self.HTTPBodyPartEnumerator nextObject])) {
                break;
            }
        } else {
            NSUInteger maxLength = length - (NSUInteger)totalNumberOfBytesRead;
            NSInteger numberOfBytesRead = [self.currentHTTPBodyPart read:&buffer[totalNumberOfBytesRead] maxLength:maxLength];
            if (numberOfBytesRead == -1) {
                self.streamError = self.currentHTTPBodyPart.inputStream.streamError;
                break;
            } else {
                totalNumberOfBytesRead += numberOfBytesRead;

                if (self.delay > 0.0f) {
                    [NSThread sleepForTimeInterval:self.delay];
                }
            }
        }
    }
#pragma clang diagnostic pop

    return totalNumberOfBytesRead;
}

- (BOOL)getBuffer:(__unused uint8_t **)buffer
           length:(__unused NSUInteger *)len
{
    return NO;
}

- (BOOL)hasBytesAvailable {
    return [self streamStatus] == NSStreamStatusOpen;
}

#pragma mark - NSStream

- (void)open {
    if (self.streamStatus == NSStreamStatusOpen) {
        return;
    }

    self.streamStatus = NSStreamStatusOpen;

    [self setInitialAndFinalBoundaries];
    self.HTTPBodyPartEnumerator = [self.HTTPBodyParts objectEnumerator];
}

- (void)close {
    self.streamStatus = NSStreamStatusClosed;
}

- (id)propertyForKey:(__unused NSString *)key {
    return nil;
}

- (BOOL)setProperty:(__unused id)property
             forKey:(__unused NSString *)key
{
    return NO;
}

- (void)scheduleInRunLoop:(__unused NSRunLoop *)aRunLoop
                  forMode:(__unused NSString *)mode
{}

- (void)removeFromRunLoop:(__unused NSRunLoop *)aRunLoop
                  forMode:(__unused NSString *)mode
{}

- (unsigned long long)contentLength {
    unsigned long long length = 0;
    for (AFHTTPBodyPart *bodyPart in self.HTTPBodyParts) {
        length += [bodyPart contentLength];
    }

    return length;
}

#pragma mark - Undocumented CFReadStream Bridged Methods

- (void)_scheduleInCFRunLoop:(__unused CFRunLoopRef)aRunLoop
                     forMode:(__unused CFStringRef)aMode
{}

- (void)_unscheduleFromCFRunLoop:(__unused CFRunLoopRef)aRunLoop
                         forMode:(__unused CFStringRef)aMode
{}

- (BOOL)_setCFClientFlags:(__unused CFOptionFlags)inFlags
                 callback:(__unused CFReadStreamClientCallBack)inCallback
                  context:(__unused CFStreamClientContext *)inContext {
    return NO;
}

#pragma mark - NSCopying

-(id)copyWithZone:(NSZone *)zone {
    AFMultipartBodyStream *bodyStreamCopy = [[[self class] allocWithZone:zone] initWithStringEncoding:self.stringEncoding];

    for (AFHTTPBodyPart *bodyPart in self.HTTPBodyParts) {
        [bodyStreamCopy appendHTTPBodyPart:[bodyPart copy]];
    }

    [bodyStreamCopy setInitialAndFinalBoundaries];

    return bodyStreamCopy;
}

@end

#pragma mark -

typedef enum {
    AFEncapsulationBoundaryPhase = 1,
    AFHeaderPhase                = 2,
    AFBodyPhase                  = 3,
    AFFinalBoundaryPhase         = 4,
} AFHTTPBodyPartReadPhase;

@interface AFHTTPBodyPart () <NSCopying> {
    AFHTTPBodyPartReadPhase _phase;
    NSInputStream *_inputStream;
    unsigned long long _phaseReadOffset;
}

- (BOOL)transitionToNextPhase;
- (NSInteger)readData:(NSData *)data
           intoBuffer:(uint8_t *)buffer
            maxLength:(NSUInteger)length;
@end

@implementation AFHTTPBodyPart

- (id)init {
    self = [super init];
    if (!self) {
        return nil;
    }

    [self transitionToNextPhase];

    return self;
}

- (void)dealloc {
    if (_inputStream) {
        [_inputStream close];
        _inputStream = nil;
    }
}

- (NSInputStream *)inputStream {
    if (!_inputStream) {
        if ([self.body isKindOfClass:[NSData class]]) {
            _inputStream = [NSInputStream inputStreamWithData:self.body];
        } else if ([self.body isKindOfClass:[NSURL class]]) {
            _inputStream = [NSInputStream inputStreamWithURL:self.body];
        } else if ([self.body isKindOfClass:[NSInputStream class]]) {
            _inputStream = self.body;
        }
    }

    return _inputStream;
}

- (NSString *)stringForHeaders {
    NSMutableString *headerString = [NSMutableString string];
    for (NSString *field in [self.headers allKeys]) {
        [headerString appendString:[NSString stringWithFormat:@"%@: %@%@", field, [self.headers valueForKey:field], kAFMultipartFormCRLF]];
    }
    [headerString appendString:kAFMultipartFormCRLF];

    return [NSString stringWithString:headerString];
}

- (unsigned long long)contentLength {
    unsigned long long length = 0;

    NSData *encapsulationBoundaryData = [([self hasInitialBoundary] ? AFMultipartFormInitialBoundary() : AFMultipartFormEncapsulationBoundary()) dataUsingEncoding:self.stringEncoding];
    length += [encapsulationBoundaryData length];

    NSData *headersData = [[self stringForHeaders] dataUsingEncoding:self.stringEncoding];
    length += [headersData length];

    length += _bodyContentLength;

    NSData *closingBoundaryData = ([self hasFinalBoundary] ? [AFMultipartFormFinalBoundary() dataUsingEncoding:self.stringEncoding] : [NSData data]);
    length += [closingBoundaryData length];

    return length;
}

- (BOOL)hasBytesAvailable {
    // Allows `read:maxLength:` to be called again if `AFMultipartFormFinalBoundary` doesn't fit into the available buffer
    if (_phase == AFFinalBoundaryPhase) {
        return YES;
    }

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wcovered-switch-default"
    switch (self.inputStream.streamStatus) {
        case NSStreamStatusNotOpen:
        case NSStreamStatusOpening:
        case NSStreamStatusOpen:
        case NSStreamStatusReading:
        case NSStreamStatusWriting:
            return YES;
        case NSStreamStatusAtEnd:
        case NSStreamStatusClosed:
        case NSStreamStatusError:
        default:
            return NO;
    }
#pragma clang diagnostic pop
}

- (NSInteger)read:(uint8_t *)buffer
        maxLength:(NSUInteger)length
{
    NSInteger totalNumberOfBytesRead = 0;

    if (_phase == AFEncapsulationBoundaryPhase) {
        NSData *encapsulationBoundaryData = [([self hasInitialBoundary] ? AFMultipartFormInitialBoundary() : AFMultipartFormEncapsulationBoundary()) dataUsingEncoding:self.stringEncoding];
        totalNumberOfBytesRead += [self readData:encapsulationBoundaryData intoBuffer:&buffer[totalNumberOfBytesRead] maxLength:(length - (NSUInteger)totalNumberOfBytesRead)];
    }

    if (_phase == AFHeaderPhase) {
        NSData *headersData = [[self stringForHeaders] dataUsingEncoding:self.stringEncoding];
        totalNumberOfBytesRead += [self readData:headersData intoBuffer:&buffer[totalNumberOfBytesRead] maxLength:(length - (NSUInteger)totalNumberOfBytesRead)];
    }

    if (_phase == AFBodyPhase) {
        NSInteger numberOfBytesRead = 0;

        numberOfBytesRead = [self.inputStream read:&buffer[totalNumberOfBytesRead] maxLength:(length - (NSUInteger)totalNumberOfBytesRead)];
        if (numberOfBytesRead == -1) {
            return -1;
        } else {
            totalNumberOfBytesRead += numberOfBytesRead;

            if ([self.inputStream streamStatus] >= NSStreamStatusAtEnd) {
                [self transitionToNextPhase];
            }
        }
    }

    if (_phase == AFFinalBoundaryPhase) {
        NSData *closingBoundaryData = ([self hasFinalBoundary] ? [AFMultipartFormFinalBoundary() dataUsingEncoding:self.stringEncoding] : [NSData data]);
        totalNumberOfBytesRead += [self readData:closingBoundaryData intoBuffer:&buffer[totalNumberOfBytesRead] maxLength:(length - (NSUInteger)totalNumberOfBytesRead)];
    }

    return totalNumberOfBytesRead;
}

- (NSInteger)readData:(NSData *)data
           intoBuffer:(uint8_t *)buffer
            maxLength:(NSUInteger)length
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wgnu"
    NSRange range = NSMakeRange((NSUInteger)_phaseReadOffset, MIN([data length] - ((NSUInteger)_phaseReadOffset), length));
    [data getBytes:buffer range:range];
#pragma clang diagnostic pop

    _phaseReadOffset += range.length;

    if (((NSUInteger)_phaseReadOffset) >= [data length]) {
        [self transitionToNextPhase];
    }

    return (NSInteger)range.length;
}

- (BOOL)transitionToNextPhase {
    if (![[NSThread currentThread] isMainThread]) {
        [self performSelectorOnMainThread:@selector(transitionToNextPhase) withObject:nil waitUntilDone:YES];
        return YES;
    }

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wcovered-switch-default"
    switch (_phase) {
        case AFEncapsulationBoundaryPhase:
            _phase = AFHeaderPhase;
            break;
        case AFHeaderPhase:
            [self.inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
            [self.inputStream open];
            _phase = AFBodyPhase;
            break;
        case AFBodyPhase:
            [self.inputStream close];
            _phase = AFFinalBoundaryPhase;
            break;
        case AFFinalBoundaryPhase:
        default:
            _phase = AFEncapsulationBoundaryPhase;
            break;
    }
    _phaseReadOffset = 0;
#pragma clang diagnostic pop

    return YES;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    AFHTTPBodyPart *bodyPart = [[[self class] allocWithZone:zone] init];
    
    bodyPart.stringEncoding = self.stringEncoding;
    bodyPart.headers = self.headers;
    bodyPart.bodyContentLength = self.bodyContentLength;
    bodyPart.body = self.body;
    
    return bodyPart;
}

@end

#pragma mark -

@implementation AFJSONRequestSerializer

+ (instancetype)serializer {
    return [self serializerWithWritingOptions:0];
}

+ (instancetype)serializerWithWritingOptions:(NSJSONWritingOptions)writingOptions
{
    AFJSONRequestSerializer *serializer = [[self alloc] init];
    serializer.writingOptions = writingOptions;

    return serializer;
}

#pragma mark - AFURLRequestSerialization

- (NSURLRequest *)requestBySerializingRequest:(NSURLRequest *)request
                               withParameters:(NSDictionary *)parameters
                                        error:(NSError *__autoreleasing *)error
{
    NSParameterAssert(request);

    if ([self.HTTPMethodsEncodingParametersInURI containsObject:[[request HTTPMethod] uppercaseString]]) {
        return [super requestBySerializingRequest:request withParameters:parameters error:error];
    }

    NSMutableURLRequest *mutableRequest = [request mutableCopy];

    [self.HTTPRequestHeaders enumerateKeysAndObjectsUsingBlock:^(id field, id value, BOOL * __unused stop) {
        if (![request valueForHTTPHeaderField:field]) {
            [mutableRequest setValue:value forHTTPHeaderField:field];
        }
    }];
    
    if (!parameters) {
        return mutableRequest;
    }

    NSString *charset = (__bridge NSString *)CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));

    [mutableRequest setValue:[NSString stringWithFormat:@"application/json; charset=%@", charset] forHTTPHeaderField:@"Content-Type"];
    [mutableRequest setHTTPBody:[NSJSONSerialization dataWithJSONObject:parameters options:self.writingOptions error:error]];

    return mutableRequest;
}

@end

#pragma mark -

@implementation AFPropertyListRequestSerializer

+ (instancetype)serializer {
    return [self serializerWithFormat:NSPropertyListXMLFormat_v1_0 writeOptions:0];
}

+ (instancetype)serializerWithFormat:(NSPropertyListFormat)format
                        writeOptions:(NSPropertyListWriteOptions)writeOptions
{
    AFPropertyListRequestSerializer *serializer = [[self alloc] init];
    serializer.format = format;
    serializer.writeOptions = writeOptions;

    return serializer;
}

#pragma mark - AFURLRequestSerializer

- (NSURLRequest *)requestBySerializingRequest:(NSURLRequest *)request
                               withParameters:(NSDictionary *)parameters
                                        error:(NSError *__autoreleasing *)error
{
    NSParameterAssert(request);

    if ([self.HTTPMethodsEncodingParametersInURI containsObject:[[request HTTPMethod] uppercaseString]]) {
        return [super requestBySerializingRequest:request withParameters:parameters error:error];
    }

    NSMutableURLRequest *mutableRequest = [request mutableCopy];

    [self.HTTPRequestHeaders enumerateKeysAndObjectsUsingBlock:^(id field, id value, BOOL * __unused stop) {
        if (![request valueForHTTPHeaderField:field]) {
            [mutableRequest setValue:value forHTTPHeaderField:field];
        }
    }];

    NSString *charset = (__bridge NSString *)CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));

    [mutableRequest setValue:[NSString stringWithFormat:@"application/x-plist; charset=%@", charset] forHTTPHeaderField:@"Content-Type"];
    [mutableRequest setHTTPBody:[NSPropertyListSerialization dataWithPropertyList:parameters format:self.format options:self.writeOptions error:error]];

    return mutableRequest;
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (!self) {
        return nil;
    }

    self.format = (NSPropertyListFormat)[aDecoder decodeIntegerForKey:@"format"];
    self.writeOptions = [aDecoder decodeIntegerForKey:@"writeOptions"];

    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];

    [aCoder encodeInteger:self.format forKey:@"format"];
    [aCoder encodeInteger:(NSInteger)self.writeOptions forKey:@"writeOptions"];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    AFPropertyListRequestSerializer *serializer = [[[self class] allocWithZone:zone] init];
    serializer.format = self.format;
    serializer.writeOptions = self.writeOptions;

    return serializer;
}

@end
