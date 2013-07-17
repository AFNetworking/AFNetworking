// AFSerialization.m
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

#import "AFSerialization.h"

typedef NSString * (^AFQueryStringSerializationBlock)(NSURLRequest *request, NSDictionary *parameters, NSError *__autoreleasing *error);

static NSString * AFStringFromIndexSet(NSIndexSet *indexSet) {
    NSMutableString *string = [NSMutableString string];

    NSRange range = NSMakeRange([indexSet firstIndex], 1);
    while (range.location != NSNotFound) {
        NSUInteger nextIndex = [indexSet indexGreaterThanIndex:range.location];
        while (nextIndex == range.location + range.length) {
            range.length++;
            nextIndex = [indexSet indexGreaterThanIndex:nextIndex];
        }

        if (string.length) {
            [string appendString:@","];
        }

        if (range.length == 1) {
            [string appendFormat:@"%lu", (long)range.location];
        } else {
            NSUInteger firstIndex = range.location;
            NSUInteger lastIndex = firstIndex + range.length - 1;
            [string appendFormat:@"%lu-%lu", (long)firstIndex, (long)lastIndex];
        }

        range.location = nextIndex;
        range.length = 1;
    }
    
    return string;
}

#pragma mark -

extern NSArray * AFQueryStringPairsFromDictionary(NSDictionary *dictionary);
extern NSArray * AFQueryStringPairsFromKeyAndValue(NSString *key, id value);

NSString * AFQueryStringFromParametersWithEncoding(NSDictionary *parameters) {
    return [AFQueryStringPairsFromDictionary(parameters) componentsJoinedByString:@"&"];
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
        [mutableQueryStringComponents addObject:[NSString stringWithFormat:@"%@=%@", key, value]];
    }

    return mutableQueryStringComponents;
}

#pragma mark -

@interface AFHTTPSerializer ()
@property (readwrite, nonatomic, strong) NSMutableDictionary *mutableHTTPRequestHeaders;
@property (readwrite, nonatomic, assign) AFHTTPRequestQueryStringSerializationStyle queryStringSerializationStyle;
@property (readwrite, nonatomic, copy) AFQueryStringSerializationBlock queryStringSerialization;
@end

@implementation AFHTTPSerializer

+ (instancetype)serializer {
    return [[self alloc] init];
}

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }

    self.mutableHTTPRequestHeaders = [NSMutableDictionary dictionary];

    // Accept-Language HTTP Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.4
    NSMutableArray *acceptLanguagesComponents = [NSMutableArray array];
    [[NSLocale preferredLanguages] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        float q = 1.0f - (idx * 0.1f);
        [acceptLanguagesComponents addObject:[NSString stringWithFormat:@"%@;q=%0.1g", obj, q]];
        *stop = q <= 0.5f;
    }];
    [self setValue:[acceptLanguagesComponents componentsJoinedByString:@", "] forHTTPHeaderField:@"Accept-Language"];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wgnu"
#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
    // User-Agent Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.43
    [self setValue:[NSString stringWithFormat:@"%@/%@ (%@; iOS %@; Scale/%0.2f)", [[[NSBundle mainBundle] infoDictionary] objectForKey:(__bridge NSString *)kCFBundleExecutableKey] ?: [[[NSBundle mainBundle] infoDictionary] objectForKey:(__bridge NSString *)kCFBundleIdentifierKey], (__bridge id)CFBundleGetValueForInfoDictionaryKey(CFBundleGetMainBundle(), kCFBundleVersionKey) ?: [[[NSBundle mainBundle] infoDictionary] objectForKey:(__bridge NSString *)kCFBundleVersionKey], [[UIDevice currentDevice] model], [[UIDevice currentDevice] systemVersion], ([[UIScreen mainScreen] respondsToSelector:@selector(scale)] ? [[UIScreen mainScreen] scale] : 1.0f)] forHTTPHeaderField:@"User-Agent"];
