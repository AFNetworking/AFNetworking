//
//  AFPreProcessorMacros.h
//
//  Copyright (c) 2012 Labgoo LTD. All rights reserved.
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
/**
 * A helper macro to keep the interfaces compatiable with pre ARC compilers.
 * Useful when you put nimbus in a library and link it to a GCC LLVM compiler.
 */

#if defined(__has_feature) && __has_feature(objc_arc_weak)
    #define AF_WEAK weak
    #define AF_STRONG strong
#elif defined(__has_feature)  && __has_feature(objc_arc)
    #define AF_WEAK __unsafe_unretained
    #define AF_STRONG retain
#else
    #define AF_WEAK assign
    #define AF_STRONG retain
#endif
