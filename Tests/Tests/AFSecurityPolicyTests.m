// AFSecurityPolicyTests.m
//
// Copyright (c) 2013 AFNetworking (http://afnetworking.com)
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

#import "AFTestCase.h"

#import "AFSecurityPolicy.h"

@interface AFSecurityPolicyTests : AFTestCase
@end

static SecTrustRef AFUTTrustChainForCertsInDirectory(NSString *directoryPath) {
    NSArray *certFileNames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directoryPath error:nil];
    NSMutableArray *certs  = [NSMutableArray arrayWithCapacity:[certFileNames count]];
    for (NSString *path in certFileNames) {
        NSData *certData = [NSData dataWithContentsOfFile:[directoryPath stringByAppendingPathComponent:path]];
        SecCertificateRef cert = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)(certData));
        [certs addObject:(__bridge id)(cert)];
    }

    SecPolicyRef policy = SecPolicyCreateBasicX509();
    SecTrustRef trust = NULL;
    SecTrustCreateWithCertificates((__bridge CFTypeRef)(certs), policy, &trust);
    CFRelease(policy);

    return trust;
}

static SecTrustRef AFUTHTTPBinOrgServerTrust() {
    NSString *bundlePath = [[NSBundle bundleForClass:[AFSecurityPolicyTests class]] resourcePath];
    NSString *serverCertDirectoryPath = [bundlePath stringByAppendingPathComponent:@"HTTPBinOrgServerTrustChain"];

    return AFUTTrustChainForCertsInDirectory(serverCertDirectoryPath);
}

static SecTrustRef AFUTADNNetServerTrust() {
    NSString *bundlePath = [[NSBundle bundleForClass:[AFSecurityPolicyTests class]] resourcePath];
    NSString *serverCertDirectoryPath = [bundlePath stringByAppendingPathComponent:@"ADNNetServerTrustChain"];

    return AFUTTrustChainForCertsInDirectory(serverCertDirectoryPath);
}

static SecCertificateRef AFUTHTTPBinOrgCertificate() {
    NSString *certPath = [[NSBundle bundleForClass:[AFSecurityPolicyTests class]] pathForResource:@"httpbinorg_10242013" ofType:@"cer"];
    NSCAssert(certPath != nil, @"Path for certificate should not be nil");
    NSData *certData = [NSData dataWithContentsOfFile:certPath];

    return SecCertificateCreateWithData(NULL, (__bridge CFDataRef)(certData));
}

#pragma mark -

@implementation AFSecurityPolicyTests

- (void)testPublicKeyPinningIsEnforcedForHTTPBinOrgPinnedCertificateAgainstHTTPBinOrgServerTrust {
    AFSecurityPolicy *policy = [[AFSecurityPolicy alloc] init];
    SecCertificateRef certificate = AFUTHTTPBinOrgCertificate();
    [policy setPinnedCertificates:@[(__bridge_transfer NSData *)SecCertificateCopyData(certificate)]];
    CFRelease(certificate);
    [policy setSSLPinningMode:AFSSLPinningModePublicKey];

    SecTrustRef trust = AFUTHTTPBinOrgServerTrust();
    XCTAssert([policy evaluateServerTrust:trust], @"HTTPBin.org Public Key Pinning Mode Failed");
    CFRelease(trust);
}

- (void)testCertificatePinningIsEnforcedForHTTPBinOrgPinnedCertificateAgainstHTTPBinOrgServerTrust {
    AFSecurityPolicy *policy = [[AFSecurityPolicy alloc] init];
    SecCertificateRef certificate = AFUTHTTPBinOrgCertificate();
    [policy setPinnedCertificates:@[(__bridge_transfer NSData *)SecCertificateCopyData(certificate)]];
    CFRelease(certificate);
    [policy setSSLPinningMode:AFSSLPinningModeCertificate];

    SecTrustRef trust = AFUTHTTPBinOrgServerTrust();
    XCTAssert([policy evaluateServerTrust:trust], @"HTTPBin.org Public Key Pinning Mode Failed");
    CFRelease(trust);
}

- (void)testNoPinningIsEnforcedForHTTPBinOrgPinnedCertificateAgainstHTTPBinOrgServerTrust {
    AFSecurityPolicy *policy = [[AFSecurityPolicy alloc] init];
    SecCertificateRef certificate = AFUTHTTPBinOrgCertificate();
    [policy setPinnedCertificates:@[(__bridge_transfer NSData *)SecCertificateCopyData(certificate)]];
    CFRelease(certificate);
    [policy setSSLPinningMode:AFSSLPinningModeNone];

    SecTrustRef trust = AFUTHTTPBinOrgServerTrust();
    XCTAssert([policy evaluateServerTrust:trust], @"HTTPBin.org Pinning should not have been enforced");
    CFRelease(trust);
}