#elif defined(__MAC_OS_X_VERSION_MIN_REQUIRED)
    [self setValue:[NSString stringWithFormat:@"%@/%@ (Mac OS X %@)", [[[NSBundle mainBundle] infoDictionary] objectForKey:(__bridge NSString *)kCFBundleExecutableKey] ?: [[[NSBundle mainBundle] infoDictionary] objectForKey:(__bridge NSString *)kCFBundleIdentifierKey], [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"] ?: [[[NSBundle mainBundle] infoDictionary] objectForKey:(__bridge NSString *)kCFBundleVersionKey], [[NSProcessInfo processInfo] operatingSystemVersionString]] forHTTPHeaderField:@"User-Agent"];
#endif
#pragma clang diagnostic pop

    self.acceptableStatusCodes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(200, 100)];
    self.acceptableContentTypes = nil;

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
    [self setValue:[NSString stringWithFormat:@"Basic %@", [[basicAuthCredentials dataUsingEncoding:NSUTF8StringEncoding] base64Encoding]] forHTTPHeaderField:@"Authorization"];
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

- (BOOL)validateResponse:(NSHTTPURLResponse *)response
                    data:(NSData *)data
                   error:(NSError *__autoreleasing *)error
{
    if (![response isKindOfClass:[NSHTTPURLResponse class]]) {
        return NO;
    }

    if (self.acceptableStatusCodes && ![self.acceptableStatusCodes containsIndex:response.statusCode]) {
        NSDictionary *userInfo = @{
                                   NSLocalizedDescriptionKey: [NSString stringWithFormat:NSLocalizedStringFromTable(@"Expected status code in (%@), got %d", @"AFNetworking", nil), AFStringFromIndexSet(self.acceptableStatusCodes), response.statusCode],
                                   NSURLErrorFailingURLErrorKey:[response URL],
                                   AFNetworkingOperationFailingURLResponseErrorKey: response
                                  };
        *error = [[NSError alloc] initWithDomain:AFNetworkingErrorDomain code:NSURLErrorBadServerResponse userInfo:userInfo];
    } else if (self.acceptableContentTypes && ![self.acceptableContentTypes containsObject:[response MIMEType]]) {
        // Don't invalidate content type if there is no content
        if ([data length] > 0) {
            NSDictionary *userInfo = @{
                                        NSLocalizedDescriptionKey: [NSString stringWithFormat:NSLocalizedStringFromTable(@"Expected content type %@, got %@", @"AFNetworking", nil), self.acceptableContentTypes, [response MIMEType]],
                                        NSURLErrorFailingURLErrorKey:[response URL],
                                        AFNetworkingOperationFailingURLResponseErrorKey: response
                                      };
            *error = [[NSError alloc] initWithDomain:AFNetworkingErrorDomain code:NSURLErrorCannotDecodeContentData userInfo:userInfo];
        }
    }

    return YES;
}

#pragma mark - AFURLRequestSerializer

- (NSURLRequest *)requestBySerializingRequest:(NSURLRequest *)request
                               withParameters:(NSDictionary *)parameters
                                        error:(NSError *__autoreleasing *)error
{
    NSParameterAssert(request);

    if (!parameters) {
        return request;
    }

    NSMutableURLRequest *mutableRequest = [request mutableCopy];

    NSString *query = nil;
    if (self.queryStringSerialization) {
        query = self.queryStringSerialization(request, parameters, error);
    } else {
        switch (self.queryStringSerializationStyle) {
            case AFHTTPRequestQueryStringDefaultStyle:
                query = AFQueryStringFromParametersWithEncoding(parameters);
                break;
            default:
                break;
        }
    }

    if ([self.HTTPMethodsEncodingParametersInURI containsObject:[[request HTTPMethod] uppercaseString]]) {
        NSURLComponents *components = [NSURLComponents componentsWithString:[[request URL] absoluteString]];
        components.query = components.query ? [components.query stringByAppendingFormat:@"&%@", query] : query;

        mutableRequest.URL = [components URL];
    } else {
        NSString *charset = (__bridge NSString *)CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(self.stringEncoding));
        [mutableRequest setValue:[NSString stringWithFormat:@"application/x-www-form-urlencoded; charset=%@", charset] forHTTPHeaderField:@"Content-Type"];
        [mutableRequest setHTTPBody:[query dataUsingEncoding:self.stringEncoding]];
    }

    return mutableRequest;
}

#pragma mark - AFURLResponseSerializer

- (BOOL)canProcessResponse:(NSHTTPURLResponse *)response {
    return YES;
}

- (id)responseObjectForResponse:(NSURLResponse *)response
                           data:(NSData *)data
                          error:(NSError *__autoreleasing *)error
{
    [self validateResponse:(NSHTTPURLResponse *)response data:data error:error];

    return data;
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [self init];
    if (!self) {
        return nil;
    }

    self.mutableHTTPRequestHeaders = [aDecoder decodeObjectForKey:@"mutableHTTPRequestHeaders"];
    self.queryStringSerializationStyle = [aDecoder decodeIntegerForKey:@"queryStringSerializationStyle"];

    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.mutableHTTPRequestHeaders forKey:@"mutableHTTPRequestHeaders"];
    [aCoder encodeInteger:self.queryStringSerializationStyle forKey:@"queryStringSerializationStyle"];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    AFHTTPSerializer *serializer = [[[self class] allocWithZone:zone] init];
    serializer.mutableHTTPRequestHeaders = [self.mutableHTTPRequestHeaders copy];
    serializer.queryStringSerializationStyle = self.queryStringSerializationStyle;
    serializer.queryStringSerialization = self.queryStringSerialization;
    
    return serializer;
}

