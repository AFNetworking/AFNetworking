/*
 
 Copyright (c) 2011 Nextive LLC
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
 associated documentation files (the "Software"), to deal in the Software without restriction,
 including without limitation the rights to use, copy, modify, merge, publish, distribute,
 sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial
 portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
 NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES
 OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 
 Created by Martin Adoue (martin@nextive.com) and Hernan Pelassini (hernan@nextive.com)
 
 */

#import "NXJsonSerializer.h"
#import <Foundation/NSObjCRuntime.h>
#import <objc/runtime.h>
#import "NXDebug.h"
//#import "NSString+Extensions.h"
#import "NXSerializable.h"

#define EXCEPTION_NUMBER_TYPE @"Unexpected NSNumber type"

/** \brief convert an signed long integer to char buffer
 *
 * \param[in] value
 * \param[out] buf the output buffer.  Should be 24 chars or more.
 */
static void modp_litoa10(signed long long value, char* buf);
/** \brief convert an unsigned long integer to char buffer
 *
 * \param[in] value
 * \param[out] buf The output buffer, should be 24 chars or more.
 */
static void modp_ulitoa10(unsigned long long value, char* buf);
static void strreverse(char* begin, char* end);
/** \brief convert a floating point number to char buffer with
 *         fixed-precision format
 *
 * This is similar to "%.[0-9]f" in the printf style.  It will include
 * trailing zeros
 *
 * If the input value is greater than 1<<31, then the output format
 * will be switched exponential format.
 *
 * \param[in] value
 * \param[out] buf  The allocated output buffer.  Should be 32 chars or more.
 * \param[in] precision  Number of digits to the right of the decimal point.
 *    Can only be 0-9.
 */
static void modp_dtoa(double value, char* buf, int precision);




#define resizeIfNeeded(length) \
{ \
	if(_current + length > _length) \
	{ \
		while (_current + length > _length) \
		{ \
			_length *= 2; \
		} \
		_buffer = (char*)realloc(_buffer, _length); \
	}\
}
#define appendBytes(bytes, length) \
{ \
	if(_current + length > _length) \
	{ \
		while (_current + length > _length) \
		{ \
			_length *= 2; \
		} \
		_buffer = (char*)realloc(_buffer, _length); \
	}\
	memcpy(_buffer + _current, bytes, length); \
	_current += length; \
}
#define appendChar(c) \
{ \
	if(_current + 1 > _length) \
	{ \
		_length *= 2; \
		_buffer = (char*)realloc(_buffer, _length); \
	}\
	_buffer[_current++] = c; \
}
#define appendCharNoResize(c) {_buffer[_current++] = c;}

@interface NXJsonSerializer()
-(void)serializeObject:(id)object;

-(void)serializeNull;
-(void)serializeDictionary:(NSDictionary*)object NOTNULL(1);
-(void)serializeArray:(NSArray*)object NOTNULL(1);
-(void)serializeNumber:(NSNumber*)object NOTNULL(1);
-(void)serializeString:(NSString*)object NOTNULL(1);
@end


@implementation NXJsonSerializer

-(void)dealloc
{
	NXReleaseAndNil(_nullClass);
	NXReleaseAndNil(_dictClass);
	NXReleaseAndNil(_arraClass);
	NXReleaseAndNil(_numbClass);
	NXReleaseAndNil(_striClass);
	
	free(_buffer);
	free(_stringBuffer);
	[super dealloc];
}

-(id)init
{
	if ((self = [super init]))
	{
		_nullClass = [[NSNull class] retain];
		_dictClass = [[NSDictionary class] retain];
		_arraClass = [[NSArray class] retain];
		_numbClass = [[NSNumber class] retain];
		_striClass = [[NSString class] retain];
	}
	
	return self;
}

+(NSString*)serialize:(id)object
{
	NXJsonSerializer* serializer = [[NXJsonSerializer alloc] init];
	NSString* retval = [serializer serialize:object];
	NXReleaseAndNil(serializer);
	return retval;
}

+(BOOL)serialize:(id)object toFile:(NSString*)path error:(NSError**)error
{
	ASSERT_CLASS(path, NSString);
	ASSERT(object);
	
	NSString* json = [NXJsonSerializer serialize:object];
	ASSERT_CLASS(json, NSString);
	return [json writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:error];
}

-(NSString*)serialize:(id)object
{
	// If we call this a few times in a row, it makes no sense to free and malloc the buffer.
	if (!_buffer)
	{
		_length = 10 * 1024;
		_buffer = (char*)malloc(_length * sizeof(char));
	}
	_current = 0;
	
	if (!_stringBuffer)
	{
		_stringBufferLength = 10 * 1024;
		_stringBuffer = (UniChar*)malloc(_stringBufferLength * sizeof(UniChar));
	}

	[self serializeObject:object];
	
	return [[[NSString alloc] initWithBytes:_buffer length:_current encoding:NSUTF8StringEncoding] autorelease];
}

