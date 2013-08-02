// AFEventSource.m
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

#import "AFEventSource.h"

typedef void (^AFServerSentEventBlock)(AFServerSentEvent *event);

NSString * const AFEventSourceErrorDomain = @"com.alamofire.networking.event-source.error";

static NSString * const AFEventSourceLockName = @"com.alamofire.networking.event-source.lock";

static NSDictionary * AFServerSentEventFieldsFromData(NSData *data, NSError * __autoreleasing *error) {
    if (!data || [data length] == 0) {
        return nil;
    }

    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSMutableDictionary *mutableFields = [NSMutableDictionary dictionary];

    for (NSString *line in [string componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]]) {
        if (!line || [line length] == 0) {
            continue;
        }

        @autoreleasepool {
            NSScanner *scanner = [[NSScanner alloc] initWithString:line];
            scanner.charactersToBeSkipped = [NSCharacterSet whitespaceCharacterSet];
            NSString *key, *value;
            [scanner scanUpToString:@":" intoString:&key];
            [scanner scanString:@":" intoString:nil];
            [scanner scanUpToString:@"\n" intoString:&value];

            if (key && value) {
                if (mutableFields[key]) {
                    mutableFields[key] = [mutableFields[key] stringByAppendingFormat:@"\n%@", value];
                } else {
                    mutableFields[key] = value;
                }
            }
        }
    }

    return mutableFields;
}

@implementation AFServerSentEvent

+ (instancetype)eventWithFields:(NSDictionary *)fields {
    if (!fields) {
        return nil;
    }

    AFServerSentEvent *event = [[self alloc] init];

    NSMutableDictionary *mutableFields = [NSMutableDictionary dictionaryWithDictionary:fields];
    event.event = mutableFields[@"event"];
    event.identifier = mutableFields[@"id"];
    event.data = [mutableFields[@"data"] dataUsingEncoding:NSUTF8StringEncoding];
    event.retry = [mutableFields[@"retry"] integerValue];

    [mutableFields removeObjectsForKeys:@[@"event", @"id", @"data", @"retry"]];
    event.userInfo = mutableFields;

    return event;
}

@end

#pragma mark -

typedef NS_ENUM(NSUInteger, AFEventSourceState) {
    AFEventSourceConnecting = 0,
    AFEventSourceOpen = 1,
    AFEventSourceClosed = 2,
};

@interface AFEventSource () <NSStreamDelegate>
@property (readwrite, nonatomic, strong) AFHTTPRequestOperation *requestOperation;
@property (readwrite, nonatomic, assign) AFEventSourceState state;
@property (readwrite, nonatomic, strong) NSURLRequest *request;
@property (readwrite, nonatomic, strong) NSHTTPURLResponse *lastResponse;
@property (readwrite, nonatomic, strong) AFServerSentEvent *lastEvent;
@property (readwrite, nonatomic, strong) NSMapTable *listenersKeyedByEvent;
@property (readwrite, nonatomic, strong) NSOutputStream *outputStream;
@property (readwrite, nonatomic, assign) NSUInteger offset;
@property (readwrite, nonatomic, strong) NSRecursiveLock *lock;
@end

@implementation AFEventSource

- (instancetype)initWithURL:(NSURL *)url {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setValue:@"text/event-stream" forHTTPHeaderField:@"Accept"];

    return [self initWithRequest:request];
}