@end

#pragma mark -

@implementation AFJSONSerializer

+ (instancetype)serializer {
    return [self serializerWithReadingOptions:0 writingOptions:0];
}

+ (instancetype)serializerWithReadingOptions:(NSJSONReadingOptions)readingOptions
                              writingOptions:(NSJSONWritingOptions)writingOptions
{
    AFJSONSerializer *serializer = [[self alloc] init];
    serializer.readingOptions = readingOptions;
    serializer.writingOptions = writingOptions;

    return serializer;
}

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }

    self.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript", nil];

    return self;
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

    NSString *charset = (__bridge NSString *)CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));

    [mutableRequest setValue:[NSString stringWithFormat:@"application/json; charset=%@", charset] forHTTPHeaderField:@"Content-Type"];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wassign-enum"
    [mutableRequest setHTTPBody:[NSJSONSerialization dataWithJSONObject:parameters options:self.writingOptions error:error]];
#pragma clang diagnostic pop

    return mutableRequest;
}

#pragma mark - AFURLRequestSerialization

- (BOOL)canProcessResponse:(NSHTTPURLResponse *)response {
    return [[[response URL] pathExtension] isEqualToString:@"json"] || [super canProcessResponse:response];
}

- (id)responseObjectForResponse:(NSURLResponse *)response
                           data:(NSData *)data
                          error:(NSError *__autoreleasing *)error
{
    // Workaround for behavior of Rails to return a single space for `head :ok` (a workaround for a bug in Safari), which is not interpreted as valid input by NSJSONSerialization.
    // See https://github.com/rails/rails/issues/1742
    NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (responseString && ![responseString isEqualToString:@" "]) {
        // Workaround for a bug in NSJSONSerialization when Unicode character escape codes are used instead of the actual character
        // See http://stackoverflow.com/a/12843465/157142
        data = [responseString dataUsingEncoding:NSUTF8StringEncoding];

        if (data) {
            return [NSJSONSerialization JSONObjectWithData:data options:self.readingOptions error:error];
        } else {
            NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
            [userInfo setValue:NSLocalizedStringFromTable(@"Data failed decoding as a UTF-8 string", nil, @"AFNetworking") forKey:NSLocalizedDescriptionKey];
            [userInfo setValue:[NSString stringWithFormat:NSLocalizedStringFromTable(@"Could not decode string: %@", nil, @"AFNetworking"), responseString] forKey:NSLocalizedFailureReasonErrorKey];
            *error = [[NSError alloc] initWithDomain:AFNetworkingErrorDomain code:NSURLErrorCannotDecodeContentData userInfo:userInfo];
        }
    }

    return nil;
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (!self) {
        return nil;
    }

    self.readingOptions = [aDecoder decodeIntegerForKey:@"readingOptions"];
    self.writingOptions = [aDecoder decodeIntegerForKey:@"writingOptions"];

    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    
    [aCoder encodeInteger:self.readingOptions forKey:@"readingOptions"];
    [aCoder encodeInteger:self.writingOptions forKey:@"writingOptions"];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    AFJSONSerializer *serializer = [[[self class] allocWithZone:zone] init];
    serializer.readingOptions = self.readingOptions;
    serializer.writingOptions = self.writingOptions;

    return serializer;
}

