//
//  AFFileDownloadOperation.h
//  AFNetworking
//
//  Created by Vincent Roy Chevalier on 2013-02-28.
//

#import <Foundation/Foundation.h>

#import "AFHTTPRequestOperation.h"

@interface AFFileDownloadOperation : AFHTTPRequestOperation

@property (readonly, nonatomic, strong) NSString * destinationFilePath;

- (id)initWithRequest:(NSURLRequest *)urlRequest destinationFilePath:(NSString *)filePath;

@end
