// AFDERDecoder.m
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

#import "AFDERDecoder.h"

#if (NSIntegerMax > NSUIntegerMax)
#error NSUInteger range must be above NSInteger
#endif

enum masks
{
    IDENTIFIER_CLASS_MASK = 0xc0,
    IDENTIFIER_PC_MASK = 0x20,
};

const NSInteger derContentLengthInvalid = -1;
const NSInteger derContentLengthIndeterminate = -2;

@interface AFDERDecoder()
{
    struct
    {
        unsigned int decodedData:1;
        unsigned int decodedIdentifier:1;
        unsigned int decodedContentLength:1;
        unsigned int decodedContent:1;
        unsigned int decodedNestedContent:1;
    } flags_;
    // Not valid unless above flags are set.
    NSData *data_;
    NSNumber *derIdentifierTag_;
    NSInteger derContentLength_;
    NSData *content_;
    NSArray *nestedContent_;
}

@property (copy, nonatomic, readonly) NSData *rawData;
@property (assign, nonatomic) NSUInteger sizeOfIdentifier;
@property (assign, nonatomic) NSUInteger sizeOfContentLength;
@property (assign, nonatomic, readonly) NSInteger derContentLength;

- (int)examineFirstByte:(int (^)(UInt8 firstByte))checker;
- (void)decodeIdentifierTag;
- (void)decodeContentLength;
- (void)decodeData;
- (void)decodeContent;
- (void)decodeNestedContent;
- (void)decodeNestedContentWithLength:(NSNumber *)lengthOfNestedContent;

@end

@implementation AFDERDecoder

@synthesize rawData = rawData_;
@synthesize sizeOfIdentifier = sizeOfIdentifier_;
@synthesize sizeOfContentLength = sizeOfContentLength_;

- (id)initWithData:(NSData *)data
{
    if ((self = [super init]))
    {
        rawData_ = [data copy];
    }
    return self;
}

- (NSString *)description
{
    NSString *class;
    switch (self.derIdentifierClass)
    {
        case derIdentifierUniversalClass:
            class = @"Universal";
            break;
        case derIdentifierApplicationClass:
            class = @"Application";
            break;
        case derIdentifierContextSpecificClass:
            class = @"Context-Specific";
            break;
        case derIdentifierPrivateClass:
            class = @"Private";
            break;
        default:
            class = @"Unknown";
    }
    char pc;
    switch (self.derIdentifierPrimitiveOrConstructed)
    {
        case derIdentifierPrimitive:
            pc = 'P';
            break;
        case derIdentifierConstructed:
            pc = 'C';
            break;
        default:
            pc = '?';
            break;
    }
    NSNumber * const tag = [self derIdentifierTag];
    const NSInteger contentLength = [self derContentLength];
    NSString *descriptionFormat;
    switch (contentLength)
    {
        case derContentLengthInvalid:
            descriptionFormat = NSLocalizedString(@"<%@:%@[%c] invalid>", @"Identifier class, tag, primitive/constructed flag");
            break;
        case derContentLengthIndeterminate:
            descriptionFormat = NSLocalizedString(@"<%@:%@[%c] len=?>", @"Identifier class, tag, primitive/constructed flag");
            break;
        default:
            descriptionFormat = NSLocalizedString(@"<%@:%@[%c] len=%ld>", @"Identifier class, tag, primitive/constructed flag, length");
    }
    NSString * const description = [NSString stringWithFormat:descriptionFormat, class, tag, pc, (long)contentLength];
    return description;
}

- (NSData *)data
{
    if (!flags_.decodedData)
    {
        [self decodeData];
    }
    return data_;
}

- (enum derIdentifierClass)derIdentifierClass
{
    enum derIdentifierClass class = (enum derIdentifierClass)[self examineFirstByte:^(const UInt8 firstByte)
    {
        return (firstByte & IDENTIFIER_CLASS_MASK);
    }];
    return class;
}

- (enum derIdentifierPC)derIdentifierPrimitiveOrConstructed
{
    enum derIdentifierPC derIdentifierPc = (enum derIdentifierPC)[self examineFirstByte:^(const UInt8 firstByte)
    {
        return (firstByte & IDENTIFIER_PC_MASK);
    }];
    return derIdentifierPc;
}

