//
//  AFDataItemDownloader.m
//  AFNetworking
//
//  Created by jufan wang on 2020/3/4.
//  Copyright © 2020 AFNetworking. All rights reserved.
//

#import "AFDataItemDownloader.h"
#import "AFDataItemReceiptorManager.h"
//#include <os/lock.h>

@interface AFDataResponseHandler : NSObject
@property (nonatomic, copy) NSString *dataItemID;
@property (nonatomic, copy) NSString *dataItemVersion;
@property (nonatomic, copy) void (^successBlock)(id<AFDataItemIdentifier> data);
@property (nonatomic, copy) void (^failureBlock)(NSString *dataItemID, NSError* error);
@end
@implementation AFDataResponseHandler
- (instancetype)initWithSuccess:(nullable void (^)(id<AFDataItemIdentifier> data))success
                        failure:(nullable void (^)(NSString *dataItemID, NSError* error))failure {
    if (self = [self init]) {
        self.successBlock = success;
        self.failureBlock = failure;
    }
    return self;
}
- (NSString *)description {
    return [NSString stringWithFormat: @"<VVDataResponseHandler>requesterID: %@", self.dataItemID];
}
@end

@interface AFDataDownloaderMergedTask : NSObject
@property (nonatomic, copy) NSString *dataItemID;
@property (nonatomic, copy) NSString *dataItemVersion;

@property (nonatomic, strong) NSMutableArray<AFDataResponseHandler*> *responseHandlers;
@end
@implementation AFDataDownloaderMergedTask
- (instancetype)init {
    if (self = [super init]) {
        self.responseHandlers = [[NSMutableArray alloc] init];
    }
    return self;
}
- (void)addResponseHandler:(AFDataResponseHandler*)handler {
    [self.responseHandlers addObject:handler];
}
- (void)removeResponseHandler:(AFDataResponseHandler*)handler {
    [self.responseHandlers removeObject:handler];
}
@end


@interface AFDataItemDownloader() {
    //    os_unfair_lock _unfairLock;
}

@property (nonatomic, strong) NSMutableDictionary<NSString *, AFDataDownloaderMergedTask *> *queuedMergedTasks;
@property (nonatomic, strong) NSMutableDictionary<NSString *, AFDataDownloaderMergedTask *> *mergedTasks;

@property (nonatomic, strong) dispatch_queue_t requestQueue;
@property (nonatomic, strong) dispatch_queue_t callbackQueue;
@property (nonatomic, strong) dispatch_queue_t responseQueue;

@property (nonatomic, strong) dispatch_semaphore_t semphore;

@property (nonatomic, assign) NSInteger maxRequestCount;
@property (nonatomic, assign) NSInteger currentRequestCount;

@property (class, nonatomic, strong) NSMutableDictionary<NSString *, AFDataItemDownloader *> *downloaders;

@property (nonatomic, assign) CFAbsoluteTime preTimeInterval;
@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, copy) NSString *categoryID;

@property (nonatomic, strong) id<AFDataItemDownloaderDelegate> dataLoaderDelegate;

@property (nonatomic, weak) AFDataItemReceiptorManager *receiptorManager;

@end


@implementation AFDataItemDownloader

@synthesize dataLoaderDelegate = _dataLoaderDelegate;


#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wshadow-ivar"

static NSMutableDictionary<NSString *, AFDataItemDownloader *> *_downloaders;

+ (NSMutableDictionary<NSString *, AFDataItemDownloader *> *)downloaders {
    
    if (!_downloaders) {
        _downloaders = [NSMutableDictionary dictionary];
    }
    return _downloaders;
}
+ (void)setDownloaders:(NSMutableDictionary<NSString *, AFDataItemDownloader *> *)downloaders {
    _downloaders = downloaders;
}