@end

#pragma mark -

@implementation AFXMLParserSerializer

+ (instancetype)serializer {
    AFXMLParserSerializer *serializer = [[self alloc] init];

    return serializer;
}

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }

    self.acceptableContentTypes = [[NSSet alloc] initWithObjects:@"application/xml", @"text/xml", nil];

    return self;
}

#pragma mark AFHTTPResponseSerializer

- (BOOL)canProcessResponse:(NSHTTPURLResponse *)response {
    return [[[response URL] pathExtension] isEqualToString:@"xml"] || [super canProcessResponse:response];
}

- (id)responseObjectForResponse:(NSHTTPURLResponse *)response
                           data:(NSData *)data
                          error:(NSError *__autoreleasing *)error
{
    return [[NSXMLParser alloc] initWithData:data];
}

@end

#pragma mark -

#ifdef __MAC_OS_X_VERSION_MIN_REQUIRED

@implementation AFXMLDocumentSerializer

+ (instancetype)serializer {
    return [self serializerWithXMLDocumentOptions:0];
}

+ (instancetype)serializerWithXMLDocumentOptions:(NSUInteger)mask {
    AFXMLDocumentSerializer *serializer = [[self alloc] init];
    serializer.options = mask;
    
    return serializer;
}

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }

    self.acceptableContentTypes = [[NSSet alloc] initWithObjects:@"application/xml", @"text/xml", nil];

    return self;
}

#pragma mark AFHTTPResponseSerializer

- (BOOL)canProcessResponse:(NSHTTPURLResponse *)response {
    return [[[response URL] pathExtension] isEqualToString:@"xml"] || [super canProcessResponse:response];
}

- (id)responseObjectForResponse:(NSURLResponse *)response
                           data:(NSData *)data
                          error:(NSError *__autoreleasing *)error
{
    return [[NSXMLDocument alloc] initWithData:data options:self.options error:error];
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (!self) {
        return nil;
    }

    self.options = [aDecoder decodeIntegerForKey:@"options"];

    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];

    [aCoder encodeInteger:self.options forKey:@"options"];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    AFXMLDocumentSerializer *serializer = [[[self class] allocWithZone:zone] init];
    serializer.options = self.options;

    return serializer;
}

@end

#endif

#pragma mark -

@implementation AFPropertyListSerializer

+ (instancetype)serializer {
    return [self serializerWithFormat:NSPropertyListXMLFormat_v1_0 readOptions:0 writeOptions:0];
}

+ (instancetype)serializerWithFormat:(NSPropertyListFormat)format
                         readOptions:(NSPropertyListReadOptions)readOptions
                        writeOptions:(NSPropertyListWriteOptions)writeOptions
{
    AFPropertyListSerializer *serializer = [[self alloc] init];
    serializer.format = format;
    serializer.readOptions = readOptions;
    serializer.writeOptions = writeOptions;

    return serializer;
}

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }

    self.acceptableContentTypes = [[NSSet alloc] initWithObjects:@"application/x-plist", nil];

    return self;
}

+ (NSSet *)acceptablePathExtensions {
    static NSSet * _acceptablePathExtension = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _acceptablePathExtension = [[NSSet alloc] initWithObjects:@"plist", nil];
    });

    return _acceptablePathExtension;
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

    NSString *charset = (__bridge NSString *)CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));

    [mutableRequest setValue:[NSString stringWithFormat:@"application/x-plist; charset=%@", charset] forHTTPHeaderField:@"Content-Type"];
    [mutableRequest setHTTPBody:[NSPropertyListSerialization dataWithPropertyList:parameters format:self.format options:self.writeOptions error:error]];

    return mutableRequest;
}

