// AFHTTPRequestProcessingOperation.h
//
// Copyright (c) 2013 Paul Melnikow
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
 `AFHTTPRequestProcessingOperation` is a subclass of `AFHTTPRequestOperation` which provides support for deserializing response data into an Objective-C object. It encapsulates a processed response object, a processing error, and an optional dispatch queue for processing.
 */

@interface AFHTTPRequestProcessingOperation : AFHTTPRequestOperation

/**
 The dispatch queue for processing, used by the completion block. If `NULL` (default), a shared, concurrent queue is used.
 */
@property (nonatomic, assign) dispatch_queue_t processingQueue;

///---------------------------------------
/// @name Properties for subclasses to set
///---------------------------------------

/**
 The processed response object, derived from the response and response data.
 
 Subclasses may redeclare this property to indicate its type.
 */
@property (nonatomic, retain) id responseObject;

/**
 Subclasses may set this method to indicate that an error occurred during processing.
 */
@property (nonatomic, retain) NSError *processingError;

///-----------------------------------------
/// @name Methods for subclasses to override
///-----------------------------------------

/**
 Subclasses must override this method to deserialize the response data. Provided the HTTP request is successful, the receiver invokes this method on the processing queue in the completion block.
 
 This method should set responseObject and should set processingError in case of an error.
 
 @warning The default implementation raises an exception.
 */
- (void)processResponse;

@end
