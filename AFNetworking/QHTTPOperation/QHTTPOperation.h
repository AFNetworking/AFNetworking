/*
    File:       QHTTPOperation.h

    Contains:   An NSOperation that runs an HTTP request.

    Written by: DTS

    Copyright:  Copyright (c) 2010 Apple Inc. All Rights Reserved.

    Disclaimer: IMPORTANT: This Apple software is supplied to you by Apple Inc.
                ("Apple") in consideration of your agreement to the following
                terms, and your use, installation, modification or
                redistribution of this Apple software constitutes acceptance of
                these terms.  If you do not agree with these terms, please do
                not use, install, modify or redistribute this Apple software.

                In consideration of your agreement to abide by the following
                terms, and subject to these terms, Apple grants you a personal,
                non-exclusive license, under Apple's copyrights in this
                original Apple software (the "Apple Software"), to use,
                reproduce, modify and redistribute the Apple Software, with or
                without modifications, in source and/or binary forms; provided
                that if you redistribute the Apple Software in its entirety and
                without modifications, you must retain this notice and the
                following text and disclaimers in all such redistributions of
                the Apple Software. Neither the name, trademarks, service marks
                or logos of Apple Inc. may be used to endorse or promote
                products derived from the Apple Software without specific prior
                written permission from Apple.  Except as expressly stated in
                this notice, no other rights or licenses, express or implied,
                are granted by Apple herein, including but not limited to any
                patent rights that may be infringed by your derivative works or
                by other works in which the Apple Software may be incorporated.

                The Apple Software is provided by Apple on an "AS IS" basis. 
                APPLE MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING
                WITHOUT LIMITATION THE IMPLIED WARRANTIES OF NON-INFRINGEMENT,
                MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, REGARDING
                THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN
                COMBINATION WITH YOUR PRODUCTS.

                IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT,
                INCIDENTAL OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
                TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
                DATA, OR PROFITS; OR BUSINESS INTERRUPTION) ARISING IN ANY WAY
                OUT OF THE USE, REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION
                OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER UNDER THEORY
                OF CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR
                OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF
                SUCH DAMAGE.

*/

#import "QRunLoopOperation.h"

/*
    QHTTPOperation is a general purpose NSOperation that runs an HTTP request. 
    You initialise it with an HTTP request and then, when you run the operation, 
    it sends the request and gathers the response.  It is quite a complex 
    object because it handles a wide variety of edge cases, but it's very 
    easy to use in simple cases:

    1. create the operation with the URL you want to get
    
    op = [[[QHTTPOperation alloc] initWithURL:url] autorelease];
    
    2. set up any non-default parameters, for example, set which HTTP 
       content types are acceptable
    
    op.acceptableContentTypes = [NSSet setWithObject:@"text/html"];
    
    3. enqueue the operation
    
    [queue addOperation:op];
    
    4. finally, when the operation is done, use the lastResponse and 
       error properties to find out how things went
    
    As mentioned above, QHTTPOperation is very general purpose.  There are a 
    large number of configuration and result options available to you.
    
    o You can specify a NSURLRequest rather than just a URL.
    
    o You can configure the run loop and modes on which the NSURLConnection is 
      scheduled.
    
    o You can specify what HTTP status codes and content types are OK.
      
    o You can set an authentication delegate to handle authentication challenges.
    
    o You can accumulate responses in memory or in an NSOutputStream. 
    
    o For in-memory responses, you can specify a default response size 
      (used to size the response buffer) and a maximum response size 
      (to prevent unbounded memory use).
    
    o You can get at the last request and the last response, to track 
      redirects.

    o There are a variety of funky debugging options to simulator errors 
      and delays.
      
    Finally, it's perfectly reasonable to subclass QHTTPOperation to meet you 
    own specific needs.  Specifically, it's common for the subclass to 
    override -connection:didReceiveResponse: in order to setup the output 
    stream based on the specific details of the response.
*/

@protocol QHTTPOperationAuthenticationDelegate;

@interface QHTTPOperation : QRunLoopOperation /* <NSURLConnectionDelegate> */
{
    NSURLRequest *      _request;
    NSIndexSet *        _acceptableStatusCodes;
    NSSet *             _acceptableContentTypes;
    id<QHTTPOperationAuthenticationDelegate>    _authenticationDelegate;
    NSOutputStream *    _responseOutputStream;
    NSUInteger          _defaultResponseSize;
    NSUInteger          _maximumResponseSize;
    NSURLConnection *   _connection;
    BOOL                _firstData;
    NSMutableData *     _dataAccumulator;
    NSURLRequest *      _lastRequest;
    NSHTTPURLResponse * _lastResponse;
    NSData *            _responseBody;
#if ! defined(NDEBUG)
    NSError *           _debugError;
    NSTimeInterval      _debugDelay;
    NSTimer *           _debugDelayTimer;
#endif
}

