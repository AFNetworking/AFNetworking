// AFReachableClient.h
//
// Copyright (c) 2011 Kevin Harwood
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
    NSAssert(reachableHostURL != nil, @"Reachable Host URL cannont be nil");
    
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
    [reachableHost_ stopNotifier];
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
    NSString * localizedErrorDescription;
    NSInteger errorCode;
    
    if(operation.isExecuting){
        localizedErrorDescription = NSLocalizedString(@"Network Connection Lost","Network Connection Lost");
        errorCode = NSURLErrorNetworkConnectionLost;
    }
    else {
        localizedErrorDescription = NSLocalizedString(@"Unable to connect to Host","Unable to connect to Host");
        errorCode = NSURLErrorCannotConnectToHost;
    }
    
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    [userInfo setValue:localizedErrorDescription
                forKey:NSLocalizedDescriptionKey];
    [userInfo setValue:[operation.request URL] 
                forKey:NSURLErrorFailingURLErrorKey];
    [userInfo setValue:NSLocalizedString(@"Ensure you are connected to the network and try again.", @"Network Lost Recovery Suggestion")
                 forKey:NSLocalizedRecoverySuggestionErrorKey];
    
    NSError *error = [NSError errorWithDomain:AFNetworkingErrorDomain
                                         code:errorCode
                                     userInfo:userInfo];
    
    [operation setHTTPError:error];
    
    //If the operation is already in the operation queue, we can
    //simply cancel it.  If it has not yet been added to the operation
    //queue, we must invoke the completion block ourselves
    if([self.operationQueue.operations containsObject:operation]){
        [operation cancel];
    }
    else{
        operation.completionBlock();
    }
    
}

@end