-(void)serializeObject:(id)object
{
	
	
	if(!object)
	{
		[self serializeNull];
	}

	/*
	 
	 Fast lookups logic:
	 isKindOfClass looks at the whole hierarchy chain. It takes a while. 
	 Most of the time, all the subclasses of a certain type will be the same in a given dictionary (or array, or whatever).
	 We cache the last subclass (or implementation, in the case of class clusters) for each class and test it with pointer equality. 
	 The difference is huge. 30% or more.
	 
	 Possible optimization: we could run a few tests and reorganize the order of the comparisons. But it's very dependant on the 
	 source structure, so you never really know.
	 
	 */
	// BEGIN FAST LOOKUPS
	else if (object->isa == _dictClassCached)
	{
		[self serializeDictionary:(NSDictionary*)object];
	}
	else if (object->isa == _arraClassCached)
	{
		[self serializeArray:(NSArray*)object];
	}
	else if (object->isa == _striClassCached)
	{
		[self serializeString:(NSString*)object];
	}
	else if (object->isa == _numbClassCached)
	{
		[self serializeNumber:(NSNumber*)object];
	}
	else if (object->isa == _nullClassCached)
	{
		[self serializeNull];
	}
	// END FAST LOOKUPS. From now on we check for subclasses too.
	else if ([object isKindOfClass:_dictClass])
	{
		_dictClassCached = object->isa;
		[self serializeDictionary:(NSDictionary*)object];
	}
	else if ([object isKindOfClass:_arraClass])
	{
		_arraClassCached = object->isa;
		[self serializeArray:(NSArray*)object];
	}
	else if ([object isKindOfClass:_striClass])
	{
		_striClassCached = object->isa;
		[self serializeString:(NSString*)object];
	}
	else if ([object isKindOfClass:_numbClass])
	{
		_numbClassCached = object->isa;
		[self serializeNumber:(NSNumber*)object];
	}
	else if ([object isKindOfClass:_nullClass])
	{
		_nullClassCached = object->isa;
		[self serializeNull];
	}
	else
	{
		if ([object conformsToProtocol:@protocol(NXSerializable)])
		{
			
			NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
			
			id value = [object performSelector:@selector(serialize)];
			ASSERT(![value conformsToProtocol:@protocol(NXSerializable)]); // this will recurse forever
			[self serializeObject:value];
			
			[pool drain];
			
		}
		else
		{
			// Enable this code if you want to know when you're serializing an "unsupported" object.
			// NSString* reason = [NSString stringWithFormat:@"Unsupported object type: %@", [object class]];
			// ASSERT(!reason);
			[self serializeString:[object description]];
		}
	}
}
-(void)serializeNull
{
	appendBytes("null", 4);
}
-(void)serializeDictionary:(NSDictionary*)object
{
	ASSERT(object);
	ASSERT([object isKindOfClass:[NSDictionary class]]);
	ASSERT(_buffer);
	
	appendChar('{');
	
	CFIndex count = CFDictionaryGetCount((CFDictionaryRef)object);
	
	id allKeys[count];
	id allValues[count];
	
	// This is much faster than calling [object allKeys] and iterating.
	CFDictionaryGetKeysAndValues((CFDictionaryRef)object, (void const**)allKeys, (void const**)allValues);
	
	for (CFIndex i = 0; i < count; i++)
	{
		id key = allKeys[i];
		ASSERT(key);
		[self serializeObject:key];
		appendChar(':');
		
		id value = allValues[i];
		ASSERT(value);
		
		[self serializeObject:value];
		appendChar(',');
	}
	
	if (count > 0)
	{
		// remove the last ","
		_current -= 1;
	}
	
	appendChar('}');
	
	ASSERT(_current < _length);
}
-(void)serializeArray:(NSArray*)object
{
	ASSERT(object);
	ASSERT([object isKindOfClass:[NSArray class]]);
	ASSERT(_buffer);
	
	appendChar('[');
	
	for (id key in object)
	{
		ASSERT(key);
		[self serializeObject:key];
		appendChar(',');
	}
	
	if ([object count] > 0)
	{
		// remove the last ","
		_current -= 1;
	}
	
	appendChar(']');
	
	ASSERT(_current < _length);
}
-(void)serializeNumber:(NSNumber*)object
{
	ASSERT(object);
	ASSERT([object isKindOfClass:[NSNumber class]]);
	ASSERT(_buffer);
	
	// Booleans can be tested with pointer equality. 
	if (object == (id)kCFBooleanTrue)
	{
		appendBytes("true", 4);
		ASSERT(_current < _length);
		return;
	}
	else if (object == (id)kCFBooleanFalse)
	{
		appendBytes("false", 5);
		ASSERT(_current < _length);
		return;
	}

	
	const char* objCType = [object objCType];
	ASSERT(strlen(objCType) == 1);
	
	switch(*objCType)
	{
		case 'c':
		case 's':
		case 'i':
		case 'I':
		case 'l':
		case 'q':
		{
			long long value = [object longLongValue];
			resizeIfNeeded(49);
			char converted[50] = {0};
			modp_litoa10(value, converted);
			
			char* str = converted;
			do
			{
				appendCharNoResize(*str);
				str++;
			}
			while (*str != '\0');
			
			break;
		}
		case 'C':
		case 'S':
		case 'Q':
		case 'L':
		{
			unsigned long long value = [object unsignedLongLongValue];
			resizeIfNeeded(49);
			char converted[50] = {0};
			modp_ulitoa10(value, converted);
			char* str = converted;
			do
			{
				appendCharNoResize(*str);
				str++;
			}
			while (*str != '\0');
			
			break;
			break;
		}
		case 'f':
		case 'd': 
		{
			double value = [object doubleValue];
			resizeIfNeeded(99);
			char converted[100] = {0};
			modp_dtoa(value, converted, 9);
			appendBytes(converted, strlen(converted));
			break;
		}
		default:
			[NSException raise:EXCEPTION_NUMBER_TYPE  format:@"Unsupported number type '%c'", *objCType];
			
	}
	
	ASSERT(_current < _length);
}
-(void)serializeString:(NSString*)object
{
	ASSERT(object);
	ASSERT([object isKindOfClass:[NSString class]]);
	ASSERT(_buffer);

	CFStringRef string = (CFStringRef)object;
	CFIndex len = CFStringGetLength(string);
	
	if (len > _stringBufferLength)
	{
		_stringBufferLength = len + 1;
		_stringBuffer = (UniChar*)realloc(_stringBuffer, sizeof(UniChar) * _stringBufferLength);
	}
	CFStringGetCharacters(string, CFRangeMake(0, len), _stringBuffer);  
	
	resizeIfNeeded((len * 6) + 2); // Worst case scenario: every char needs to be unicode encoded, plus the '"'s.
	
	appendCharNoResize('\"');
	for (CFIndex i = 0; i < len; i++)
	{
		UniChar uc = _stringBuffer[i];
		if (uc < 127)
		{
			switch (uc)
			{
				case '\\':
					appendCharNoResize('\\');
					appendCharNoResize('\\');
					break;
				case '/':
					appendCharNoResize('\\');
					appendCharNoResize('/');
					break;
				case '"':
					appendCharNoResize('\\');
					appendCharNoResize('"');
					break;
				case '\b':
					appendCharNoResize('\\');
					appendCharNoResize('b');
					break;
				case '\f':
					appendCharNoResize('\\');
					appendCharNoResize('f');
					break;
				case '\n':
					appendCharNoResize('\\');
					appendCharNoResize('n');
					break;
				case '\r':
					appendCharNoResize('\\');
					appendCharNoResize('r');
					break;
				case '\t':
					appendCharNoResize('\\');
					appendCharNoResize('t');
					break;
				default:
					appendCharNoResize(uc);
					break;
			}
		}
		else
		{
			appendCharNoResize('\\');
			appendCharNoResize('u');
			
			static const char hexDigits[16] = 
			{
				'0', '1', '2', '3', '4', '5', '6', '7', 
				'8', '9', 'a', 'b', 'c', 'd', 'e', 'f'
			};
			
			ASSERT((uc & 0xF000) >> 12 >= 0 && (uc & 0xF000) >> 12 < 16);
			ASSERT((uc & 0x0F00) >> 8 >= 0 && (uc & 0x0F00) >> 8 < 16);
			ASSERT((uc & 0x00F0) >> 4 >= 0 && (uc & 0x00F0) >> 4 < 16);
			ASSERT((uc & 0x000F) >> 0 >= 0 && (uc & 0x000F) >> 0 < 16);
			
			appendCharNoResize(hexDigits[(uc & 0xF000) >> 12]);
			appendCharNoResize(hexDigits[(uc & 0x0F00) >> 8]);
			appendCharNoResize(hexDigits[(uc & 0x00F0) >> 4]);
			appendCharNoResize(hexDigits[(uc & 0x000F) >> 0]);
		}
	}
	
	appendCharNoResize('\"');
	
	ASSERT(_current < _length);
	
}