- (NSNumber *)derIdentifierTag
{
    if (!flags_.decodedIdentifier)
    {
        [self decodeIdentifierTag];
    }
    return derIdentifierTag_;
}

- (NSInteger)derContentLength
{
    if (!flags_.decodedContentLength)
    {
        [self decodeContentLength];
    }
    return derContentLength_;
}

- (NSData *)derContent
{
    if (!flags_.decodedContent)
    {
        [self decodeContent];
    }
    return content_;
}

- (NSArray *)nestedContent
{
    if (!flags_.decodedNestedContent)
    {
        [self decodeNestedContent];
    }
    return nestedContent_;
}

- (NSUInteger)sizeOfIdentifier
{
    if (!flags_.decodedIdentifier)
    {
        [self decodeIdentifierTag];
    }
    return sizeOfIdentifier_;
}

- (NSUInteger)sizeOfContentLength
{
    if (!flags_.decodedContentLength)
    {
        [self decodeContentLength];
    }
    return sizeOfContentLength_;
}

- (int)examineFirstByte:(int (^)(const UInt8 firstByte))checker
{
    int result;
    NSData * const data = self.rawData;
    if (0 < [data length])
    {
        const UInt8 * const bytes = [data bytes];
        result = checker(bytes[0]);
    }
    else
    {
        result = derIdentifierInvalidClass;
    }
    return result;
}

- (void)decodeIdentifierTag
{
    NSNumber *tag = nil;
    NSData * const data = self.rawData;
    const NSUInteger length = [data length];
    if (length > 0)
    {
        const UInt8 * const bytes = [data bytes];
        const UInt8 tinyTag = (bytes[0] & 0x1f);
        if (tinyTag != 0x1f)
        {
            // The tag fit within 5 bits.
            tag = [NSNumber numberWithUnsignedChar:tinyTag];
            self.sizeOfIdentifier = 1;
        }
        else
        {
            // Tag is greater than 30; escalate to using an unsigned long long.
            unsigned long long smallTag = 0;
            for (NSUInteger i = 1; i < length; ++i)
            {
                UInt8 octet = bytes[i];
                smallTag = (smallTag << 7) | (octet & 0x7f);
                if ((octet & 0x80) != 0x80)
                {
                    tag = [NSNumber numberWithUnsignedLongLong:smallTag];
                    self.sizeOfIdentifier = i;
                    break;
                }
                else if (i == (sizeof(smallTag) * 8 / 7))
                {
                    // Tag doesn't fit within unsigned long long; escalate to NSDecimal.
                    NSDecimalNumber * const shiftSize = [[NSDecimalNumber alloc] initWithUnsignedInteger:0x80];
                    NSDecimalNumberHandler * const handler =
                        [[NSDecimalNumberHandler alloc] initWithRoundingMode:NSRoundPlain
                                                                       scale:0
                                                            raiseOnExactness:YES
                                                             raiseOnOverflow:YES
                                                            raiseOnUnderflow:YES
                                                         raiseOnDivideByZero:YES];
                    NSDecimalNumber *largeTag = [[NSDecimalNumber alloc] initWithUnsignedLongLong:smallTag];
                    while (++i < length)
                    {
                        octet = bytes[i];
                        NSDecimalNumber * const newBits = [[NSDecimalNumber alloc] initWithUnsignedChar:(octet & 0x7f)];
                        @try
                        {
                            largeTag = [largeTag decimalNumberByMultiplyingBy:shiftSize withBehavior:handler];
                        }
                        @catch (NSException * const exception)
                        {
                            if ([NSDecimalNumberOverflowException isEqualToString:[exception name]])
                            {
                                // The tag number doesn't fit. We'll continue processing so that the size can be
                                // determined, but the tag number itself will be returned as nil.
                                largeTag = nil;
                            }
                            else
                            {
                                @throw;
                            }
                        }
                        largeTag = [largeTag decimalNumberByAdding:newBits];
                        if ((octet & 0x80) == 0x80)
                        {
                            tag = largeTag;
                            self.sizeOfIdentifier = i;
                            break;
                        }
                    }
                    break;
                }
            }
        }
    }
    derIdentifierTag_ = tag;
    flags_.decodedIdentifier = YES;
}

