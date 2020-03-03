//
//  AFDataItemReceiptorManager.m
//  AFNetworking
//
//  Created by jufan wang on 2020/3/4.
//  Copyright © 2020 AFNetworking. All rights reserved.
//

#import "AFDataItemReceiptorManager.h"
#import "AFDataItemDownloader.h"


static NSString * kAFDataItemReceiptorError = @"kAFDataItemReceiptorError";

#define kAFDataItemReceiptorErrorCodeCancel 1001
#define kAFDataItemReceiptorErrorCodeParameter 1002

@interface AFDataItemReceiptorHandler : NSObject
@property (nonatomic, copy) NSString *dataItemID;
@property (nonatomic, weak) id<AFDataItemReceiptor> dataReceiptor;
@property (nonatomic, copy) AFDataItemReceiptorSuccessBlock successBlock;
@property (nonatomic, copy) AFDataItemReceiptorFailureBlock failureBlock;
@end
@implementation AFDataItemReceiptorHandler
- (NSString *)description {
    return [NSString stringWithFormat: @"<AFDataItemReceiptorHandler>: %@", self];
}
@end

@interface AFDataItemReceiptorHandlersManager : NSObject
@property (nonatomic, strong) NSMutableDictionary<NSString *,NSNumber *> *requestPinnings;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableArray<AFDataItemReceiptorHandler *> *> *request2Handlers;
@end
@implementation AFDataItemReceiptorHandlersManager

- (instancetype)init {
    if (self = [super init]) {
        _request2Handlers = [NSMutableDictionary dictionary];
    }
    return self;
}
- (NSMutableArray *)handlesForDataItemID:(NSString *)dataItemID {
    if (!dataItemID) {
        return nil;
    }
    NSMutableArray *handlers = [self.request2Handlers objectForKey:dataItemID];
    if (!handlers) {
        handlers = [NSMutableArray array];
        [self.request2Handlers setObject:handlers forKey:[dataItemID copy]];
    }
    return handlers;
}

- (void)addHandler:(AFDataItemReceiptorHandler *)handler
     forDataItemID:(NSString *)dataItemID {
    if (!handler || !dataItemID) {
        return;
    }
    [[self handlesForDataItemID:[dataItemID copy]] addObject:handler];
}

- (NSArray<id<AFDataItemReceiptor>> *)removeHandlersForDataItemID:(NSString *)dataItemID {
    if (!dataItemID) {
       return nil;
    }
   NSArray *handlers = [[self.request2Handlers objectForKey:dataItemID] copy];
   handlers = [handlers valueForKey:@"dataReceiptor"];
    [self.request2Handlers removeObjectForKey:dataItemID];
   return handlers;
}


- (BOOL)pinningForDataItemID:(NSString *)dataItemID {
    return [[self.requestPinnings objectForKey:dataItemID] boolValue];
}
- (void)updatePinning:(BOOL)pinning forDataItemID:(NSString *)dataItemID {
    if (!dataItemID) {
        return;
    }
    [self.requestPinnings setObject:@(pinning) forKey:[dataItemID copy]];
}

- (void)cancel:(NSString *)dataItemID forRecceipter:(id)receiptor {
    if (!dataItemID || !receiptor) {
        return;
    }
    NSMutableArray *handlers = [self handlesForDataItemID:dataItemID];
    NSArray *ihandlers = [handlers copy];
    for (AFDataItemReceiptorHandler *handler in ihandlers) {
        if ([handler.dataItemID isEqualToString:dataItemID]
            && [handler.dataReceiptor isEqual:receiptor]) {
            NSError *error = [NSError errorWithDomain:kAFDataItemReceiptorError
                                                 code:kAFDataItemReceiptorErrorCodeCancel
                                             userInfo:nil];
            if (handler.failureBlock) {
                handler.failureBlock(dataItemID, error);
            }
        }
    }
    if (!handlers.count) {
        [self removeHandlersForDataItemID:dataItemID];
    }
}

- (NSString *)description {
    return [NSString stringWithFormat: @"<AFDataItemReceiptorHandlersManager>: %@", self];
}

