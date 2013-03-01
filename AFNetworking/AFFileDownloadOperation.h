#import <Foundation/Foundation.h>

#import "AFHTTPRequestOperation.h"

@interface AFFileDownloadOperation : AFHTTPRequestOperation

- (id)initWithRequest:(NSURLRequest *)urlRequest destinationFilePath:(NSString *)filePath;

@end
