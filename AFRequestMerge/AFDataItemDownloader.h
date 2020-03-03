//
//  AFDataItemDownloader.h
//  AFNetworking
//
//  Created by jufan wang on 2020/3/4.
//  Copyright © 2020 AFNetworking. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "AFDataItemIdentifier.h"

NS_ASSUME_NONNULL_BEGIN


@interface AFDataItemDownloader : NSObject

/**
 Creates a data item downloader  for category which is marked by dataCategoryID if not existed .
 
 @param delegate the real downloader for data item .
 @param dataCategoryID data category marks the some kind of data items .
 
 @return a data item downloader for category dataCategoryID .
*/
+ (instancetype)creatDownloaderWithDelegate:(id<AFDataItemDownloaderDelegate>)delegate
                             dataCategoryID:(NSString *)dataCategoryID;

/**
 Return a data item downloader  for category which is marked by dataCategoryID if existed .
 
 @param dataCategoryID data category marks the some kind of data items .
 
 @return a data item downloader for category dataCategoryID or nil if not existed .
*/
+ (instancetype)getDownloaderWithDataCategoryID:(NSString *)dataCategoryID;

/**
 Remove a data item downloader  for category which is marked by dataCategoryID if existed .
 
 @param dataCategoryID data category marks the some kind of data items .
*/
+ (void)removeDownloaderWithDataCategoryID:(NSString *)dataCategoryID;

@property (nonatomic, strong) id<AFDataItemDownloaderCacher> cache;

/**
 Waits for retryTimeInterval seconds before retrying download  if currentRequestCount is equal to maxRequestCount .
*/
@property (atomic, assign) NSTimeInterval retryTimeInterval;

/**
 The  time interval for retrying download  if the max request connection arrived .
*/
@property (nonatomic, assign, readonly) NSInteger maxRequestCount; //Default  1

/**
 The  request count  if currentRequestCount is equal to maxRequestCount there no request will be happens.
*/
@property (nonatomic, assign, readonly) NSInteger currentRequestCount;

/*
 Get the data item associated with the given ID .
 @param dataID the data item id which will be added to the data item list if the cacher return nil. The next request will merge certain count of data item ids into a single request .
 */
- (void)getDataItemWithID:(NSString *)dataID
                  success:(AFDataItemReceiptorSuccessBlock)success
                  failure:(AFDataItemReceiptorFailureBlock)failure;

/*
 if the comming dataItemVersion is bigger than local cached , update the data item .
*/
- (void)updateData:(NSArray<id<AFDataItemIdentifier>> *)dataIDsList;

/*
 Get the data item associated with the given ID in memory cache .
*/
- (nullable id<AFDataItemIdentifier>)memoryDataItemWithID:(NSString *)dataID;

@end

NS_ASSUME_NONNULL_END
