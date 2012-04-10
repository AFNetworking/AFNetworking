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

/**
 
 */
@interface AFDownloadRequestOperation : AFHTTPRequestOperation;

/** 
 A Boolean value that indicates if we should try to resume the download. Defaults is `YES`.
 
 Can only be set while creating the request.
 
 Note: This allows long-lasting resumes between app-starts. Use this for content that doesn't change.
 If the file changed in the meantime, you'll end up with a broken file.
 */
@property (assign, readonly) BOOL shouldResume;

/**
 Set a destination. If you don't manually set one, this defaults to the documents directory.
 Note: This can point to a path or a file. If this is a path, response.suggestedFilename will be used for the filename.
 */
- (void)setDestination:(NSString *)path allowOverwrite:(BOOL)allowOverwrite;


/** 
 Deletes the temporary file if operation fails/is cancelled. Defaults to `NO`.
 */
@property (assign) BOOL deletesFileUponFailure;


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
