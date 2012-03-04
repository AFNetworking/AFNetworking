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

/**
 
 Serializes an object structure to Json, according to the spec in http://www.json.org/
 
 Supports NSDictionary, NSArray, NSString, NSNumber, NSNull and its subclasses.
 If you implement the NXSerializable protocol, just serialize yourself to a dictionary 
 (or array, or any JSON compatible type) and we'll do our best.
 
 @warning *Important*: Do NOT try to serialize a recursive structure.
 
 */
@interface NXJsonSerializer : NSObject  
{
@private
	// We keep references to [XX class] here for performance reasons. Yes. Really. Calling
	// [XX class] thousands of times is expensive.
	Class _nullClass;
	Class _dictClass;
	Class _arraClass;
	Class _numbClass;
	Class _striClass;

	Class _nullClassCached;
	Class _dictClassCached;
	Class _arraClassCached;
	Class _numbClassCached;
	Class _striClassCached;
	
	char* _buffer;
	size_t _length;
	size_t _current;
	
	UniChar* _stringBuffer;
	CFIndex _stringBufferLength;
}
/**
 Serializes the specified object, such as NSDictionary, NSNumber, NSString, NSArray, NSNull 
 @param object the object to serialize
 @return Returns a serialized object
 */
+(NSString*)serialize:(id)object;
/**
 Serializes the specified object, such as NSDictionary, NSNumber, NSString, NSArray, NSNull 
 @param object the object to serialize
 @return Returns a serialized object
 */
-(NSString*)serialize:(id)object;
/**
 Serializes the object and writes serialized object's contents to a specific file.
 @param object The object to serialize
 @param path The destination path of the serialized data's newly created file 
 @return Returns YES on success, NO on error.
 */
+(BOOL)serialize:(id)object toFile:(NSString*)path error:(NSError**)error;

@end