+ (instancetype)creatDownloaderWithDelegate:(id<AFDataItemDownloaderDelegate>)delegate
                             dataCategoryID:(NSString *)dataCategoryID {
    if (!delegate || !dataCategoryID) {
        return nil;
    }
    AFDataItemDownloader *downloader = nil;
    @synchronized (self) {
        downloader = [[self downloaders] objectForKey:dataCategoryID];
        if (!downloader) {
            downloader = [[AFDataItemDownloader alloc] init];
            downloader.dataLoaderDelegate = delegate;
            downloader.categoryID = dataCategoryID;
            [[self downloaders] setObject:downloader forKey:dataCategoryID];
        }
    }
    return downloader;
}
+ (void)removeDownloaderWithDataCategoryID:(NSString *)dataCategoryID {
    if (!dataCategoryID) {
        return;
    }
    @synchronized (self) {
        [[self downloaders] removeObjectForKey:dataCategoryID];
    }
}
+ (instancetype)getDownloaderWithDataCategoryID:(NSString *)dataCategoryID {
    AFDataItemDownloader *downloader = nil;
    @synchronized (self) {
        downloader = [[self downloaders] objectForKey:dataCategoryID];
    }
    return downloader;
}

- (instancetype)init {
    if (self = [super init]) {
        //        _unfairLock = OS_UNFAIR_LOCK_INIT;
        _semphore = dispatch_semaphore_create(1);
        _queuedMergedTasks = [[NSMutableDictionary alloc] init];
        _mergedTasks = [[NSMutableDictionary alloc] init];
        
        _requestQueue = dispatch_queue_create("com.af.dataItemDownloader.requestQueue", DISPATCH_QUEUE_SERIAL);
        _responseQueue = dispatch_queue_create("com.af.dataItemDownloader.responsequeue", DISPATCH_QUEUE_CONCURRENT);
        _callbackQueue = dispatch_queue_create("com.af.dataItemDownloader.callbackQueue", DISPATCH_QUEUE_SERIAL);
        
        _retryTimeInterval = 1;
        _preTimeInterval = CFAbsoluteTimeGetCurrent();
        _maxRequestCount = 1;
        _currentRequestCount = 0;
    }
    return self;
}

- (void)startTimer {
    if (!self.timer) {
        self.timer = [NSTimer timerWithTimeInterval:self.retryTimeInterval
                                             target:self
                                           selector:@selector(timerDispatch)
                                           userInfo:nil
                                            repeats:true];
        [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSDefaultRunLoopMode];
        [self.timer fire];
    }
}

- (void)timerDispatch {
    __weak __typeof(self) weakSelf = self;
    dispatch_async(self.requestQueue, ^{
        __strong __typeof(weakSelf) self = weakSelf;
        [self tryDispatch];
    });
}

- (void)finishTimer {
    [self.timer invalidate];
    self.timer = nil;
}

- (void)setDataLoaderDelegate:(id<AFDataItemDownloaderDelegate>)dataLoaderDelegate {
    _dataLoaderDelegate = dataLoaderDelegate;
    _maxRequestCount = [_dataLoaderDelegate dataItemDownLoaderMaxHTTPConnection:self];
}

- (void)downloaderLock {
    //    os_unfair_lock_lock(&(_unfairLock));
    dispatch_semaphore_wait(self.semphore, DISPATCH_TIME_FOREVER);
}

- (void)downloaderUnlock {
    //    os_unfair_lock_unlock(&(_unfairLock));
    dispatch_semaphore_signal(self.semphore);
}

- (nullable id<AFDataItemIdentifier>)memoryDataItemWithID:(NSString *)dataID {
    return (id<AFDataItemIdentifier>)[self.cache memoryObjectForKey:dataID];
}

- (AFDataItemReceiptorManager *)receiptorManager {
    AFDataItemReceiptorManager *receiptorManager = _receiptorManager;
    if (!receiptorManager) {
        receiptorManager = [AFDataItemReceiptorManager managerForDataCategoryID:self.categoryID];
        _receiptorManager = receiptorManager;
    }
    return receiptorManager;
}

