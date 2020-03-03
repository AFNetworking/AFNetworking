//
//  AFDataItemIdentifier.h
//  AFNetworking iOS
//
//  Created by jufan wang on 2020/3/3.
//  Copyright © 2020 AFNetworking. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol AFDataItemIdentifier;

typedef void (^AFDataItemDownloadSuccessBlock)(NSArray<NSString *> *dataItemIDs,
                                           NSArray<id<AFDataItemIdentifier, NSCoding>> *dataItemList);
typedef void (^AFDataItemDownloadFailureBlock)(NSArray<NSString *> *dataItemIDs,
                                               NSError * _Nullable error);

typedef void (^AFDataItemReceiptorSuccessBlock)(_Nullable id<AFDataItemIdentifier> dataItem);
typedef void (^AFDataItemReceiptorFailureBlock)(NSString *dataItemID, NSError * _Nullable error);


@protocol AFDataItemIdentifier <NSObject>
@required
@property (nonatomic, copy) NSString *dataItemID;
@property (nonatomic, copy) NSString *dataItemVersion;
- (BOOL)updatedCompareTo:(id<AFDataItemIdentifier>)dataItemIdentifier;
@end
@interface AFDataItemIdentifier : NSObject<AFDataItemIdentifier>
@end


@protocol AFDataItemReceiptor <AFDataItemIdentifier>
@optional
- (void)dataItemUpdated:(id<AFDataItemIdentifier>)dataItem;
@end


@class AFDataItemDownloader;

@protocol AFDataItemDownloaderDelegate <NSObject>

@required

- (void)dataItemDownLoader:(AFDataItemDownloader *)dataDownLoader
              loadData:(NSArray *)dataItemIDs
          successBlock:(AFDataItemDownloadSuccessBlock)successBlock
          failureBlock:(AFDataItemDownloadFailureBlock)failureBlock;

- (NSInteger)dataItemDownLoaderPageSize:(AFDataItemDownloader *)dataDownLoader;

- (NSInteger)dataItemDownLoaderMaxHTTPConnection:(AFDataItemDownloader *)dataDownLoader;

@end


@protocol AFDataItemDownloaderCacher

@required

@property (nonatomic, assign) NSTimeInterval ageLimit;
@property (nonatomic, assign) NSTimeInterval invalidCachingTime;

- (void)setObject:(nullable id<AFDataItemIdentifier>)object forKey:(NSString *)key;

- (nullable id<AFDataItemIdentifier>)objectForKey:(NSString *)key;

- (void)removeObjectForKey:(NSString *)key;

- (nullable id<AFDataItemIdentifier>)memoryObjectForKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