#pragma mark - AFURLResponseSerializer

- (BOOL)canProcessResponse:(NSHTTPURLResponse *)response {
    return [[[response URL] pathExtension] isEqualToString:@"plist"] || [super canProcessResponse:response];
}

- (id)responseObjectForResponse:(NSURLResponse *)response
                           data:(NSData *)data
                          error:(NSError *__autoreleasing *)error
{
    return [NSPropertyListSerialization propertyListWithData:data options:self.readOptions format:nil error:error];
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (!self) {
        return nil;
    }

    self.format = [aDecoder decodeIntegerForKey:@"format"];
    self.readOptions = [aDecoder decodeIntegerForKey:@"readOptions"];
    self.writeOptions = [aDecoder decodeIntegerForKey:@"writeOptions"];

    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    
    [aCoder encodeInteger:self.format forKey:@"format"];
    [aCoder encodeInteger:self.readOptions forKey:@"readOptions"];
    [aCoder encodeInteger:self.writeOptions forKey:@"writeOptions"];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    AFPropertyListSerializer *serializer = [[[self class] allocWithZone:zone] init];
    serializer.format = self.format;
    serializer.readOptions = self.readOptions;
    serializer.writeOptions = self.writeOptions;

    return serializer;
}

@end

#pragma mark -

@implementation AFImageSerializer

+ (instancetype)serializer {
    AFImageSerializer *serializer = [[self alloc] init];
    serializer.imageScale = [[UIScreen mainScreen] scale];
    serializer.automaticallyInflatesResponseImage = YES;

    return serializer;
}

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }

    self.acceptableContentTypes = [[NSSet alloc] initWithObjects:@"image/tiff", @"image/jpeg", @"image/gif", @"image/png", @"image/ico", @"image/x-icon", @"image/bmp", @"image/x-bmp", @"image/x-xbitmap", @"image/x-win-bitmap", nil];

    return self;
}

+ (NSSet *)acceptablePathExtensions {
    static NSSet * _acceptablePathExtension = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _acceptablePathExtension = [[NSSet alloc] initWithObjects:@"tif", @"tiff", @"jpg", @"jpeg", @"gif", @"png", @"ico", @"bmp", @"cur", nil];
    });

    return _acceptablePathExtension;
}

#pragma mark -

- (BOOL)canProcessResponse:(NSHTTPURLResponse *)response {
    return [[[self class] acceptablePathExtensions] containsObject:[[response URL] pathExtension]] || [super canProcessResponse:response];
}

- (id)responseObjectForResponse:(NSURLResponse *)response
                           data:(NSData *)data
                          error:(NSError *__autoreleasing *)error
{
#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
    return [[UIImage alloc] initWithData:data scale:self.imageScale]; // TODO port AFImageReqOp implementation
#elif defined(__MAC_OS_X_VERSION_MIN_REQUIRED)
    // Ensure that the image is set to it's correct pixel width and height
    NSBitmapImageRep *bitimage = [[NSBitmapImageRep alloc] initWithData:data];
    NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize([bitimage pixelsWide], [bitimage pixelsHigh])];
    [image addRepresentation:bitimage];

    return image;
#endif

    return nil;
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (!self) {
        return nil;
    }

    self.imageScale = [aDecoder decodeFloatForKey:@"imageScale"];
    self.automaticallyInflatesResponseImage = [aDecoder decodeBoolForKey:@"automaticallyInflatesResponseImage"];

    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];

    [aCoder encodeFloat:self.imageScale forKey:@"imageScale"];
    [aCoder encodeBool:self.automaticallyInflatesResponseImage forKey:@"automaticallyInflatesResponseImage"];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    AFImageSerializer *serializer = [[[self class] allocWithZone:zone] init];
    serializer.imageScale = self.imageScale;
    serializer.automaticallyInflatesResponseImage = self.automaticallyInflatesResponseImage;

    return serializer;
}

@end