- (void)getDataItemWithID:(NSString *)dataItemID
                  success:(AFDataItemReceiptorSuccessBlock)success
                  failure:(AFDataItemReceiptorFailureBlock)failure {
    if (!dataItemID || !success || !failure) {
        return;
    }
    __weak __typeof(self) weakSelf = self;
    dispatch_async(self.requestQueue, ^{
        __strong __typeof(weakSelf) self = weakSelf;
        if (!self) {
            return ;
        }
        [self downloaderLock];
        id<AFDataItemIdentifier> wrapper = (id<AFDataItemIdentifier>)[self.cache objectForKey:dataItemID];
        if (wrapper) {
            if (success) {
                dispatch_async(self.callbackQueue, ^{
                    success(wrapper);
                });
            }
            [self downloaderUnlock];
            return;
        }
        
        AFDataDownloaderMergedTask *mergedTask = nil;
        mergedTask = self.mergedTasks[dataItemID];
        
        if (!mergedTask) {
            mergedTask = self.queuedMergedTasks[dataItemID];
        }
        
        if (mergedTask) {
            AFDataResponseHandler *responseHandler = [[AFDataResponseHandler alloc] initWithSuccess:success failure:failure];
            responseHandler.dataItemID = dataItemID;
            [mergedTask addResponseHandler:responseHandler];
            [self downloaderUnlock];
            dispatch_async(self.requestQueue, ^{
                [self tryDispatch];
            });
            return;
        };
        
        mergedTask = [[AFDataDownloaderMergedTask alloc] init];
        mergedTask.dataItemID = dataItemID;
        self.mergedTasks[dataItemID] = mergedTask;
        
        AFDataResponseHandler *handler = [[AFDataResponseHandler alloc] initWithSuccess:success failure:failure];
        handler.dataItemID = dataItemID;
        [mergedTask addResponseHandler:handler];
        
        [self downloaderUnlock];
        dispatch_async(self.requestQueue, ^{
            [self tryDispatch];
        });
    });
}

- (void)tryDispatch {
    NSArray * requestIDs = [self requestDataIDs];
    if (requestIDs.count) {
        [self downloaderLock];
        self.currentRequestCount++;
        [self downloaderUnlock];
        
        __weak __typeof(self) weakSelf = self;
        [self.dataLoaderDelegate dataItemDownLoader:self
                                           loadData:requestIDs
                                       successBlock:^(NSArray<NSString *> *dataItemIDs,
                                                      NSArray<id<AFDataItemIdentifier, NSCoding>> * _Nonnull response) {
            __strong __typeof(weakSelf) self = weakSelf;
            if (!self) {
                return ;
            }
            response = [response copy];
            dispatch_async(self.responseQueue, ^{
                [self downloaderLock];
                self.currentRequestCount--;
                NSMutableArray<AFDataResponseHandler *> *finishTasks = [NSMutableArray array];
                for (id<AFDataItemIdentifier, NSCoding> data in response) {
                    [self.cache setObject:data forKey:[data dataItemID]];
                    AFDataDownloaderMergedTask *mergedTask = self.queuedMergedTasks[[data dataItemID]];
                    if (mergedTask) {
                        self.queuedMergedTasks[[data dataItemID]] = nil;
                        [finishTasks addObjectsFromArray:mergedTask.responseHandlers];
                    }
                }
                for (NSString *dataID in dataItemIDs) {
                    if (self.queuedMergedTasks[dataID]) {
                        self.queuedMergedTasks[dataID] = nil;
                    }
                    if (self.mergedTasks[dataID]) {
                        self.mergedTasks[dataID] = nil;
                    }
                }
                [self downloaderUnlock];
                
                dispatch_async(self.requestQueue, ^{
                    [self tryDispatch];
                });
                dispatch_async(self.callbackQueue, ^{
                    for (AFDataResponseHandler *handler in finishTasks) {
                        id<AFDataItemIdentifier> dataItem = (id<AFDataItemIdentifier>)[self.cache objectForKey:handler.dataItemID];
                        if (handler.successBlock) {
                            handler.successBlock(dataItem);
                        }
                    }
                    [self.receiptorManager dataItemsUpdated:response];
                });
            });
        } failureBlock:^(NSArray<NSString *> * _Nonnull dataItemIDs,
                         NSError * _Nullable error) {
            __strong __typeof(weakSelf) self = weakSelf;
            if (!self) {
                return ;
            }
            dispatch_async(self.responseQueue, ^{
                [self downloaderLock];
                self.currentRequestCount--;
                NSMutableArray<AFDataResponseHandler *> *finishTasks = [NSMutableArray array];
                
                for (NSString *dataItemID in dataItemIDs) {
                    AFDataDownloaderMergedTask *mergedTask = self.queuedMergedTasks[dataItemID];
                    if (mergedTask) {
                        self.queuedMergedTasks[dataItemID] = nil;
                        [finishTasks addObjectsFromArray:mergedTask.responseHandlers];
                    }
                    if (self.queuedMergedTasks[dataItemID]) {
                        self.queuedMergedTasks[dataItemID] = nil;
                    }
                    if (self.mergedTasks[dataItemID]) {
                        self.mergedTasks[dataItemID] = nil;
                    }
                }
                [self downloaderUnlock];
                
                dispatch_async(self.callbackQueue, ^{
                    for (AFDataResponseHandler *handler in finishTasks) {
                        id<AFDataItemIdentifier> dataItem = (id<AFDataItemIdentifier>)[self.cache objectForKey:handler.dataItemID];
                        if (handler.failureBlock) {
                            handler.failureBlock(dataItem.dataItemID, error);
                        }
                    }
                });
            });
        }];
    }
}