@end

/*
 * Code adapted from http://code.google.com/p/stringencoders/source/browse/trunk/src/modp_numtoa.h
 * Copyright &copy; 2007, Nick Galbreath -- nickg [at] modp [dot] com
 * All rights reserved.
 * http://code.google.com/p/stringencoders/
 * Released under the MIT license. 
 */
void modp_litoa10(signed long long value, char* str)
{
    char* wstr = str;
    unsigned long long uvalue = (value < 0) ? -value : value;
	
    // Conversion. Number is reversed.
    do 
	{
		*wstr++ = (char)(48 + (uvalue % 10)); 
	}
	while(uvalue /= 10);
	
    if (value < 0)
	{
		*wstr++ = '-';
	}
	
    *wstr = '\0';
	
    // Reverse string
    strreverse(str, wstr - 1);
}

void modp_ulitoa10(unsigned long long value, char* str)
{
    char* wstr = str;
    // Conversion. Number is reversed.
    do
	{
		*wstr++ = (char)(48 + (value % 10)); 
	}
	while (value /= 10);
	
    *wstr = '\0';
    // Reverse string
    strreverse(str, wstr - 1);
}

void strreverse(char* begin, char* end)
{
    while (end > begin)
	{
        char aux = *end;
		*end-- = *begin;
		*begin++ = aux;
	}
}