- (id)initWithRequest:(NSURLRequest *)request;      // designated
- (id)initWithURL:(NSURL *)url;                     // convenience, calls +[NSURLRequest requestWithURL:]

// Things that are configured by the init method and can't be changed.

@property (copy,   readonly)  NSURLRequest *        request;
@property (copy,   readonly)  NSURL *               URL;

// Things you can configure before queuing the operation.

// runLoopThread and runLoopModes inherited from QRunLoopOperation
@property (copy,   readwrite) NSIndexSet *          acceptableStatusCodes;  // default is nil, implying 200..299
@property (copy,   readwrite) NSSet *               acceptableContentTypes; // default is nil, implying anything is acceptable
@property (assign, readwrite) id<QHTTPOperationAuthenticationDelegate>  authenticationDelegate;

#if ! defined(NDEBUG)
@property (copy,   readwrite) NSError *             debugError;             // default is nil
@property (assign, readwrite) NSTimeInterval        debugDelay;             // default is none
#endif

// Things you can configure up to the point where you start receiving data. 
// Typically you would change these in -connection:didReceiveResponse:, but 
// it is possible to change them up to the point where -connection:didReceiveData: 
// is called for the first time (that is, you could override -connection:didReceiveData: 
// and change these before calling super).

// IMPORTANT: If you set a response stream, QHTTPOperation calls the response 
// stream synchronously.  This is fine for file and memory streams, but it would 
// not work well for other types of streams (like a bound pair).

@property (retain, readwrite) NSOutputStream *      responseOutputStream;   // defaults to nil, which puts response into responseBody
@property (assign, readwrite) NSUInteger            defaultResponseSize;    // default is 1 MB, ignored if responseOutputStream is set
@property (assign, readwrite) NSUInteger            maximumResponseSize;    // default is 4 MB, ignored if responseOutputStream is set
                                                                            // defaults are 1/4 of the above on embedded

// Things that are only meaningful after a response has been received;

@property (assign, readonly, getter=isStatusCodeAcceptable)  BOOL statusCodeAcceptable;
@property (assign, readonly, getter=isContentTypeAcceptable) BOOL contentTypeAcceptable;

// Things that are only meaningful after the operation is finished.

// error property inherited from QRunLoopOperation
@property (copy,   readonly)  NSURLRequest *        lastRequest;       
@property (copy,   readonly)  NSHTTPURLResponse *   lastResponse;       

@property (copy,   readonly)  NSData *              responseBody;   

@end

@interface QHTTPOperation (NSURLConnectionDelegate)

// QHTTPOperation implements all of these methods, so if you override them 
// you must consider whether or not to call super.
//
// These will be called on the operation's run loop thread.

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace;
    // Routes the request to the authentication delegate if it exists, otherwise 
    // just returns NO.
    
- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge;
    // Routes the request to the authentication delegate if it exists, otherwise 
    // just cancels the challenge.

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response;
    // Latches the request and response in lastRequest and lastResponse.
    
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response;
    // Latches the response in lastResponse.
    
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data;
    // If this is the first chunk of data, it decides whether the data is going to be 
    // routed to memory (responseBody) or a stream (responseOutputStream) and makes the 
    // appropriate preparations.  For this and subsequent data it then actually shuffles 
    // the data to its destination.
    
- (void)connectionDidFinishLoading:(NSURLConnection *)connection;
    // Completes the operation with either no error (if the response status code is acceptable) 
    // or an error (otherwise).
    
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;
    // Completes the operation with the error.

@end

@protocol QHTTPOperationAuthenticationDelegate <NSObject>
@required

// These are called on the operation's run loop thread and have the same semantics as their 
// NSURLConnection equivalents.  It's important to realise that there is no 
// didCancelAuthenticationChallenge callback (because NSURLConnection doesn't issue one to us).  
// Rather, an authentication delegate is expected to observe the operation and cancel itself 
// if the operation completes while the challenge is running.

- (BOOL)httpOperation:(QHTTPOperation *)operation canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace;
- (void)httpOperation:(QHTTPOperation *)operation didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge;

@end

extern NSString * kQHTTPOperationErrorDomain;

// positive error codes are HTML status codes (when they are not allowed via acceptableStatusCodes)
//
// 0 is, of course, not a valid error code
//
// negative error codes are errors from the module

enum {
    kQHTTPOperationErrorResponseTooLarge = -1, 
    kQHTTPOperationErrorOnOutputStream   = -2, 
    kQHTTPOperationErrorBadContentType   = -3
};
