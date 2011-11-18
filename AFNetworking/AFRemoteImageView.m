//
//  AFRemoteImageView.m
//  AFNetworking
//
//  Created by Berik Visschers on 2011-11-18.
//  Copyright (c) 2011 Gowalla. All rights reserved.
//

#import "AFRemoteImageView.h"
#import "AFImageCache.h"

static NSUInteger const maxConcurrentOperationCount = 8;

@interface AFRemoteImageView()
@property (nonatomic, retain) AFImageRequestOperation *af_imageRequestOperation;
@property (nonatomic, retain) UIActivityIndicatorView *activityIndicatorView;

+ (NSOperationQueue *)af_sharedImageRequestOperationQueue;
- (void)updateWithCurrentURL;
- (void)updateActivityIndicatorState;
@end

@implementation AFRemoteImageView
@synthesize url=url_;
@synthesize placeholderImage=placeholderImage_;
@synthesize failureImage=failureImage_;
@synthesize showsActivityIndicator=showsActivityIndicator_;
@synthesize successHandler=successHandler_;
@synthesize failureHandler=failureHandler_;
@synthesize urlRequestGenerator=urlRequestGenerator_;
@synthesize progressiveLoading=progressiveLoading_;
@synthesize activityIndicatorView=activityIndicatorView_;;
@dynamic af_imageRequestOperation;

#pragma mark - Object lifecycle

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.placeholderImage = self.image;
    }
    return self;
}

- (void)dealloc {
    self.url = nil;
    self.placeholderImage = nil;
    self.failureImage = nil;
    self.successHandler = nil;
    self.failureHandler = nil;
    self.urlRequestGenerator = nil;
    self.activityIndicatorView = nil;
    [super dealloc];
}

#pragma mark - API

- (void)clearCacheForURL:(NSURL *)url {
    [[AFImageCache sharedImageCache] removeCachedImageForURL:url cacheName:nil];
    
    NSURLRequest *urlRequest = nil;
    if (self.urlRequestGenerator) {
        urlRequest = self.urlRequestGenerator(self.url);
    }
    NSAssert(urlRequest, @"URLRequestGenerator should return a NSURLRequest");
    [[NSURLCache sharedURLCache] removeCachedResponseForRequest:urlRequest];
}

- (void)reload {
    [[AFImageCache sharedImageCache] removeCachedImageForURL:self.url cacheName:nil];
    [self updateWithCurrentURL];
}

- (void)cancelImageRequestOperation {
    [self.af_imageRequestOperation cancel];
}

+ (void)cancelAllImageRequestOperations {
    [[[self class] af_sharedImageRequestOperationQueue] cancelAllOperations];
}

#pragma mark - Private

+ (NSOperationQueue *)af_sharedImageRequestOperationQueue {
    static NSOperationQueue *_imageRequestOperationQueue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _imageRequestOperationQueue = [[NSOperationQueue alloc] init];
        [_imageRequestOperationQueue setMaxConcurrentOperationCount:maxConcurrentOperationCount];
    });
    return _imageRequestOperationQueue;
}

