// AFDERDecoder.h
// Copyright (c) 2011–2015 Alamofire Software Foundation (http://alamofire.org/)
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

#import <Foundation/Foundation.h>

enum derIdentifierClass
{
    derIdentifierUniversalClass = 0x00,
    derIdentifierApplicationClass = 0x40,
    derIdentifierContextSpecificClass = 0x80,
    derIdentifierPrivateClass = 0xc0,

    derIdentifierInvalidClass = -1,
};

enum derIdentifierPC
{
    derIdentifierPrimitive = 0x00,
    derIdentifierConstructed = 0x20,

    derIdentifierInvalidPC = derIdentifierInvalidClass,
};

enum derIdentifierUniversalTagNumber
{
    derIdentifierUniversalSequence = 0x10,
};

@interface AFDERDecoder : NSObject

- (id)initWithData:(NSData *)data;

@property (copy, nonatomic, readonly) NSData *data;
@property (assign, nonatomic, readonly) enum derIdentifierClass derIdentifierClass;
@property (assign, nonatomic, readonly) enum derIdentifierPC derIdentifierPrimitiveOrConstructed;
@property (strong, nonatomic, readonly) NSNumber *derIdentifierTag;
@property (copy, nonatomic, readonly) NSData *derContent;
@property (copy, nonatomic, readonly) NSArray *nestedContent;

@end

@interface AFDERDecoder (Diagnostics)

- (void)dumpHierarchy;

@end

@interface NSData (X509)

- (NSData *)dataForX509CertificateSubjectPublicKeyInfo;

@end
