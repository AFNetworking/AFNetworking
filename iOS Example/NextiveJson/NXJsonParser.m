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

#import "NXJsonParser.h"
#import "NSError+Extensions.h"

NSString* const kUnexpectedCharException = @"UnexpectedCharException";
NSString* const kUnexpectedControlCharException = @"UnexpectedControlCharException";
NSString* const kUnexpectedEndOfFileException = @"UnexpectedEndOfFileException";
NSString* const kUnexpectedHexCharException = @"UnexpectedHexCharException";

NSString* const kNextiveJsonParserErrorDomain = @"com.nextive.NXJsonParser";

@interface NXJsonParser()
-(void)skipWhitespace;
-(NSDictionary*)newDictionary;
-(NSArray*)newArray;
-(NSString*)newString;
-(NSNumber*)newNumber;
-(NSNumber*)newBoolean;
-(NSNull*)newNull;
-(id)newObject;

// Deprecated. Replaced with the inline macros below. 
//-(BOOL)hasData;
//-(char)currentChar;
//-(char)nextChar;
@end

#define currentChar() (_bytes[_current])
#define hasData() (_current < _length)
#define nextChar() (_bytes[_current + 1])
#define skip() (_current++)

static const char _true_chars[] = {'r', 'u', 'e', '\0'};
static const char _false_chars[] = {'a', 'l', 's', 'e', '\0'};
static const char _null_chars[] = {'u', 'l', 'l', '\0'};


@implementation NXJsonParser

-(void)dealloc
{
	NXReleaseAndNil(_data);
	
	free(_stringBuffer);
	
	[super dealloc];
}

-(id)init
{
	if ((self = [super init]))
	{
		_stringBufferSize = 10 * 1024;
		_stringBuffer = (char*)malloc(_stringBufferSize * sizeof(char));
	}
	
	return self;
}


-(id)initWithData:(NSData*)data 
{
	ASSERT(data);
	ASSERT_CLASS(data, NSData);
	
	if ((self = [self init]))
	{
		_data = [data retain];
		_bytes = (char*)[data bytes];
		_current = 0;
		_length = [data length];
	}
	
	return self;
}


+ (id)parseString:(NSString *)jsonString error:(NSError **)error ignoreNulls:(BOOL)ignoreNulls
{
	return [NXJsonParser parseData:[jsonString dataUsingEncoding:NSUTF8StringEncoding] error:error ignoreNulls:ignoreNulls];
}

+ (id)parseData:(NSData*)jsonData error:(NSError **)error ignoreNulls:(BOOL)ignoreNulls
{
	NXJsonParser* parser = [[NXJsonParser alloc] initWithData:jsonData];
	id retval = [parser parse:error ignoreNulls:ignoreNulls];
	NXReleaseAndNil(parser);
	return retval;
}

+(id)parseFileAtPath:(NSString*)path error:(NSError**)error ignoreNulls:(BOOL)ignoreNulls
{
	ASSERT_CLASS(path, NSString);
	
	NSError* myError  = nil;
	NSString* string = [[NSString alloc] initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&myError];
	
	if(myError)
	{
		NXReleaseAndNil(string);
		TRACE(@"Reading JSON file failed with %@", myError);
		if (error)
		{
			*error = myError;
		}
		return nil;
	}	
	id retval = [NXJsonParser parseString:string error:error ignoreNulls:ignoreNulls];
	
	NXReleaseAndNil(string);
	
	return retval;
}

-(id)parseData:(NSData*)data error:(NSError**)error ignoreNulls:(BOOL)ignoreNulls
{
	ASSERT_CLASS(data, NSData);
	NXReleaseAndNil(_data);
	
	_data = [data retain];
	_bytes = (char*)[data bytes];
	_current = 0;
	_length = [data length];
	
	return [self parse:error ignoreNulls:ignoreNulls];
}