- (NSArray *)requestDataIDs {
    NSMutableArray *dataIDs = [NSMutableArray array];
    [self downloaderLock];
    NSTimeInterval currentTimeInterval = CFAbsoluteTimeGetCurrent();
    if (currentTimeInterval - self.preTimeInterval >= self.retryTimeInterval) {
        self.preTimeInterval = currentTimeInterval;
        if (self.currentRequestCount < self.maxRequestCount) {
            NSArray *keys = [self.mergedTasks allKeys];
            int couter = 0;
            NSInteger pageSize = [self.dataLoaderDelegate dataItemDownLoaderPageSize:self];
            for (NSString *dataID in keys) {
                if (couter++ > pageSize) {
                    break;
                }
                [dataIDs addObject:dataID];
                self.queuedMergedTasks[dataID] = self.mergedTasks[dataID];
                self.mergedTasks[dataID] = nil;
            }
        }
        if (!dataIDs.count) {
            [self finishTimer];
        }
    } else {
        [self startTimer];
    }
    [self downloaderUnlock];
    return [dataIDs copy];
}

- (void)updateData:(NSArray<id<AFDataItemIdentifier>> *)dataIDsList {
    __weak __typeof(self) weakSelf = self;
    dispatch_async(self.requestQueue, ^{
        __strong __typeof(weakSelf) self = weakSelf;
        if (!self) {
            return;
        }
        for (id<AFDataItemIdentifier> data in dataIDsList) {
            if (!data.dataItemID) {
                continue;
            }
            [self downloaderLock];
            if (self.mergedTasks[data.dataItemID]
                || self.queuedMergedTasks[data.dataItemID]) {
                [self downloaderUnlock];
                continue;
            }
            [self downloaderUnlock];
            id<AFDataItemIdentifier> storeData = (id<AFDataItemIdentifier>)[self.cache objectForKey:[data dataItemID]];
            if ([data updatedCompareTo:storeData] || !storeData) {
                AFDataDownloaderMergedTask *mergedTask = [[AFDataDownloaderMergedTask alloc] init];
                mergedTask.dataItemVersion = data.dataItemVersion;
                mergedTask.dataItemID = data.dataItemID;
                self.mergedTasks[data.dataItemID] = mergedTask;
                [self.cache removeObjectForKey:data.dataItemID];
            }
        }
        dispatch_async(self.requestQueue, ^{
            [self tryDispatch];
        });
    });
}

#pragma clang diagnostic pop

@end

