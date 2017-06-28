// AFTestCertificates.m
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

#import "AFTestCertificates.h"

@interface AFTestCertificates ()

+ (SecCertificateRef)certificateWithFileName:(NSString *)fileName;

@end

@implementation AFTestCertificates

+ (SecCertificateRef)certificateWithFileName:(NSString *)fileName {
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *path = [bundle pathForResource:fileName
                                      ofType:@"cer"];
    
    NSAssert(path != nil, @"Could not find certificate for filename.");
    
    NSData *data = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:path]];
    
    NSAssert(data != nil, @"Could not load data.");
    
    SecCertificateRef cert = SecCertificateCreateWithData(NULL,
                                                          (__bridge CFDataRef)data);
    
    NSAssert(cert != NULL, @"Could not create certificate with data.");
    
    return cert;
}

#pragma mark - Root Certificate

+ (SecCertificateRef)rootCA {
    return [self certificateWithFileName:@"alamofire-root-ca"];
}

#pragma mark - Intermediate Certificates

+ (SecCertificateRef)intermediateCA1 {
    return [self certificateWithFileName:@"alamofire-signing-ca1"];
}

+ (SecCertificateRef)intermediateCA2 {
    return [self certificateWithFileName:@"alamofire-signing-ca2"];
}

#pragma mark - Leaf Certificates - Signed by CA1

+ (SecCertificateRef)leafWildcard {
    return [self certificateWithFileName:@"wildcard.alamofire.org"];
}

+ (SecCertificateRef)leafMultipleDNSNames {
    return [self certificateWithFileName:@"multiple-dns-names"];
}

+ (SecCertificateRef)leafSignedByCA1 {
    return [self certificateWithFileName:@"signed-by-ca1"];
}

+ (SecCertificateRef)leafDNSNameAndURI {
    return [self certificateWithFileName:@"test.alamofire.org"];
}

#pragma mark - Leaf Certificates - Signed by CA2

+ (SecCertificateRef)leafExpired {
    return [self certificateWithFileName:@"expired"];
}

+ (SecCertificateRef)leafMissingDNSNameAndURI {
    return [self certificateWithFileName:@"missing-dns-name-and-uri"];
}

+ (SecCertificateRef)leafSignedByCA2 {
    return [self certificateWithFileName:@"signed-by-ca2"];
}

+ (SecCertificateRef)leafValidDNSName {
    return [self certificateWithFileName:@"valid-dns-name"];
}

+ (SecCertificateRef)leafValidURI {
    return [self certificateWithFileName:@"valid-uri"];
}

@end