-(id)parse:(NSError**)error ignoreNulls:(BOOL)ignoreNulls
{
	ASSERT(_data);
	
	_ignoreNulls = ignoreNulls;
	_current = 0;
	
	id retval = nil;
	@try
	{
		retval = [self newObject];
	}
	@catch (NSException* e)
	{
		retval = nil;
		if(error)
		{
			*error = [NSError errorWithDomain:kNextiveJsonParserErrorDomain code:100 description:[e reason]];
		}
	}
	@finally
	{
		return [retval autorelease];
	}
}

-(id)newObject
{
	id retval = nil;
	
	[self skipWhitespace];
	
	if(hasData())
	{
		char c = currentChar();
		
		switch (c)
		{
			case '{':
				retval = [self newDictionary];
				break;
			case '[':
				retval = [self newArray];
				break;
			case '\"':
				retval = [self newString];
				break;
			case '0':
			case '1':
			case '2':
			case '3':
			case '4':
			case '5':
			case '6':
			case '7':
			case '8':
			case '9':
			case '-':
			case '.':
				retval = [self newNumber];
				break;
			case 't':
			case 'f':
				retval = [self newBoolean];
				break;
			case 'n':
				retval = [self newNull];
				break;
			case '\0':
				[NSException raise:kUnexpectedEndOfFileException  format:@"Unexpected EOF"];
				break;
			default:
				[NSException raise:kUnexpectedCharException  format:@"Expecting a dictionary, array, string, number, boolean, null, anything but a \"%c\"", currentChar()];
				break;
		}
	}
	
	return retval;
}

-(void)skipWhitespace
{
	BOOL intoComment = NO;
	BOOL end = NO;
	while (!end && hasData())
	{
		char c = currentChar();
		
		switch (c)
		{
			case ' ':
			case '\t':
			case '\n':
				skip();
				break;
			case '/':
				if (nextChar() == '*')
				{
					// skip both the '/' and the '*'
					skip();
					skip();
					intoComment = YES;
				}
				else
				{
					end = YES;
				}
				break;
			case '*':
				if (intoComment) 
				{
					skip(); // skip the '*'
					if(currentChar() == '/')
					{
						skip(); // skip the '/'
						intoComment = NO;
					}
				}
				else
				{
					end = YES;
				}
				break;
			default:
				if (intoComment)
				{
					skip(); 
				}
				else
				{
					end = YES;
				}
				break;
		}
	}
}

