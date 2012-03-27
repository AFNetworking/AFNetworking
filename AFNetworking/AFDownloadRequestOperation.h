// AFDownloadRequestOperation.h
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

#import "AFHTTPRequestOperation.h"

#define kAFNetworkingIncompleteDownloadFolderName @"Incomplete"

/**
 `AFDownloadRequestOperation` is a subclass of `AFHTTPRequestOperation` for streamed file downloading. Supports Content-Range. (http://tools.ietf.org/html/rfc2616#section-14.16)
 */
@interface AFDownloadRequestOperation : AFURLConnectionOperation {
@private
    NSString *_responsePath;
    NSError *_downloadError;
    NSString *_destination;
    BOOL _allowOverwrite;
    BOOL _deletesFileUponFailure;
}

@property (readonly, nonatomic, copy) NSString *responsePath;

/**
 
 */
- (void)setDestination:(NSString *)path allowOverwrite:(BOOL)allowOverwrite;

/**
 
 */
- (BOOL)deletesFileUponFailure;

/**
 
 */
- (void)setDeletesFileUponFailure:(BOOL)deletesFileUponFailure;


///**
// 
// */
//- (void)setDecideDestinationWithSuggestedFilenameBlock:(void (^)(NSString *filename))block;
//
///**
// 
// */
//- (void)setShouldDecodeSourceDataOfMimeTypeBlock:(BOOL (^)(NSString *encodingType))block;
//

@end
