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
@property (readwrite, nonatomic, copy) NSString *responsePath;
@property (readwrite, nonatomic, retain) NSError *downloadError;
@property (readwrite, nonatomic, copy) NSString *destination;
@property (readwrite, nonatomic, assign) BOOL allowOverwrite;
@property (readwrite, nonatomic, assign) BOOL deletesFileUponFailure;
@end

@implementation AFDownloadRequestOperation
@synthesize responsePath = _responsePath;
@synthesize downloadError = _downloadError;
@synthesize destination = _destination;
@synthesize allowOverwrite = _allowOverwrite;
@synthesize deletesFileUponFailure = _deletesFileUponFailure;

- (void)dealloc {
    [_responsePath release];
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

#pragma mark -

/**
 
 */
- (void)setDestination:(NSString *)path allowOverwrite:(BOOL)allowOverwrite {
    [self willChangeValueForKey:@"isReady"];
    self.destination = path;
    self.allowOverwrite = allowOverwrite;
    [self didChangeValueForKey:@"isReady"];
}

#pragma mark - NSOperation

- (BOOL)isReady {
    return [super isReady] && self.destination;
}

- (void)start {
    if ([self isReady]) {
        // TODO Create temporary path
        self.outputStream = [NSOutputStream outputStreamToFileAtPath:self.destination append:NO];
        
        [super start];
    }
}


#pragma mark -

///**
// 
// */
//- (void)setDecideDestinationWithSuggestedFilenameBlock:(void (^)(NSString *filename))block;
//
///**
// 
// */
//- (void)setShouldDecodeSourceDataOfMimeTypeBlock:(BOOL (^)(NSString *encodingType))block;

@end
