// AFTestTrusts.h
// Copyright (c) 2011–2016 Alamofire Software Foundation ( http://alamofire.org/ )
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

NS_ASSUME_NONNULL_BEGIN

SecTrustRef AFTrustRefWithCertificates(SecCertificateRef firstCert, ...) NS_RETURNS_RETAINED;

@interface AFTestTrusts : NSObject

// Leaf Trusts - Signed by CA1
+ (SecTrustRef)leafWildcard;
+ (SecTrustRef)leafMultipleDNSNames;
+ (SecTrustRef)leafSignedByCA1;
+ (SecTrustRef)leafDNSNameAndURI;

// Leaf Trusts - Signed by CA2
+ (SecTrustRef)leafExpired;
+ (SecTrustRef)leafMissingDNSNameAndURI;
+ (SecTrustRef)leafSignedByCA2;
+ (SecTrustRef)leafValidDNSName;
+ (SecTrustRef)leafValidURI;

// Invalid Trusts
+ (SecTrustRef)leafValidDNSNameMissingIntermediate;
+ (SecTrustRef)leafValidDNSNameWithIncorrectIntermediate;

@end

NS_ASSUME_NONNULL_END
