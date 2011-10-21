//
//  YHTBTMediaFileRequestOperation.h
//  YouHadToBeThere
//
//  Created by Justin Marrington on 21/10/11.
//  Copyright (c) 2011 University of Queensland. All rights reserved.
//

#import "AFHTTPRequestOperation.h"

@interface AFFileRequestOperation : AFHTTPRequestOperation {
@private
    NSString *_filePath;
    NSString *_saveDirectory;
}

/**
 Custom initialiser for file requests. If you're gong to use a custom file type not included in the standard 'safe' file types in this class (see +defaultAcceptableMimeTypes), you should call this initialiser when instantiating your request
 
 @param urlRequest The request object to be loaded asynchronously during execution of the operation.
 @param mimeTypes A set of one or more custom mime types that you want to be able to download using this operation.
 
 @return A new file request operation
 */
- (id)initWithRequest:(NSURLRequest *)urlRequest andAcceptableFileTypes:(NSSet *)mimeTypes;

/**
 Adds a set of file type of your choice to the acceptable file type headers for this http request. Make sure you call this before you execute the operation if you're aiming to use a non-standard file type.
 
 @param mimeType An NSSEt containing one or more mime type that you want to except, for example `application/pdf` for PDF, or `audio/mpeg` for mp3 files.
 */
- (void)addAcceptableFilesWithMimeTypes:(NSSet *)mimeTypes;


/**
 Creates and returns an `AFFileRequestOperation` object and sets the specified success callback. This operation will save the file data returned from the request to the specified path on the local device filesystem, and then return this path in the success block. To get the file data itself, use the sister method fileDataRequestOperation:fileProcessingBLock:filesystemPath:success:failure.
 
 @param urlRequest The request object to be loaded asynchronously during execution of the operation.
 @param fileProcessingBlock A block object to be executed after the file request finishes successfully, but before the local path to the file is returned in the `success` block. This block takes a single argument, the file loaded from the response body, and returns the possibly modified file data.
 @param filesystemPath The absolute path on the local filesystem where you want to persist this file. If a file already exists with the same name at this location, the final path will have a date string appended at the end of the filename (e.g. mydocument_27_06_2011_0900.pdf rather than mydocument.pdf)
 @param success A block object to be executed when the request finishes successfully, with a status code in the 2xx range, and with an acceptable content type (e.g. `application/pdf`). This block has no return value and takes three arguments: the request object of the operation, the response for the request, and the path to the file created from the response data.
 @param failure A block object to be executed when the request finishes unsuccessfully. This block has no return value and takes three arguments: the request object of the operation, the response for the request, and the error associated with the cause for the unsuccessful operation.
 
 @return A new image request operation
 */
+ (AFFileRequestOperation *)fileRequestOperationWithRequest:(NSURLRequest *)urlRequest
                                         fileProcessingBlock:(NSData *(^)(NSData *))fileProcessingBlock
                                                    filesystemPath:(NSString *)filesystemPathOrNil
                                                      success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSString *filePath))success
                                                      failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error))failure;

@end
