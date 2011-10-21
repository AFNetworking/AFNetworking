//
//  YHTBTMediaFileRequestOperation.m
//  YouHadToBeThere
//
//  Created by Justin Marrington on 21/10/11.
//  Copyright (c) 2011 University of Queensland. All rights reserved.
//

#import "AFFileRequestOperation.h"

static dispatch_queue_t af_file_request_operation_processing_queue;
static dispatch_queue_t file_request_operation_processing_queue() {
    if (af_file_request_operation_processing_queue == NULL) {
        af_file_request_operation_processing_queue = dispatch_queue_create("com.alamofire.networking.file-request.processing", 0);
    }
    
    return af_file_request_operation_processing_queue;
}

@interface AFFileRequestOperation ()
@property (nonatomic, retain) NSString *saveDirectory;
@property (nonatomic, copy) NSString *filePath;

+ (NSSet *)defaultAcceptableContentTypes;
+ (NSSet *)defaultAcceptablePathExtensions;
@end

@implementation AFFileRequestOperation
@synthesize saveDirectory = _saveDirectory;
@synthesize filePath = _filePath;

- (void)addAcceptableFilesWithMimeTypes:(NSSet *)mimeTypes
{
    self.acceptableContentTypes = [self.acceptableContentTypes setByAddingObjectsFromSet:mimeTypes];
}

+ (NSSet *)defaultAcceptableContentTypes {
    return [NSSet setWithObjects:@"application/pdf", @"application/xml", @"audio/mp4a-latm", @"audio/mpeg", @"video/x-m4v", nil];
}

+ (NSSet *)defaultAcceptablePathExtensions {
    return [NSSet setWithObjects:@"pdf", @".epub", @"m4a", @"mp3", @"m4v", nil];
}


#pragma mark - AFHTTPClientOperation

+ (BOOL)canProcessRequest:(NSURLRequest *)request {
    return [[self defaultAcceptableContentTypes] containsObject:[request valueForHTTPHeaderField:@"Accept"]] || [[self defaultAcceptablePathExtensions] containsObject:[[request URL] pathExtension]];
}

+ (AFHTTPRequestOperation *)HTTPRequestOperationWithRequest:(NSURLRequest *)urlRequest
                                                    success:(void (^)(id object))success 
                                                    failure:(void (^)(NSHTTPURLResponse *response, NSError *error))failure
{
    return [self fileRequestOperationWithRequest:urlRequest fileProcessingBlock:nil filesystemPath:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, NSString *filePath) {
        success(filePath);
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
        failure(response, error);
    }];
}


+ (AFFileRequestOperation *)fileRequestOperationWithRequest:(NSURLRequest *)urlRequest
                                        fileProcessingBlock:(NSData *(^)(NSData *))fileProcessingBlock
                                             filesystemPath:(NSString *)filesystemPath
                                                    success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSString *filePath))success
                                                    failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error))failure;
{
    AFFileRequestOperation *operation = [[[AFFileRequestOperation alloc] initWithRequest:urlRequest] autorelease];
    operation.saveDirectory = filesystemPath;
    
    operation.completionBlock = ^ {
        if ([operation isCancelled]) {
            return;
        }
        
        dispatch_async(file_request_operation_processing_queue(), ^(void) {
            if (operation.error) {
                if (failure) {
                    dispatch_async(dispatch_get_main_queue(), ^(void) {
                        failure(operation.request, operation.response, operation.error);
                    });
                }
            } else {
                NSData *fileData = operation.responseData;
                
                if (fileProcessingBlock) {
                    fileData = fileProcessingBlock(fileData);
                }
                
                if (success) {
                    dispatch_async(dispatch_get_main_queue(), ^(void) {
                        success(operation.request, operation.response, operation.filePath);
                    });
                }
            }
        });        
    };
    
    return operation;
}

- (id)initWithRequest:(NSURLRequest *)urlRequest
{
    self = [super initWithRequest:urlRequest];
    if (self) {
        self.acceptableContentTypes = [self.class defaultAcceptableContentTypes];
    }
    
    return self;
}

- (id)initWithRequest:(NSURLRequest *)urlRequest andAcceptableFileTypes:(NSSet *)mimeTypes
{
    self = [super initWithRequest:urlRequest];
    if (self) {
        [self addAcceptableFilesWithMimeTypes:mimeTypes];
    }
    
    return self;
}

- (NSString *)filePath
{
    if (!_filePath && [self isFinished]) {
        if (!_saveDirectory) {
            _saveDirectory = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"my_files"];
        }
        
        NSString *filename = [self.response.URL lastPathComponent];
        NSString *absolutePath = [self.saveDirectory stringByAppendingPathComponent:filename];
        
        NSFileManager *fm = [NSFileManager defaultManager];
        
        // If there is already a file of this name saved here, append an underscore-formatted date string to the file name.
        if ([fm fileExistsAtPath:absolutePath]) {
            NSString *minusExtension = [absolutePath stringByDeletingPathExtension];
            NSDateFormatter *df = [[NSDateFormatter alloc] init];
            [df setDateFormat:@"_yyyy_MM_dd_hh_mm_ss"];
            NSString *newFilenameMinusExtension = [minusExtension stringByAppendingString:[df stringFromDate:[NSDate date]]];
            self.filePath = [newFilenameMinusExtension stringByAppendingPathExtension:[absolutePath pathExtension]];
            
            [df release];
        }
        
        [fm createFileAtPath:self.filePath contents:self.responseData attributes:nil];
    }
    
    return _filePath;
}

- (void)dealloc {
    
    [super dealloc];
}

@end
