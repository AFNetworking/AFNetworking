// AFTestCertificates.h
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

@interface AFTestCertificates : NSObject

// Root Certificate
@property (class, nonatomic, readonly) SecCertificateRef rootCA;

// Intermediate Certificates
@property (class, nonatomic, readonly) SecCertificateRef intermediateCA1;
@property (class, nonatomic, readonly) SecCertificateRef intermediateCA2;

// Leaf Certificates - Signed by CA1
@property (class, nonatomic, readonly) SecCertificateRef leafWildcard;
@property (class, nonatomic, readonly) SecCertificateRef leafMultipleDNSNames;
@property (class, nonatomic, readonly) SecCertificateRef leafSignedByCA1;
@property (class, nonatomic, readonly) SecCertificateRef leafDNSNameAndURI;

// Leaf Certificates - Signed by CA2
@property (class, nonatomic, readonly) SecCertificateRef leafExpired;
@property (class, nonatomic, readonly) SecCertificateRef leafMissingDNSNameAndURI;
@property (class, nonatomic, readonly) SecCertificateRef leafSignedByCA2;
@property (class, nonatomic, readonly) SecCertificateRef leafValidDNSName;
@property (class, nonatomic, readonly) SecCertificateRef leafValidURI;

@end

NS_ASSUME_NONNULL_END
