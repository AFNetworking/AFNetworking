//
//  AFReachableClient.m
//  AFReachableClient
//
//  Created by Kevin Harwood on 12/19/11.
//  Copyright (c) 2011 Alications. All rights reserved.
//

#import "AFReachableClient.h"

@interface AFReachableClient(){
    BOOL _hasEstablishedReachability;
}

- (void)reachabilityChanged:(NSNotification*)notification;
- (void)failOperation:(AFHTTPRequestOperation*)operation;

@end

@implementation AFReachableClient
@synthesize reachableHostURL = reachableHostURL_;
@synthesize reachableHost = reachableHost_;

- (id)initWithBaseURL:(NSURL *)url 
     reachableHostURL:(NSURL *)reachableHostURL{
    self = [super initWithBaseURL:url];
    if (self != nil){
        reachableHostURL_ = reachableHostURL;
        [reachableHostURL_ retain];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(reachabilityChanged:) 
                                                     name:kReachabilityChangedNotification 
                                                   object:nil];
        reachableHost_ = [[Reachability reachabilityWithHostName:[reachableHostURL_ absoluteString]] retain];
        [reachableHost_ startNotifier];
    }
    return self;
    
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [reachableHost_ release], reachableHost_ = nil;
    [reachableHostURL_ release], reachableHostURL_ = nil;
    [super dealloc];
}

#pragma mark - AFHTTPClient Subclassed Methods
- (id)initWithBaseURL:(NSURL *)url{
    self = [self initWithBaseURL:url 
                reachableHostURL:url];
    if (self != nil){
        
    }
    return self;
}

- (void)enqueueHTTPRequestOperation:(AFHTTPRequestOperation *)operation{
    if((_hasEstablishedReachability) &&
       reachableHost_.currentReachabilityStatus == NotReachable){
        //No reason to kick off a request.  Fail immediately.
        [self failOperation:operation];
    }
    else {
        [super enqueueHTTPRequestOperation:operation];
    }
}

#pragma mark - Private
- (void)reachabilityChanged:(NSNotification *)notification{
    _hasEstablishedReachability = YES;
    if(reachableHost_.currentReachabilityStatus == NotReachable){
        for(AFHTTPRequestOperation *operation in self.operationQueue.operations){
            [self failOperation:operation];
        }
    }
}

- (void)failOperation:(AFHTTPRequestOperation*)operation{
    if(operation.isExecuting){
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
        [userInfo setValue:[NSString stringWithString:NSLocalizedString(@"Network Connection Lost","Network Connection Lost")] forKey:NSLocalizedDescriptionKey];
        [userInfo setValue:[operation.request URL] forKey:NSURLErrorFailingURLErrorKey];
        NSError *error = [NSError errorWithDomain:AFNetworkingErrorDomain
                                             code:NSURLErrorNetworkConnectionLost
                                         userInfo:userInfo];
        
        [operation setHTTPError:error];
        [operation cancel];
    }
    else {
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
        [userInfo setValue:[NSString stringWithString:NSLocalizedString(@"Unable to connect to Host","Unable to connect to Host")] forKey:NSLocalizedDescriptionKey];
        [userInfo setValue:[operation.request URL] forKey:NSURLErrorFailingURLErrorKey];
        NSError *error = [NSError errorWithDomain:AFNetworkingErrorDomain
                                             code:NSURLErrorCannotConnectToHost
                                         userInfo:userInfo];
        
        [operation setHTTPError:error];
        operation.completionBlock();
    }
}

@end
