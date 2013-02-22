// AFXMLRequestOperation.h
//
// Copyright (c) 2013 Gowalla (http://gowalla.com/)
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

// This file is for AFNetworking's use only, and should never be included by
// code using AFNetworking.
//
// To disable a warning, use one of these PUSH_ macros. Each use of PUSH_ macro
// should be balanced with a POP_WARNINGS macro.

#define PUSH_WARNINGS _Pragma("clang diagnostic push")

#define PUSH_NO_FLOAT_EQUAL_WARNING PUSH_WARNINGS \
_Pragma("clang diagnostic ignored \"-Wfloat-equal\"")

#define PUSH_NO_COVERED_SWITCH_DEFAULT_WARNING PUSH_WARNINGS \
_Pragma("clang diagnostic ignored \"-Wcovered-switch-default\"")

#define PUSH_NO_ARC_RETAIN_CYCLES_WARNING PUSH_WARNINGS \
_Pragma("clang diagnostic ignored \"-Warc-retain-cycles\"")

#define POP_WARNINGS _Pragma("clang diagnostic pop")
