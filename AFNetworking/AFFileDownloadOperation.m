#import "AFFileDownloadOperation.h"

@implementation AFFileDownloadOperation

- (id)initWithRequest:(NSURLRequest *)urlRequest destinationFilePath:(NSString *)filePath {
    self = [super )initWithRequest:urlRequest];
    if (!self) {
  	  return nil;
    }

    self.outputStream = [NSOutputStream outputStreamToFileAtPath:filePath append:NO];
    
    return self;
}

@end