void modp_dtoa(double value, char* str, int prec)
{
	/**
	 * Powers of 10
	 * 10^0 to 10^9
	 */
	static const double pow10[] = {1, 10, 100, 1000, 10000, 100000, 1000000,
		10000000, 100000000, 1000000000};
	
    /* Hacky test for NaN
     * under -fast-math this won't work, but then you also won't
     * have correct nan values anyways.  The alternative is
     * to link with libmath (bad) or hack IEEE double bits (bad)
     */
    if (! (value == value)) 
	{
        str[0] = 'N'; str[1] = 'a'; str[2] = 'N'; str[3] = '\0';
        return;
    }
    /* if input is larger than thres_max, revert to exponential */
    const double thres_max = (double)(0x7FFFFFFF);

    double diff = 0.0;
    char* wstr = str;
	
    if (prec < 0) 
	{
        prec = 0;
    } 
	else if (prec > 9) 
	{
        /* precision of >= 10 can lead to overflow errors */
        prec = 9;
    }
	
	
    /* we'll work in positive values and deal with the
	 negative sign issue later */
    int neg = 0;
    if (value < 0) 
	{
        neg = 1;
        value = -value;
    }
	
	
    int whole = (int) value;
    double tmp = (value - whole) * pow10[prec];
    uint32_t frac = (uint32_t)(tmp);
    diff = tmp - frac;
	
    if (diff > 0.5) 
	{
        ++frac;
        /* handle rollover, e.g.  case 0.99 with prec 1 is 1.0  */
        if (frac >= pow10[prec]) 
		{
            frac = 0;
            ++whole;
        }
    } 
	else if (diff == 0.5 && ((frac == 0) || (frac & 1))) 
	{
        /* if halfway, round up if odd, OR
		 if last digit is 0.  That last part is strange */
        ++frac;
    }
	
    /* for very large numbers switch back to native sprintf for exponentials.
	 anyone want to write code to replace this? */
    /*
	 normal printf behavior is to print EVERY whole number digit
	 which can be 100s of characters overflowing your buffers == bad
	 */
    if (value > thres_max) 
	{
        sprintf(str, "%e", neg ? -value : value);
        return;
    }
	
    if (prec == 0) 
	{
        diff = value - whole;
        if (diff > 0.5) 
		{
            /* greater than 0.5, round up, e.g. 1.6 -> 2 */
            ++whole;
        } 
		else if (diff == 0.5 && (whole & 1)) 
		{
            /* exactly 0.5 and ODD, then round up */
            /* 1.5 -> 2, but 2.5 -> 2 */
            ++whole;
        }
    } 
	else 
	{
        int count = prec;
        // now do fractional part, as an unsigned number
        do 
		{
            --count;
            *wstr++ = (char)(48 + (frac % 10));
        } while (frac /= 10);
        // add extra 0s
        while (count-- > 0)
		{
			*wstr++ = '0';
		}
        // add decimal
        *wstr++ = '.';
    }
	
    // do whole part
    // Take care of sign
    // Conversion. Number is reversed.
    do
	{
		*wstr++ = (char)(48 + (whole % 10)); 
	} while (whole /= 10);
	
    if (neg) 
	{
        *wstr++ = '-';
    }
    *wstr='\0';
    strreverse(str, wstr-1);
}