@end


@interface AFDataItemReceiptorManager()
@property (class, nonatomic, strong) NSMutableDictionary<NSString *, AFDataItemReceiptorManager *> *receiptorsManager;
@property (nonatomic, strong) AFDataItemReceiptorHandlersManager *handlersManager;
@property (nonatomic, strong) dispatch_queue_t responseQueue;
@property (nonatomic, strong) dispatch_queue_t requestQueue;
@property (nonatomic, copy) NSString * dataCategoryID;
@property (nonatomic, strong) NSHashTable<id<AFDataItemReceiptor>> *receiptors;

@property (nonatomic, weak) AFDataItemDownloader *downLoader;

@end

@implementation AFDataItemReceiptorManager


#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wshadow-ivar"

static NSMutableDictionary<NSString *, AFDataItemReceiptorManager *> *_receiptorsManager;

+ (NSMutableDictionary<NSString *, AFDataItemReceiptorManager *> *)receiptorsManager {
    if (!_receiptorsManager) {
        _receiptorsManager = [NSMutableDictionary dictionary];
    }
    return _receiptorsManager;
}
+ (void)setReceiptorsManager:(NSMutableDictionary<NSString *,AFDataItemReceiptorManager *> *)receiptorsManager {
    _receiptorsManager = receiptorsManager;
}

+ (instancetype)managerForDataCategoryID:(NSString *)dataCategoryID {
    if (!dataCategoryID) {
        return nil;
    }
    AFDataItemReceiptorManager *mananger = nil;
    @synchronized (self) {
        mananger = [[[self class] receiptorsManager] objectForKey:dataCategoryID];
        if (!mananger) {
            mananger = [[AFDataItemReceiptorManager alloc] init];
            [[[self class] receiptorsManager] setObject:mananger
                                                 forKey:[dataCategoryID copy]];
            mananger.dataCategoryID = dataCategoryID;
        }
    }
    return mananger;
}
+ (void)removeManagerForDataCategoryID:(NSString *)dataCategoryID {
    if (!dataCategoryID) {
        return ;
    }
    @synchronized (self) {
        [[[self class] receiptorsManager] removeObjectForKey:dataCategoryID];
    }
}

- (instancetype)init {
    if (self = [super init]) {
        _handlersManager = [[AFDataItemReceiptorHandlersManager alloc] init];
        _requestQueue = dispatch_queue_create("com.af.dataItemReceiptorManager.requestQueue", DISPATCH_QUEUE_SERIAL);
        _responseQueue = dispatch_queue_create("com.af.dataItemReceiptorManager.responsequeue", DISPATCH_QUEUE_CONCURRENT);
        _receiptors = [NSHashTable hashTableWithOptions:NSPointerFunctionsWeakMemory];
    }
    return self;
}

- (AFDataItemDownloader *)downLoader {
    AFDataItemDownloader *downLoader = _downLoader;
    if (!downLoader) {
        downLoader = [AFDataItemDownloader getDownloaderWithDataCategoryID:self.dataCategoryID];
        _downLoader = downLoader;
    }
    return downLoader;
}

