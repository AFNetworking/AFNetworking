/*
    File:       QRunLoopOperation.h

    Contains:   An abstract subclass of NSOperation for async run loop based operations.

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

#import <Foundation/Foundation.h>

enum QRunLoopOperationState {
    kQRunLoopOperationStateInited, 
    kQRunLoopOperationStateExecuting, 
    kQRunLoopOperationStateFinished
};
typedef enum QRunLoopOperationState QRunLoopOperationState;

@interface QRunLoopOperation : NSOperation
{
    QRunLoopOperationState  _state;
    NSThread *              _runLoopThread;
    NSSet *                 _runLoopModes;
    NSError *               _error;
}

// Things you can configure before queuing the operation.

// IMPORTANT: Do not change these after queuing the operation; it's very likely that 
// bad things will happen if you do.

@property (retain, readwrite) NSThread *                runLoopThread;          // default is nil, implying main thread
@property (copy,   readwrite) NSSet *                   runLoopModes;           // default is nil, implying set containing NSDefaultRunLoopMode

// Things that are only meaningful after the operation is finished.

@property (copy,   readonly ) NSError *                 error;

// Things you can only alter implicitly.

@property (assign, readonly ) QRunLoopOperationState    state;
@property (retain, readonly ) NSThread *                actualRunLoopThread;    // main thread if runLoopThread is nil, runLoopThread otherwise
@property (assign, readonly ) BOOL                      isActualRunLoopThread;  // YES if the current thread is the actual run loop thread
@property (copy,   readonly ) NSSet *                   actualRunLoopModes;     // set containing NSDefaultRunLoopMode if runLoopModes is nil or empty, runLoopModes otherwise

@end

@interface QRunLoopOperation (SubClassSupport)

// Override points

// A subclass will probably need to override -operationDidStart and -operationWillFinish 
// to set up and tear down its run loop sources, respectively.  These are always called 
// on the actual run loop thread.
//
// Note that -operationWillFinish will be called even if the operation is cancelled. 
//
// -operationWillFinish can check the error property to see whether the operation was 
// successful.  error will be NSCocoaErrorDomain/NSUserCancelledError on cancellation. 
//
// -operationDidStart is allowed to call -finishWithError:.

- (void)operationDidStart;
- (void)operationWillFinish;

// Support methods

// A subclass should call finishWithError: when the operation is complete, passing nil 
// for no error and an error otherwise.  It must call this on the actual run loop thread. 
// 
// Note that this will call -operationWillFinish before returning.

- (void)finishWithError:(NSError *)error;

@end
