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
 `AFRemoteImageView` is an UIImageView subclass that supports loading images from `NSURL`s. `AFRemoteImageView` uses `AFImageRequestOperation` to fetch the image data.
 */
@interface AFRemoteImageView : UIImageView

/**
 Assigning to `url` will enqueue a `AFImageReqeustOperation` for that url. On completion, the request will call the `successHandler` or `failureHandler`.
 If the url has changed before the `AFImageRequestOperation` finishes, no completion handlers will be called.
 */
@property (nonatomic, retain) NSURL *url;

/**
 The `placeholderImage` is shown when no image is loaded. In case there is no failureImage defined, the placeholderImage will be shown in place of the failureImage also.
 The placeholderImage will be set by `initWithCoder:` (for InterfaceBuilder support) and `initWithImage:'.
 */
@property (nonatomic, retain) UIImage *placeholderImage;

/**
 The `failureImage` will be shown when the `AFImageRequestOperation` fails to deliver an image.
 */
@property (nonatomic, retain) UIImage *failureImage;

/**
 When `showActivityIndicator` is set to YES, a spinner will be shown while the image is loading.
 */
@property (nonatomic, assign) BOOL showsActivityIndicator;

/**
 When `showActivityIndicator` is set to YES, `activityIndicatorView` will contain the `UIActivityIndicatorView`.
 */
@property (nonatomic, retain) UIActivityIndicatorView *activityIndicatorView;

/**
 When `progressiveLoading` is set to YES, the `placeholderImage` will not be shown when reloading or changing the URL.
 When reusing `AFRemoteImageView`s that are reused (for example within a `UITableViewCell`), this property should be NO.
 NO is the default value.
 */
@property (nonatomic, assign) BOOL progressiveLoading;

/**
 The `successHandler` is called by the `AFImageReqeustOperation` if it successfully loaded an image.
 By default, the `successHandler` will set the fetched image as the current image.
 */
@property (nonatomic, copy) AFNetworkingUIImageViewSuccessHandler successHandler;

/**
 The `failureHandler` is called by the `AFImageReqeustOperation` if it did not succeed to load an image.
 By default, the `failureHandler` displays the `failureImage` or the `placeholderImage` in case the `failureImage` is nil.
 */
@property (nonatomic, copy) AFNetworkingUIImageViewFailureHandler failureHandler;

/**
 The `urlRequestGenerator` is called to transform an NSURL to a NSURLRequest.
 By default, the `urlRequestGenerator` generates an `NSURLRequest` with a timeout of 30 seconds and a cache policy of `NSURLCacheStorageAllowed`.
 */
@property (nonatomic, copy) AFNetworkingUIImageViewURLRequestGenerator urlRequestGenerator;

/**
 Clears the `AFImageCache` and reloads the image for the current URL.
 */
- (void)reload;

/**
 Clears the `NSURLCache` and the `AFImageCache` for the URL specified.
 */
- (void)clearCacheForURL:(NSURL *)url;

/**
 `cancelAllImageRequestOperations` cancels all queued requests that are made through `AFRemoteImageView`.
 */
+ (void)cancelAllImageRequestOperations;

/**
 `cancelImageRequestOperation` cancels the current request operation.
 */
- (void)cancelImageRequestOperation;

@end
