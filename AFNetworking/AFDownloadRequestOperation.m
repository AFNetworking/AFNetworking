// AFDownloadRequestOperation.m
//
// Copyright (c) 2012 Mattt Thompson (http://mattt.me)
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

#import "AFDownloadRequestOperation.h"
#import "AFURLConnectionOperation.h"

@interface AFDownloadRequestOperation()
@property (readwrite, nonatomic, retain) NSURLRequest *request;
@property (readwrite, nonatomic, retain) NSError *downloadError;
@property (readwrite, nonatomic, copy) NSString *destination;
@property (readwrite, nonatomic, assign) BOOL allowOverwrite;
@end

static unsigned long long AFFileSizeForPath(NSString *path) {
    unsigned long long fileSize = 0;
    NSFileManager *fileManager = [[[NSFileManager alloc] init] autorelease];
    if ([fileManager fileExistsAtPath:path]) {
        NSError *error = nil;
        NSDictionary *attributes = [fileManager attributesOfItemAtPath:path error:&error];
        if (!error && attributes) {
            fileSize = [attributes fileSize];
        }
    }
    return fileSize;
}

@implementation AFDownloadRequestOperation
@synthesize shouldResume = _shouldResume;
@synthesize downloadError = _downloadError;
@synthesize destination = _destination;
@synthesize allowOverwrite = _allowOverwrite;
@synthesize deletesFileUponFailure = _deletesFileUponFailure;
@dynamic request;

- (id)initWithRequest:(NSURLRequest *)urlRequest {
    if ((self = [super initWithRequest:urlRequest])) {
        _shouldResume = YES;
        _destination = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] copy];
    }
    return self;
}

- (void)dealloc {
    [_downloadError release];
    [_destination release];
    [super dealloc];
}

- (NSError *)error {
    if (_downloadError) {
        return _downloadError;
    } else {
        return [super error];
    }
}

// the temporary path depends on the request URL.
- (NSString *)temporaryPath {
    NSString *temporaryPath = nil;
    if (self.destination) {
        NSString *hashString = [NSString stringWithFormat:@"%u", [self.request.URL hash]];
        temporaryPath = [AFCreateIncompleteDownloadDirectoryPath() stringByAppendingPathComponent:hashString];
    }
    return temporaryPath;
}

// build the final destination with _destination and response.suggestedFilename.
- (NSString *)destinationPath {
    NSString *destinationPath = _destination;
    
    // we assume that at least the directory has to exist on the targetPath
    BOOL isDirectory;
    if(![[NSFileManager defaultManager] fileExistsAtPath:_destination isDirectory:&isDirectory]) {
        isDirectory = NO;
    }        
    // if targetPath is a directory, use the file name we got from the urlRequest.
    if (isDirectory) {
        destinationPath = [NSString pathWithComponents:[NSArray arrayWithObjects:_destination, self.response.suggestedFilename, nil]];
    }
    
    return destinationPath;
}

- (BOOL)deleteTempFileWithError:(NSError **)error {
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    BOOL success = YES;
    @synchronized(self) {
        NSString *tempPath = [self temporaryPath];
        if ([fileManager fileExistsAtPath:tempPath]) {
            success = [fileManager removeItemAtPath:[self temporaryPath] error:error];
        }
    }
    [fileManager release];
    return success;
}

#pragma mark -

- (void)setDestination:(NSString *)path allowOverwrite:(BOOL)allowOverwrite {
    self.allowOverwrite = allowOverwrite;
    self.destination = path;
}

#pragma mark - NSOperation

- (BOOL)isReady {
    return [super isReady] && self.destination;
}

- (void)start {
    if ([self isReady]) {
        self.responseFilePath = [self temporaryPath];
        
        if (_shouldResume) {
            unsigned long long tempFileSize = AFFileSizeForPath([self temporaryPath]);
            if (tempFileSize > 0) {
                NSMutableURLRequest *mutableURLRequest = [[self.request mutableCopy] autorelease];
                [mutableURLRequest setValue:[NSString stringWithFormat:@"bytes=%llu-", tempFileSize] forHTTPHeaderField:@"Range"];
                self.request = mutableURLRequest;
                [self.outputStream setProperty:[NSNumber numberWithUnsignedLongLong:tempFileSize] forKey:NSStreamFileCurrentOffsetKey];
            }
        }
        
        [super start];
    }
}

#pragma mark - AFURLRequestOperation

- (void)setCompletionBlockWithSuccess:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                              failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    self.completionBlock = ^ {
        if([self isCancelled]) {
            if (self.deletesFileUponFailure) {
                [self deleteTempFileWithError:&_downloadError];
            }
            return;
        }else {
            @synchronized(self) {
                NSString *destinationPath = [self destinationPath];
                NSFileManager *fileManager = [[NSFileManager alloc] init];
                if (_allowOverwrite && [fileManager fileExistsAtPath:destinationPath]) {
                    [fileManager removeItemAtPath:destinationPath error:&_downloadError];
                }
                if (!_downloadError) {
                    [fileManager moveItemAtPath:[self temporaryPath] toPath:destinationPath error:&_downloadError];
                }
                [fileManager release];
            }
        }
        
        if (self.error) {
            dispatch_async(self.failureCallbackQueue ? self.failureCallbackQueue : dispatch_get_main_queue(), ^{
                failure(self, self.error);
            });
        } else {
            dispatch_async(self.successCallbackQueue ? self.successCallbackQueue : dispatch_get_main_queue(), ^{
                success(self, _destination);
            });
        }
    };    
}

#pragma mark -

//- (void)setDecideDestinationWithSuggestedFilenameBlock:(void (^)(NSString *filename))block;
//
//- (void)setShouldDecodeSourceDataOfMimeTypeBlock:(BOOL (^)(NSString *encodingType))block;

@end