- (instancetype)initWithRequest:(NSURLRequest *)request {
    self = [super init];
    if (!self) {
        return nil;
    }

    self.request = request;

    self.listenersKeyedByEvent = [[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsCopyIn valueOptions:NSPointerFunctionsStrongMemory capacity:100];

    self.lock = [[NSRecursiveLock alloc] init];
    self.lock.name = AFEventSourceLockName;

    NSError *error = nil;
    [self open:&error];
    if (error) {
        if ([self.delegate respondsToSelector:@selector(eventSource:didFailWithError:)]) {
            [self.delegate eventSource:self didFailWithError:error];
        }
    }

    return self;
}

- (BOOL)isConnecting {
    return self.state == AFEventSourceConnecting;
}

- (BOOL)isOpen {
    return self.state == AFEventSourceOpen;
}

- (BOOL)isClosed {
    return self.state == AFEventSourceClosed;
}

- (NSHTTPURLResponse *)lastResponse {
    return self.requestOperation.response;
}

- (BOOL)open:(NSError * __autoreleasing *)error {
    if ([self isOpen]) {
        if (error) {
            *error = [NSError errorWithDomain:AFEventSourceErrorDomain code:0 userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedStringFromTable(@"Even Source Already Opened", @"AFEventSource", nil) }];
        }

        return NO;
    }

    [self.lock lock];
    self.state = AFEventSourceConnecting;

    self.requestOperation = [[AFHTTPRequestOperation alloc] initWithRequest:self.request];
    self.requestOperation.responseSerializers = @[ [AFServerSentEventSerializer serializer] ];
    self.outputStream = [NSOutputStream outputStreamToMemory];
    self.outputStream.delegate = self;
    self.requestOperation.outputStream = self.outputStream;

    // TODO Determine correct retry behavior / customization
//    [self.requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
//        NSLog(@"Success: %@", responseObject);
//    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
//        NSLog(@"Failure: %@", error);
//    }];
    
    [self.requestOperation start];

    self.state = AFEventSourceOpen;
    [self.lock unlock];

    return YES;
}

- (BOOL)close:(NSError * __autoreleasing *)error {
    if ([self isClosed]) {
        if (error) {
            *error = [NSError errorWithDomain:AFEventSourceErrorDomain code:0 userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedStringFromTable(@"Even Source Already Closed", @"AFEventSource", nil) }];
        }

        return NO;
    }

    [self.lock lock];
    [self.requestOperation cancel];

    self.state = AFEventSourceClosed;
    [self.lock unlock];

    return YES;
}

#pragma mark -

- (void)addEventListener:(NSString *)event
              usingBlock:(void (^)(AFServerSentEvent *event))block
{
    NSMutableArray *mutableListeners = [self.listenersKeyedByEvent objectForKey:event];
    if (!mutableListeners) {
        mutableListeners = [NSMutableArray array];
    }

    [mutableListeners addObject:[block copy]];
    
    [self.listenersKeyedByEvent setObject:mutableListeners forKey:event];
}

- (void)removeListenersForEvent:(NSString *)event {
    [self.listenersKeyedByEvent removeObjectForKey:event];
}

#pragma mark - NSStreamDelegate

- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode {    
    switch (eventCode) {
        case NSStreamEventHasSpaceAvailable: {
            NSData *data = [stream propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
            NSError *error = nil;
            AFServerSentEvent *event = [[AFServerSentEventSerializer serializer] responseObjectForResponse:self.lastResponse data:[data subdataWithRange:NSMakeRange(self.offset, [data length] - self.offset)] error:&error];
            self.offset = [data length];

            if (error) {
                if ([self.delegate respondsToSelector:@selector(eventSource:didFailWithError:)]) {
                    [self.delegate eventSource:self didFailWithError:error];
                }
            } else {
                if (event) {
                    if ([self.delegate respondsToSelector:@selector(eventSource:didReceiveMessage:)]) {
                        [self.delegate eventSource:self didReceiveMessage:event];
                    }

                    for (AFServerSentEventBlock block in [self.listenersKeyedByEvent objectForKey:event.event]) {
                        if (block) {
                            block(event);
                        }
                    }
                }
            }
            break;
        }
        default:
            break;
    }
}

@end

#pragma mark -

@implementation AFServerSentEventSerializer

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }

    self.acceptableContentTypes = [[NSSet alloc] initWithObjects:@"text/event-stream", nil];

    return self;
}

#pragma mark - AFURLResponseSerializer

- (id)responseObjectForResponse:(NSURLResponse *)response
                           data:(NSData *)data
                          error:(NSError *__autoreleasing *)error
{
    if (![self validateResponse:(NSHTTPURLResponse *)response data:data error:error]) {
        return nil;
    }

    return [AFServerSentEvent eventWithFields:AFServerSentEventFieldsFromData(data, error)];
}

@end
