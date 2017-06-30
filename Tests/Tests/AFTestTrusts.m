// AFTestTrusts.m
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

#import "AFTestTrusts.h"

#import "AFTestCertificates.h"

SecTrustRef AFTrustRefWithCertificates(SecCertificateRef firstCert, ...)
{
    SecPolicyRef policy = SecPolicyCreateBasicX509();
    
    va_list certs;
    va_start(certs, firstCert);
    
    CFMutableArrayRef certArray = CFArrayCreateMutable(kCFAllocatorDefault,
                                                       0,
                                                       &kCFTypeArrayCallBacks);
    
    for (SecCertificateRef cert = firstCert;
         cert != NULL;
         cert = va_arg(certs, SecCertificateRef)) {
        CFArrayAppendValue(certArray, cert);
    }
    
    SecTrustRef trust;
    OSStatus status = SecTrustCreateWithCertificates(certArray,
                                                     policy,
                                                     &trust);
    
    assert(status == errSecSuccess);
    
    CFRelease(certArray);
    
    return trust;
}

@implementation AFTestTrusts

+ (SecTrustRef)leafWildcard {
    return AFTrustRefWithCertificates([AFTestCertificates leafWildcard],
                                      [AFTestCertificates intermediateCA1],
                                      [AFTestCertificates rootCA],
                                      NULL);
}

+ (SecTrustRef)leafMultipleDNSNames {
    return AFTrustRefWithCertificates([AFTestCertificates leafMultipleDNSNames],
                                      [AFTestCertificates intermediateCA1],
                                      [AFTestCertificates rootCA],
                                      NULL);
}

+ (SecTrustRef)leafSignedByCA1 {
    return AFTrustRefWithCertificates([AFTestCertificates leafSignedByCA1],
                                      [AFTestCertificates intermediateCA1],
                                      [AFTestCertificates rootCA],
                                      NULL);
}

+ (SecTrustRef)leafDNSNameAndURI {
    return AFTrustRefWithCertificates([AFTestCertificates leafDNSNameAndURI],
                                      [AFTestCertificates intermediateCA1],
                                      [AFTestCertificates rootCA],
                                      NULL);
}

+ (SecTrustRef)leafExpired {
    return AFTrustRefWithCertificates([AFTestCertificates leafExpired],
                                      [AFTestCertificates intermediateCA2],
                                      [AFTestCertificates rootCA],
                                      NULL);
}

+ (SecTrustRef)leafMissingDNSNameAndURI {
    return AFTrustRefWithCertificates([AFTestCertificates leafMissingDNSNameAndURI],
                                      [AFTestCertificates intermediateCA2],
                                      [AFTestCertificates rootCA],
                                      NULL);
}

+ (SecTrustRef)leafSignedByCA2 {
    return AFTrustRefWithCertificates([AFTestCertificates leafSignedByCA2],
                                      [AFTestCertificates intermediateCA2],
                                      [AFTestCertificates rootCA],
                                      NULL);
}

+ (SecTrustRef)leafValidDNSName {
    return AFTrustRefWithCertificates([AFTestCertificates leafValidDNSName],
                                      [AFTestCertificates intermediateCA2],
                                      [AFTestCertificates rootCA],
                                      NULL);
}

+ (SecTrustRef)leafValidURI {
    return AFTrustRefWithCertificates([AFTestCertificates leafValidURI],
                                      [AFTestCertificates intermediateCA2],
                                      [AFTestCertificates rootCA],
                                      NULL);
}

+ (SecTrustRef)leafValidDNSNameMissingIntermediate {
    return AFTrustRefWithCertificates([AFTestCertificates leafValidDNSName],
                                      [AFTestCertificates rootCA],
                                      NULL);
}

+ (SecTrustRef)leafValidDNSNameWithIncorrectIntermediate {
    return AFTrustRefWithCertificates([AFTestCertificates leafValidDNSName],
                                      [AFTestCertificates intermediateCA1],
                                      [AFTestCertificates rootCA],
                                      NULL);
}

@end