- (void)testPublicKeyPinningFailsForHTTPBinOrgIfNoCertificateIsPinned {
    AFSecurityPolicy *policy = [[AFSecurityPolicy alloc] init];
    [policy setPinnedCertificates:@[]];
    [policy setSSLPinningMode:AFSSLPinningModePublicKey];

    SecTrustRef trust = AFUTHTTPBinOrgServerTrust();
    XCTAssert([policy evaluateServerTrust:trust] == NO, @"HTTPBin.org Public Key Pinning Should have failed with no pinned certificate");
    CFRelease(trust);
}

- (void)testCertificatePinningFailsForHTTPBinOrgIfNoCertificateIsPinned {
    AFSecurityPolicy *policy = [[AFSecurityPolicy alloc] init];
    [policy setPinnedCertificates:@[]];
    [policy setSSLPinningMode:AFSSLPinningModeCertificate];

    SecTrustRef trust = AFUTHTTPBinOrgServerTrust();
    XCTAssert([policy evaluateServerTrust:trust] == NO, @"HTTPBin.org Certificate Pinning Should have failed with no pinned certificate");
    CFRelease(trust);
}

- (void)testNoPinningIsEnforcedForHTTPBinOrgIfNoCertificateIsPinned {
    AFSecurityPolicy *policy = [[AFSecurityPolicy alloc] init];
    [policy setPinnedCertificates:@[]];
    [policy setSSLPinningMode:AFSSLPinningModeNone];

    SecTrustRef trust = AFUTHTTPBinOrgServerTrust();
    XCTAssert([policy evaluateServerTrust:trust], @"HTTPBin.org Pinning should not have been enforced");
    CFRelease(trust);
}

- (void)testPublicKeyPinningForHTTPBinOrgFailsWhenPinnedAgainstADNServerTrust {
    AFSecurityPolicy *policy = [[AFSecurityPolicy alloc] init];
    [policy setPinnedCertificates:@[]];
    [policy setSSLPinningMode:AFSSLPinningModePublicKey];

    SecTrustRef trust = AFUTADNNetServerTrust();
    XCTAssert([policy evaluateServerTrust:trust] == NO, @"HTTPBin.org Public Key Pinning Should have failed against ADN");
    CFRelease(trust);
}

- (void)testCertificatePinningForHTTPBinOrgFailsWhenPinnedAgainstADNServerTrust {
    AFSecurityPolicy *policy = [[AFSecurityPolicy alloc] init];
    [policy setPinnedCertificates:@[]];
    [policy setSSLPinningMode:AFSSLPinningModeCertificate];

    SecTrustRef trust = AFUTADNNetServerTrust();
    XCTAssert([policy evaluateServerTrust:trust] == NO, @"HTTPBin.org Certificate Pinning Should have failed against ADN");
    CFRelease(trust);
}

- (void)testDefaultPolicyContainsHTTPBinOrgCertificate {
    AFSecurityPolicy *policy = [AFSecurityPolicy defaultPolicy];
    SecCertificateRef cert = AFUTHTTPBinOrgCertificate();
    NSData *certData = (__bridge NSData *)(SecCertificateCopyData(cert));
    CFRelease(cert);
    NSInteger index = [policy.pinnedCertificates indexOfObjectPassingTest:^BOOL(NSData *data, NSUInteger idx, BOOL *stop) {
        return [data isEqualToData:certData];
    }];

    XCTAssert(index!=NSNotFound, @"HTTPBin.org certificate not found in the default certificates");
}

- (void)testDefaultPolicyIsSetToAFSSLPinningModePublicKey {
    AFSecurityPolicy *policy = [AFSecurityPolicy defaultPolicy];

    XCTAssert(policy.SSLPinningMode==AFSSLPinningModeNone, @"Default policy is not set to AFSSLPinningModePublicKey.");
}

- (void)testDefaultPolicyIsSetToNotAllowInvalidSSLCertificates {
    AFSecurityPolicy *policy = [AFSecurityPolicy defaultPolicy];

    XCTAssert(policy.allowInvalidCertificates == NO, @"Default policy should not allow invalid ssl certificates");
}

- (void)testPolicyWithPinningModeIsSetToNotAllowInvalidSSLCertificates {
    AFSecurityPolicy *policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
    
    XCTAssert(policy.allowInvalidCertificates == NO, @"policyWithPinningMode: should not allow invalid ssl certificates by default.");
}

- (void)testThatSSLPinningPolicyClassMethodContainsDefaultCertificates{
    AFSecurityPolicy *policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModePublicKey];
    XCTAssertNotNil(policy.pinnedCertificates, @"Default certificate array should not be empty for SSL pinning mode policy");
}

- (void)testThatDefaultPinningPolicyClassMethodContainsNoDefaultCertificates{
    AFSecurityPolicy *policy = [AFSecurityPolicy defaultPolicy];
    XCTAssertNil(policy.pinnedCertificates, @"Default certificate array should be empty for default policy.");
}

@end