-(NSDictionary*)newDictionary
{
	ASSERT(_bytes);
	ASSERT(hasData());
	ASSERT(currentChar() == '{');
	
	skip(); // skip the '{'
	
	size_t size = 100;
	id* keys = (id*)malloc(sizeof(id) * size);
	ASSERT(keys);
	id* values = (id*)malloc(sizeof(id) * size);
	ASSERT(values);
	NSUInteger count = 0;
	
	@try
	{
		BOOL intoDictionary = YES;
		[self skipWhitespace];
		if(currentChar() == '}')
		{
			intoDictionary = NO;
		}
		
		while (intoDictionary)
		{
			[self skipWhitespace];
			
			id key = [self newObject];
			ASSERT(key);
			
			[self skipWhitespace];
			
			if(currentChar() != ':')
			{
				[NSException raise:kUnexpectedCharException  format:@"Expecting ':', found \"%c\"", currentChar()];
			}
			skip();
			
			[self skipWhitespace];
			
			id value = [self newObject];
			
			if (!(_ignoreNulls && !value))
			{
				ASSERT(value);
				
				if (count == size)
				{
					size *= 2;
					keys = (id*)realloc(keys, size * sizeof(id));
					ASSERT(keys);
					values = (id*)realloc(values, size * sizeof(id));
					ASSERT(values);
				}
				keys[count] = key;
				values[count] = value;
				count++;
			}
			
			[self skipWhitespace];
			
			char c = currentChar();
			switch (c)
			{
				case ',':
					// skip and keep going
					skip();
					break;
				case '}':
					intoDictionary = NO;
					break;
				case '\0':
					[NSException raise:kUnexpectedEndOfFileException  format:@"Unexpected EOF"];
					break;
				default:
					[NSException raise:kUnexpectedCharException  format:@"Expecting \",\" or \"}\", found \"%c\"", c];
					break;
			}
		}
		
		skip(); //skip the "}"
		
		[self skipWhitespace];
	}
	@catch (NSException * e)
	{
		for (NSUInteger i = 0; i < count; i++)
		{
			[keys[i] release];
			[values[i] release];
		}
		free(keys);
		free(values);
		
		[e raise];
	}
	@finally
	{
		
		// Creating a dictionary from arrays of keys and values is much much faster than adding them one item at a time. 
		NSDictionary* dict = (NSDictionary*)CFDictionaryCreate(kCFAllocatorDefault, (const void**) keys, (const void**) values, count, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
		
		for (NSUInteger i = 0; i < count; i++)
		{
			[keys[i] release];
			[values[i] release];
		}
		free(keys);
		free(values);
		
		return dict;
	}
}

-(NSNumber*)newBoolean
{
	ASSERT(_bytes);
	ASSERT(hasData());
	
	BOOL value = NO;
	
	const char* array = NULL;
	switch (currentChar())
	{
		case 't':
			array = _true_chars;
			value = YES;
			break;
		case 'f':
			array = _false_chars;
			value = NO;
			break;
		default:
			DIE(@"I should never be here. Fault the calling function."); 
			array = _false_chars; // We should never be here. Assign something to shut up the static analyzer.
			break;
	}
	
	ASSERT(array);
	
	skip(); // Skip the 't' or 'f' to compare a little less. Anal retentive, me? Nah.
	
	int pos = 0;
	char expected = array[pos];
	
	while (expected != '\0')
	{
		if (currentChar() != expected)
		{
			[NSException raise:kUnexpectedCharException  format:@"Invalid char in a boolean: %c", currentChar()];
		}
		else
		{
			skip();
			expected = array[++pos];
		}
	}
	
	if (value)
	{
		return (id)CFRetain(kCFBooleanTrue);
	}
	else
	{
		return (id)CFRetain(kCFBooleanFalse);
	}

}

-(NSNull*)newNull
{
	ASSERT(_bytes);
	ASSERT(hasData());
	
	skip(); // skip the 'n'
	
	int pos = 0;
	while (_null_chars[pos] != '\0')
	{
		if (currentChar() != _null_chars[pos])
		{
			[NSException raise:kUnexpectedCharException format:@"Expecting '%c' (of 'null'), found %c", _null_chars[pos], currentChar()];
		}
		else
		{
			skip();
			pos++;
		}
	}
	
	if (_ignoreNulls)
	{
		return nil;
	}
	else
	{
		return (id)CFRetain(kCFNull);
	}

}

-(NSNumber*)newNumber
{
	//NOTE: this function is a mess. But it's the only way I found to make it fast.
	ASSERT(_bytes);
	ASSERT(hasData());
	
	BOOL end = NO;
	BOOL isNegative = NO;
	BOOL hasDecimal = NO;
	BOOL hasDigits = NO;
	BOOL hasExponent = NO;
	BOOL positiveExponent = NO;
	int exponent = 0;
	
	long long integer = 0;
	long long decimal = 0;
	double divisor = 10;
	
	while(!end)
	{
		char c = currentChar();
		
		switch (c)
		{
			case '0': case '1':	case '2': case '3':	case '4':
			case '5': case '6':	case '7': case '8':	case '9':
				hasDigits = YES;
				if(hasDecimal)
				{
					decimal *= 10;
					decimal += c - '0';
					divisor *= 10;
				}
				else
				{
					integer *= 10;
					integer += c - '0';
				}
				skip();
				break;
			case '-':
				if(hasDigits)
				{
					[NSException raise:kUnexpectedCharException  format:@"- after a digit?"];
				}
				if(hasDecimal)
				{
					[NSException raise:kUnexpectedCharException  format:@"- after '.'?"];
				}
				if(isNegative)
				{
					[NSException raise:kUnexpectedCharException  format:@"Two negatives one number?"];
				}
				isNegative = YES;
				skip();
				break;
			case '.':
				if(hasDecimal)
				{
					[NSException raise:kUnexpectedCharException  format:@"Two decimal points one number?"];
				}
				hasDecimal = YES;
				skip();
				break;
			case 'e':
			case 'E':
				if (hasExponent)
				{
					[NSException raise:kUnexpectedCharException  format:@"Two exponents one number?"];
				}
				hasExponent = YES;
				skip();
				switch (currentChar())
				{
					case '+':
						positiveExponent = YES;
						break;
					case '-':
						positiveExponent = NO;
						break;
					default:
						[NSException raise:kUnexpectedCharException  format:@"e should be followed by '+' or '-', not '%c'", currentChar()];
						break;
				}
				skip();
				while (!end)
				{
					char e = currentChar();
					if (e >= '0' && e <= '9')
					{
						exponent *= 10;
						exponent += e - '0';
						skip();
					}
					else
					{
						end = YES;
					}
				}
				
				
			default:
				end = YES;
				break;
		}
	}
	
	if(!hasDigits)
	{
		[NSException raise:kUnexpectedCharException  format:@"No digits in a number?"];
	}
	
	if (hasExponent)
	{
		exponent = positiveExponent ? exponent : -exponent;
		unsigned long long mantissa = (integer * divisor / 10) + decimal;
		while (divisor > 10)
		{
			exponent --;
			divisor /= 10;
		}
		return [[NSDecimalNumber alloc] initWithMantissa:mantissa exponent:exponent isNegative:isNegative];
	}
	else
	{
		int sign = isNegative ? -1 : 1;
		if(hasDecimal)
		{
			divisor /= 10;
			return [[NSNumber alloc] initWithDouble:sign * (integer + (decimal / divisor))];
		}
		else
		{
			return [[NSNumber alloc] initWithLongLong:sign * integer];
		}
	}

}

-(NSString*)newString
{
	//NOTE: this function is a mess. But it's the only way I found to make it fast.
	
	ASSERT(_bytes);
	ASSERT(hasData());
	ASSERT(currentChar() == '\"');
	
	skip(); // skip the '"'
	
	BOOL end = NO;
	BOOL intoEscape = NO;
	
	size_t len = 0;
	
#define resizeIfNeeded(newSize) \
if(newSize >= _stringBufferSize) \
{ \
	while(newSize >= _stringBufferSize) \
	{ \
		_stringBufferSize *= 2; \
	} \
	_stringBuffer = (char*)realloc(_stringBuffer, _stringBufferSize * sizeof(char)); \
} \
	
	while(!end)
	{
		char c = currentChar();
		
		resizeIfNeeded(len);
		
		switch (c)
		{
			case '\\':
				if (intoEscape)
				{
					_stringBuffer[len++] = c;
				}
				intoEscape = !intoEscape;
				skip();
				break;
			case '\"':
				if(intoEscape)
				{
					intoEscape = NO;
					skip();
					_stringBuffer[len++] = c;
				}
				else
				{
					end = YES;
				}
				break;
			case '\0':
				[NSException raise:kUnexpectedEndOfFileException  format:@"Unexpected EOF"];
				break;
			default:
				if(intoEscape)
				{
					intoEscape = NO;
					switch (c)
					{
						case '/':
							c = '/';
							break;
						case 'b':
							c = '\b';
							break;
						case 'f':
							c = '\f';
							break;
						case 'n':
							c = '\n';
							break;
						case 'r':
							c = '\r';
							break;
						case 't':
							c = '\t';
							break;
						case 'u':
							skip();
							
							unichar uc = 0;
							for (int i = 0; i < 4; i++) 
							{
								c = currentChar();
								skip();
								
								uc *= 16;
								
								switch (c)
								{
									case '0':
									case '1':
									case '2':
									case '3':
									case '4':
									case '5':
									case '6':
									case '7':
									case '8':
									case '9':
										uc += c - '0';
										break;
									case 'a':
									case 'b':
									case 'c':
									case 'd':
									case 'e':
									case 'f':
										uc += c - 'a' + 10;
										break;
									case 'A':
									case 'B':
									case 'C':
									case 'D':
									case 'E':
									case 'F':
										uc += c - 'A' + 10;
										break;
									default:
										[NSException raise:kUnexpectedHexCharException  format:@"Unexpected hex char: '\\%c'", c];
										break;
								}
							}
							
							// Ugly code
							// The code sequence for, for example "®", is \u00ae. In UTF8 is encoded as 0xC2 0xAE.
							// There's probably a better way to do this with some bit twiddling, but I'm tired and this works for now.
							// Feel free to fix it.
							NSString* utf16 = [[NSString alloc] initWithBytes:&uc length:sizeof(uc) encoding:NSUTF16LittleEndianStringEncoding];
							char ubuffer[10] = {0}; // 10 is more than enough.
							NSUInteger size = 0;
							NSRange range = {0, 1};
							[utf16 getBytes:&ubuffer maxLength:10 usedLength:&size encoding:NSUTF8StringEncoding options:NSStringEncodingConversionAllowLossy range:range remainingRange:NULL];
							
							resizeIfNeeded(len + size);
							
							for (size_t i = 0; i < size; i++)
							{
								_stringBuffer[len++] = ubuffer[i];
							}
							NXReleaseAndNil(utf16);
							
							continue;
							
							break;
						default:
							[NSException raise:kUnexpectedControlCharException  format:@"Unexpected control char: '\\%c'", c];
							break;
					}
				}
				
				_stringBuffer[len++] = c;
				
				skip();
				break;
		}
	}

	// The great thing about using CFStrings instead of NSStrings is that (besides it's a tiny bit faster to create)
	// the [string copy] message simply retains it. As the string is immutable the effect is the same, 
	// only that is faster and in some cases it will use less memory. 
	NSString* retval = (NSString*)CFStringCreateWithBytes(kCFAllocatorDefault, (unsigned char*)_stringBuffer, len, kCFStringEncodingUTF8, false);
	
	skip(); //skip the '"'
	ASSERT(retval);
	return retval;
}

-(NSArray*)newArray
{
	ASSERT(_bytes);
	ASSERT(hasData());
	ASSERT(currentChar() == '[');
	
	size_t size = 100;
	id* values = (id*)malloc(sizeof(id) * size);
	ASSERT(values);
	NSUInteger count = 0;		
	@try
	{
		skip(); // skip the '"'
		
		BOOL intoArray = YES;
		[self skipWhitespace];
		if(currentChar() == ']')
		{
			intoArray = NO;
		}
		while (intoArray)
		{
			[self skipWhitespace];
			
			
			id value = [self newObject];
			
			if (!(_ignoreNulls && !value))
			{
				ASSERT(value);
				
				if (count == size)
				{
					size *= 2;
					values = (id*)realloc(values, size * sizeof(id));
					ASSERT(values);
				}
				values[count] = value;
				count++;
			}
			
			[self skipWhitespace];
			
			char c = currentChar();
			switch (c)
			{
				case ',':
					// skip and keep going
					skip();
					break;
				case ']':
					intoArray = NO;
					break;
				case '\0':
					[NSException raise:kUnexpectedEndOfFileException  format:@"Unexpected EOF"];
					break;
				default:
					[NSException raise:kUnexpectedCharException  format:@"Expecting ',' or ']', found '%c'", c];
					break;
			}
		}
		
		skip(); //skip the "]"
		
		[self skipWhitespace];
	}
	@catch (NSException * e)
	{
		for (NSUInteger i = 0; i < count; i++)
		{
			[values[i] release];
		}
		free(values);

		[e raise];
	}
	@finally
	{
		NSArray* array = (NSArray*)CFArrayCreate(kCFAllocatorDefault, (const void**) values, count, &kCFTypeArrayCallBacks);
		for (NSUInteger i = 0; i < count; i++)
		{
			[values[i] release];
		}
		free(values);
		
		return array;
	}
	
}


// Deprecated, replaced by the inline versions. Kept just in case we want to debug it.

//-(BOOL)hasData
//{
//	return _current < _length;
//}

//-(char)currentChar
//{
//	ASSERT(_bytes);
//	ASSERT(_current < _length);
//	return _bytes[_current];
//}

//-(char)nextChar
//{
//	ASSERT(_bytes);
//	ASSERT(_current + 1 < _length);
//	return _bytes[_current + 1];
//}

@end
