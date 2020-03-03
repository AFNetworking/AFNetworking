//
//  AFDataItemReceiptorManager.h
//  AFNetworking
//
//  Created by jufan wang on 2020/3/4.
//  Copyright © 2020 AFNetworking. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "AFDataItemIdentifier.h"

NS_ASSUME_NONNULL_BEGIN

@interface AFDataItemReceiptorManager : NSObject

+ (instancetype)managerForDataCategoryID:(NSString *)dataCategoryID;
+ (void)removeManagerForDataCategoryID:(NSString *)dataCategoryID;

- (void)cancel:(NSString *)dataItemID forRecceipter:(id<AFDataItemReceiptor>)receiptor;

- (void)dataItemForID:(NSString *)dataItemID
           recceipter:(id<AFDataItemReceiptor>)receiptor
         successBlock:(AFDataItemReceiptorSuccessBlock)successBlock
         failureBlock:(AFDataItemReceiptorFailureBlock)failureBlock;

- (void)dataItemsUpdated:(NSArray<id<AFDataItemIdentifier>> *)dataItems;

@end

NS_ASSUME_NONNULL_END
