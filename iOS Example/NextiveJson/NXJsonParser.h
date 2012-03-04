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


#import <Foundation/Foundation.h>
#import "NXDebug.h"

/// The error domain for all errors of this class.
extern NSString* const kNextiveJsonParserErrorDomain;


/*
 
 TODO: 
 - Optimize the unicode escape sequence code ("\u00ae"). It works but it's slow. And ugly. And kicks puppies.

 */
/**
 
 Implements a fast JSON parser according to the spec in http://www.json.org/
 Also has support for C style comments.
 
 *Note:* null values are represented as `NSNull` objects instead of nil unless ignoreNulls is YES. In that case
 nil values are not added to dictionaries or arrays; if the JSON string is "null", nil is returned.
 
 @warning *Important:* a malformed JSON might wrek havoc. 
 
 */
@interface NXJsonParser : NSObject 
{
@private
	NSData* _data;
	char* _bytes;
	size_t _current;
	size_t _length;
	
	// I keep a buffer for strings to avoid creating it and tearing it down every time.
	char* _stringBuffer;
	size_t _stringBufferSize;
	
	BOOL _ignoreNulls;
}

/**
 Encodes the jsonString to data and calls [NXJsonParser parseData:error:ignoreNulls:]
 @param jsonString The string to parse
 @param error The parsing error
 @param ignoreNulls If YES null values will be ignored in the parsing process
 @return Returns the parsed data
 */
+(id)parseString:(NSString*)jsonString error:(NSError**)error ignoreNulls:(BOOL)ignoreNulls;
/**
 Parse the provided data.
 
 @param jsonData The data to parse
 @param error The parsing error
 @param ignoreNulls If YES null values will be ignored in the parsing process
 @return Returns the parsed data
 
 */
+(id)parseData:(NSData*)jsonData error:(NSError**)error ignoreNulls:(BOOL)ignoreNulls;
/**
 Used to parse a specific file. Calls [NXJsonParser parseData:error:ignoreNulls:] with the given path for the file
 @param path The file's path to parse
 @param error The parsing error
 @param ignoreNulls If YES null values will be ignored in the parsing process
 @return Returns the parsed file
 */
+(id)parseFileAtPath:(NSString*)path error:(NSError**)error ignoreNulls:(BOOL)ignoreNulls;

/** 
 Initializes a new data object
 @return Returns the initialized data object
 */
-(id)init;

/** 
 Initializes a new data object
 @param data The data to parse
 @return Returns the initialized data object
 */
-(id)initWithData:(NSData*)data NOTNULL(1);

/**
 Parse the provided data.
 
 @param jsonData The data to parse
 @param error The parsing error
 @param ignoreNulls If YES null values will be ignored in the parsing process
 @return Returns the parsed data
 
 */
-(id)parseData:(NSData*)data error:(NSError**)error ignoreNulls:(BOOL)ignoreNulls NOTNULL(1);

/**
 Parsing of passed data occurs here (assuming initWithData was called)
 @param error The parsing error
 @param ignoreNulls If YES null values will be ignored in the parsing process
 @return Returns the parsed data
 */
-(id)parse:(NSError**)error ignoreNulls:(BOOL)ignoreNulls;

@end
