//
//  AFFileDownloadOperation.m
//  AFNetworking
//
//  Created by Vincent Roy Chevalier on 2013-02-28.
//

#import <Foundation/Foundation.h>

#import "AFFileDownloadOperation.h"

@implementation AFFileDownloadOperation

@synthesize destinationFilePath = _destinationFilePath;

- (id)initWithRequest:(NSURLRequest *)urlRequest destinationFilePath:(NSString *)filePath {
    self = [super initWithRequest:urlRequest];
    if (!self) {
        return nil;
    }
    
    _destinationFilePath = filePath;
    
    self.outputStream = [NSOutputStream outputStreamToFileAtPath:filePath append:NO];
    
    return self;
}

- (void)connectionDidFinishLoading:(NSURLConnection __unused *)connection {
    [self.outputStream setProperty:[NSData dataWithContentsOfFile:_destinationFilePath options:NSDataReadingMappedIfSafe error:nil] forKey:NSStreamDataWrittenToMemoryStreamKey];
    [super connectionDidFinishLoading:connection];
}

@end
