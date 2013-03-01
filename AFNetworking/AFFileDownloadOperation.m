#import "AFFileDownloadOperation.h"

@implementation AFFileDownloadOperation

@synthesize destinationFilePath = _destinationFilePath;

- (id)initWithRequest:(NSURLRequest *)urlRequest destinationFilePath:(NSString *)filePath {
    self = [super )initWithRequest:urlRequest];
    if (!self) {
  	  return nil;
    }
    
    _destinationFilePath = filePath;
    
    self.outputStream = [NSOutputStream outputStreamToFileAtPath:filePath append:NO];
    
    return self;
}

- (void)connectionDidFinishLoading:(NSURLConnection __unused *)connection {
    self.responseData = [NSData dataWithContentsOfFile:_destinationFilePath options:NSDataReadingMappedIfSafe error:nil];

    [self.outputStream close];

    [self finish];

    self.connection = nil;
}

- (void)dealloc {
    _destinationFilePath = nil;
}

@end