- (void)decodeContentLength
{
    // Initial offset depends on the size of the tag. Parse the tag if not already done.
    NSUInteger startOfContentLength = self.sizeOfIdentifier;
    NSInteger contentLength = derContentLengthInvalid;
    if (0 != startOfContentLength)
    {
        NSData * const data = self.rawData;
        const NSUInteger length = [data length];
        const NSUInteger maxReadable = (length - startOfContentLength);
        if (maxReadable > 0)
        {
            const UInt8 * const bytes = [data bytes];
            const UInt8 firstByte = bytes[startOfContentLength];
            if (firstByte != 0x80)
            {
                const UInt8 size = firstByte & (0x7f);
                if ((firstByte & 0x80) != 0x80)
                {
                    contentLength = size;
                    self.sizeOfContentLength = 1;
                }
                else if (size <= maxReadable)
                {
                    // Even if the length doesn't fit within NSInteger we can still work with
                    // its size.
                    if (size <= sizeof(NSUInteger))
                    {
                        ++startOfContentLength;
                        NSUInteger accumulator = 0;
                        for (unsigned int i = 0; i < size; ++i)
                        {
                            const UInt8 byte = bytes[startOfContentLength + i];
                            accumulator = (accumulator << 8) + byte;
                        }
                        if (accumulator < (NSUInteger)NSIntegerMax)
                        {
                            contentLength = (NSInteger)accumulator;
                        }
                    }
                    self.sizeOfContentLength = (size + 1);
                }
            }
            else
            {
                contentLength = derContentLengthIndeterminate;
                self.sizeOfContentLength = 1;
            }
        }
    }
    derContentLength_ = contentLength;
    flags_.decodedContentLength = YES;
}

- (void)decodeData
{
    const NSUInteger sizeOfIdentifier = self.sizeOfIdentifier;
    if (0 < sizeOfIdentifier)
    {
        const NSUInteger sizeOfContentLength = self.sizeOfContentLength;
        if (0 < sizeOfContentLength)
        {
            const NSUInteger sizeOfPreamble = sizeOfIdentifier + sizeOfContentLength;
            // Guard against overflow.
            if (sizeOfPreamble > sizeOfIdentifier && sizeOfPreamble > sizeOfContentLength)
            {
                NSData * const content = self.derContent;
                if (nil != content)
                {
                    const NSUInteger sizeOfContent = [content length];
                    const NSUInteger sizeOfData = sizeOfPreamble + sizeOfContent;
                    // Guard against overflow.
                    if (sizeOfData >= sizeOfPreamble && sizeOfData > sizeOfContent)
                    {
                        NSData * const rawData = self.rawData;
                        data_ = (sizeOfData < [rawData length]) ? [rawData subdataWithRange:NSMakeRange(0, sizeOfData)] : [rawData copy];
                    }
                }
            }
        }
    }
    flags_.decodedData = YES;
}

- (void)decodeContent
{
    const NSInteger contentLength = self.derContentLength;
    switch (contentLength)
    {
        case derContentLengthInvalid:
            break;
        case derContentLengthIndeterminate:
            [self decodeNestedContentWithLength:nil];
            flags_.decodedNestedContent = YES;
            break;
        default:
        {
            const NSUInteger startOfContent = self.sizeOfIdentifier + self.sizeOfContentLength;
            NSData * const data = self.rawData;
            const NSUInteger maxContentLength = [data length] - startOfContent;
            if ((NSUInteger)contentLength <= maxContentLength)
            {
                content_ = [data subdataWithRange:NSMakeRange(startOfContent, (NSUInteger)contentLength)];
            }
        }
    }
    flags_.decodedContent = YES;
}

- (void)decodeNestedContent
{
    const NSInteger contentLength = self.derContentLength;
    switch (contentLength)
    {
        case derContentLengthInvalid:
            break;
        case derContentLengthIndeterminate:
            [self decodeNestedContentWithLength:nil];
            break;
        default:
            [self decodeNestedContentWithLength:[NSNumber numberWithInteger:contentLength]];
            break;
    }
    flags_.decodedNestedContent = YES;
}

