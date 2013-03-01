#import <Foundation/Foundation.h>

#import "AFHTTPRequestOperation.h"

@interface AFFileDownloadOperation : AFHTTPRequestOperation

@property (readonly, nonatomic, strong) NSString * destinationFilePath;

- (id)initWithRequest:(NSURLRequest *)urlRequest destinationFilePath:(NSString *)filePath;

@end