- (void)dataItemForID:(NSString *)dataItemID
           recceipter:(id<AFDataItemReceiptor>)receiptor
         successBlock:(AFDataItemReceiptorSuccessBlock)successBlock
         failureBlock:(AFDataItemReceiptorFailureBlock)failureBlock {
    
    if (!dataItemID || !receiptor || !successBlock || !failureBlock) {
        if (failureBlock) {
            NSError *error = [NSError errorWithDomain:kAFDataItemReceiptorError
                                                 code:kAFDataItemReceiptorErrorCodeCancel
                                             userInfo:nil];
            failureBlock(dataItemID, error);
        }
        return;
    }
    
    id<AFDataItemIdentifier> dataItem = [self.downLoader memoryDataItemWithID:dataItemID];
    if (dataItem) {
        successBlock(dataItem);
        __weak __typeof(self) weakSelf = self;
        dispatch_async(self.requestQueue, ^{
            __strong typeof(weakSelf) self = weakSelf;
            [self.receiptors addObject:receiptor];
        });
        return;
    }
    
    __weak __typeof(self) weakSelf = self;
    dispatch_async(self.requestQueue, ^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) {
            return ;
        }
        [self.receiptors removeObject:receiptor];
        AFDataItemReceiptorHandler *handler = [[AFDataItemReceiptorHandler alloc] init];
        handler.successBlock = successBlock;
        handler.failureBlock = failureBlock;
        handler.dataReceiptor = receiptor;
        handler.dataItemID = dataItemID;
        [self.handlersManager addHandler:handler forDataItemID:dataItemID];
        if ([self.handlersManager pinningForDataItemID:dataItemID]) {
            return;
        }
        [self.handlersManager updatePinning:YES forDataItemID:dataItemID];
        [self.downLoader getDataItemWithID:dataItemID success:^(id<AFDataItemIdentifier>  _Nonnull dataItem) {
            dispatch_async(self.requestQueue, ^{
                NSString *dataItemIDSuccess = dataItem.dataItemID;
                NSArray *handlers = [[self.handlersManager handlesForDataItemID:dataItemIDSuccess] copy];
                [self.handlersManager updatePinning:NO forDataItemID:dataItemIDSuccess];
                NSArray *receiptors = [self.handlersManager removeHandlersForDataItemID:dataItemID];
                for (id<AFDataItemReceiptor> receiptor in receiptors) {
                    [self.receiptors addObject:receiptor];
                }
                dispatch_async(self.responseQueue, ^{
                    for (AFDataItemReceiptorHandler *handler in handlers) {
                        if (handler.successBlock) {
                            handler.successBlock(dataItem);
                        }
                    }
                });
            });
        } failure:^(NSString * _Nonnull dataItemID, NSError * _Nonnull error) {
            dispatch_async(self.requestQueue, ^{
                NSArray *handlers = [[self.handlersManager handlesForDataItemID:dataItemID] copy];
                [self.handlersManager updatePinning:NO forDataItemID:dataItemID];
                NSArray *receiptors = [self.handlersManager removeHandlersForDataItemID:dataItemID];
                for (id<AFDataItemReceiptor> receiptor in receiptors) {
                    [self.receiptors addObject:receiptor];
                }
                dispatch_async(self.requestQueue, ^{
                    for (AFDataItemReceiptorHandler *handler in handlers) {
                        if (handler.failureBlock) {
                            handler.failureBlock(dataItemID, error);
                        }
                    }
                });
            });
        }];
    });
}

- (void)cancel:(NSString *)dataItemID forRecceipter:(id<AFDataItemReceiptor>)receiptor {
    if (!dataItemID || !receiptor) {
        return;
    }
    __weak __typeof(self) weakSelf = self;
    dispatch_async(self.requestQueue, ^{
        __strong __typeof(weakSelf) self = weakSelf;
        [self.handlersManager cancel:dataItemID forRecceipter:receiptor];
        [self.receiptors removeObject:receiptor];
    });
}

- (void)dataItemsUpdated:(NSArray<id<AFDataItemIdentifier>> *)dataItems {
    __weak __typeof(self) weakSelf = self;
    dataItems = [dataItems copy];
    dispatch_async(self.requestQueue, ^{
        __strong __typeof(weakSelf) self = weakSelf;
        if (!self) {
            return;
        }
        NSHashTable *receiptors = [self.receiptors copy];
        dispatch_async(self.responseQueue, ^{
            for (id<AFDataItemReceiptor> receiptor in receiptors) {
                if ([receiptor respondsToSelector:@selector(dataItemID)]
                    && [receiptor respondsToSelector:@selector(dataItemUpdated:)]) {
                    for (id<AFDataItemIdentifier> dataItem in dataItems) {
                        if ([dataItem.dataItemID isEqualToString:receiptor.dataItemID]) {
                            [receiptor dataItemUpdated:dataItem];
                            break;
                        }
                    }
                }
            }
        });
    });
}

#pragma clang diagnostic pop

@end