- (void)decodeNestedContentWithLength:(NSNumber *)lengthOfNestedContent
{
    const NSUInteger startOfContent = self.sizeOfIdentifier + self.sizeOfContentLength;
    NSData * const data = self.rawData;
    const NSUInteger dataLength = (nil != lengthOfNestedContent) ? (startOfContent + [lengthOfNestedContent unsignedIntegerValue]) : [data length];
    NSUInteger contentLength = 0;
    NSMutableArray *nestedContent = [[NSMutableArray alloc] init];
    for (;;)
    {
        const NSUInteger cursor = startOfContent + contentLength;
        if (cursor >= dataLength)
        {
            // Finished.
            break;
        }
        const NSUInteger remainingLength = dataLength - cursor;
        if (nil == lengthOfNestedContent)
        {
            if (remainingLength < 2)
            {
                // Invalid content; no terminating sequence.
                nestedContent = nil;
                break;
            }
            const UInt8 * const bytes = [data bytes];
            if (bytes[cursor] == 0 && bytes[cursor+1] == 0)
            {
                // Terminating sequence found.
                contentLength += 2;
                break;
            }
        }
        NSData * const nestedRawData = [data subdataWithRange:NSMakeRange(cursor, remainingLength)];
        AFDERDecoder * const nestedDecoder = [[AFDERDecoder alloc] initWithData:nestedRawData];
        NSData * const nestedData = nestedDecoder.data;
        if (nil == nestedData)
        {
            // Invalid nested content.
            nestedContent = nil;
            break;
        }
        [nestedContent addObject:nestedDecoder];
        contentLength += [nestedData length];
    }
    if (nil != nestedContent)
    {
        nestedContent_ = [nestedContent copy];
        if (!flags_.decodedContent)
        {
            content_ = [rawData_ subdataWithRange:NSMakeRange(startOfContent, contentLength)];
            flags_.decodedContent = YES;
        }
    }
}

@end

@implementation AFDERDecoder (Diagnostics)

- (void)dumpHierarchy:(const NSUInteger)indentLevel
{
    static const NSUInteger INDENT_SIZE = 2;
    NSLog(@"%*s%@", indentLevel * INDENT_SIZE, "", self);
    for (AFDERDecoder * const nestedItem in self.nestedContent)
    {
        [nestedItem dumpHierarchy:indentLevel + 1];
    }
}

- (void)dumpHierarchy
{
    NSLog(@"DER encoded data:");
    [self dumpHierarchy:1];
}

@end

@implementation NSData (X509)

- (NSData *)dataAtIndexPath:(NSIndexPath *)indexPath
{
    AFDERDecoder *decoder = [[AFDERDecoder alloc] initWithData:self];
    const NSUInteger pathLength = [indexPath length];
    NSUInteger indexes[pathLength];
    [indexPath getIndexes:indexes];
    NSNumber * const sequenceTag = [NSNumber numberWithInt:derIdentifierUniversalSequence];
    for (NSUInteger i = 0; i < pathLength; ++i)
    {
        if (derIdentifierUniversalClass == decoder.derIdentifierClass
            && [decoder.derIdentifierTag isEqualToNumber:sequenceTag])
        {
            NSArray * const nestedContent = decoder.nestedContent;
            const NSUInteger index = indexes[i];
            if (index >= [nestedContent count])
            {
                decoder = nil;
                break;
            }
            decoder = [nestedContent objectAtIndex:index];
        }
    }
    return [decoder data];
}

- (NSData *)dataForX509CertificateSubjectPublicKeyInfo
{
    // These indexes work because there are no optional parts before the SPKI.
    NSUInteger indexPathForSPKI[] = { 0, 6, };
    NSIndexPath * const indexPath = [[NSIndexPath alloc] initWithIndexes:indexPathForSPKI
                                                                  length:sizeof(indexPathForSPKI)/sizeof(indexPathForSPKI[0])];
    return [self dataAtIndexPath:indexPath];
}

@end
