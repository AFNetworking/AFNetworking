//
//  AFRemoteImageView.h
//  AFNetworking
//
//  Created by Berik Visschers on 2011-11-18.
//  Copyright (c) 2011 Gowalla. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^AFNetworkingUIImageViewSuccessHandler)(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image);
typedef void (^AFNetworkingUIImageViewFailureHandler)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error);
typedef NSURLRequest * (^AFNetworkingUIImageViewURLRequestGenerator)(NSURL *url);

/**
 This category adds methods to the UIKit framework's `UIImageView` class. The methods in this category provide support for loading remote images asynchronously from a URL.
 */
@interface AFRemoteImageView : UIImageView

#pragma mark - Properties

/**
 Assigning to url will enqueue a new image request operation for that url. Previous requests will not be cancelled, their response will be cached but will not make the new image shown.
 */
@property (nonatomic, retain) NSURL *url;

/**
 The placeholderImage is shown when no image is loaded. In case there is no failureImage defined, the placeholderImage will be shown in place of the failureImage also.
 */
@property (nonatomic, retain) UIImage *placeholderImage;

/**
 The failureImage will be shown when the image request operation fails to deliver an image.
 */
@property (nonatomic, retain) UIImage *failureImage;

/**
 When showActivityIndicator is set to YES, a spinner will be shown while the image is loading.
 */
@property (nonatomic, assign) BOOL showsActivityIndicator;

/**
 When progressiveLoading is set to YES, the placeholderImage will not be shown when reloading or changing the URL.
 For UIImageViews that are reused (for example within a UITableViewCell), this property should be NO.
 NO is the default value.
 */
@property (nonatomic, assign) BOOL progressiveLoading;

/**
 The default success handler sets the begotten image in the UIImageView.
 */
@property (nonatomic, copy) AFNetworkingUIImageViewSuccessHandler successHandler;

/**
 The default failure handler displays the failureImage in the UIImageView.
 */
@property (nonatomic, copy) AFNetworkingUIImageViewFailureHandler failureHandler;

/**
 The default urlRequestGenerator generates a URLRequest with a timeout of 30 seconds and a cache policy of 'NSURLCacheStorageAllowed'.
 */
@property (nonatomic, copy) AFNetworkingUIImageViewURLRequestGenerator urlRequestGenerator;

/**
 Reloads the image from the current URL.
 */
- (void)reload;

/**
 Clears the NSURLCache and teh AFImageCache for this url.
 */
- (void)clearCacheForURL:(NSURL *)url;

/**
 Cancel all queued request that are made through UIImageView+AFNetworking
 */
+ (void)cancelAllImageRequestOperations;

/**
 Cancel the current request operation
 */
- (void)cancelImageRequestOperation;

@end