- (void)updateWithCurrentURL {
    if (!self.url) {
        self.image = self.placeholderImage;
        return;
    }
    
    UIImage *cachedImage = [[AFImageCache sharedImageCache] cachedImageForURL:self.url cacheName:nil];
    if (cachedImage) {
        if (self.successHandler) {
            self.successHandler(nil, nil, cachedImage);
        } else {
            self.image = cachedImage;
        }
        return;
    }
    
    if (!self.progressiveLoading) {
        self.image = self.placeholderImage;
    }
    
    NSURLRequest *urlRequest = nil;
    if (self.urlRequestGenerator) {
        urlRequest = self.urlRequestGenerator(self.url);
    }
    NSAssert(urlRequest, @"URLRequestGenerator should return a NSURLRequest");
    
    AFNetworkingUIImageViewSuccessHandler succesHandler = ^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
        if (![request.URL isEqual:self.url]) {
            // This request is not the latest
            return;
        }
        if (self.successHandler) {
            self.successHandler(request, response, image);
        }
    };
    
    AFNetworkingUIImageViewFailureHandler failureHandler = ^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
        if (![request.URL isEqual:self.url]) {
            // This request is not the latest
            return;
        }
        if (self.failureHandler) {
            self.failureHandler(request, response, error);
        }
    };
    
    self.af_imageRequestOperation = [AFImageRequestOperation imageRequestOperationWithRequest:urlRequest
                                                                         imageProcessingBlock:nil
                                                                                    cacheName:nil
                                                                                      success:succesHandler
                                                                                      failure:failureHandler];
    
    NSOperationQueue *imageRequestOperationQueue = [[self class] af_sharedImageRequestOperationQueue];
    
    // If there are a lot of operations in the queue, make the current operations of higher priority.
    NSUInteger operationCount = [imageRequestOperationQueue operationCount];
    if (operationCount > 2 * maxConcurrentOperationCount) {
        self.af_imageRequestOperation.queuePriority = NSOperationQueuePriorityHigh;
    }
    
    [imageRequestOperationQueue addOperation:self.af_imageRequestOperation];
    [self.activityIndicatorView startAnimating];
}

- (void)updateActivityIndicatorState {
    if (self.showsActivityIndicator && !self.activityIndicatorView) {
        UIActivityIndicatorView *activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        activityIndicatorView.hidesWhenStopped = YES;
        
        [self addSubview:activityIndicatorView];
        activityIndicatorView.center = self.center;
        activityIndicatorView.autoresizingMask = (  UIViewAutoresizingFlexibleLeftMargin
                                                  | UIViewAutoresizingFlexibleRightMargin
                                                  | UIViewAutoresizingFlexibleTopMargin
                                                  | UIViewAutoresizingFlexibleBottomMargin);
        [activityIndicatorView stopAnimating];
        self.activityIndicatorView = activityIndicatorView;
        [activityIndicatorView release];
    } else if (!self.showsActivityIndicator && self.activityIndicatorView) {
        self.activityIndicatorView = nil;
    }
}

#pragma mark - Property accessors

- (void)setUrl:(NSURL *)url {
    [self willChangeValueForKey:@"url"];
    [url_ autorelease];
    url_ = [url retain];
    [self didChangeValueForKey:@"url"];
    [self updateWithCurrentURL];
}

- (void)setShowsActivityIndicator:(BOOL)showsActivityIndicator {
    [self willChangeValueForKey:@"activityIndicatorView"];
    showsActivityIndicator_ = showsActivityIndicator;
    [self didChangeValueForKey:@"activityIndicatorView"];
    [self updateActivityIndicatorState];
}

- (AFNetworkingUIImageViewSuccessHandler)successHandler {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!successHandler_) {
            __block AFRemoteImageView *blockSelf = self;
            successHandler_ = Block_copy(^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                [blockSelf.activityIndicatorView stopAnimating];
                blockSelf.image = image;
            });
        }
    });
    return successHandler_;
}

- (AFNetworkingUIImageViewFailureHandler)failureHandler {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!failureHandler_) {
            __block AFRemoteImageView *blockSelf = self;
            failureHandler_ = Block_copy(^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                [blockSelf.activityIndicatorView stopAnimating];
                blockSelf.image = blockSelf.failureImage ?: blockSelf.placeholderImage;
            });
        }
    });
    return failureHandler_;
}

- (AFNetworkingUIImageViewURLRequestGenerator)urlRequestGenerator {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!urlRequestGenerator_) {
            urlRequestGenerator_  = Block_copy(^NSURLRequest * (NSURL *url) {
                NSMutableURLRequest *mutableURLRequest = [NSMutableURLRequest requestWithURL:url
                                                                                 cachePolicy:NSURLCacheStorageAllowed
                                                                             timeoutInterval:30.0];
                mutableURLRequest.HTTPShouldHandleCookies = NO;
                mutableURLRequest.HTTPShouldUsePipelining = YES;
                return mutableURLRequest;
            });
        }
    });
    return urlRequestGenerator_;
}

@end
