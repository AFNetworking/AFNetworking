// AFSecurityPolicyTests.m
//
// Copyright (c) 2013-2014 AFNetworking (http://afnetworking.com)
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
    NSString *certPath = [[NSBundle bundleForClass:[AFSecurityPolicyTests class]] pathForResource:@"httpbinorg_11212014" ofType:@"cer"];
    NSCAssert(certPath != nil, @"Path for certificate should not be nil");
    NSData *certData = [NSData dataWithContentsOfFile:certPath];

    return SecCertificateCreateWithData(NULL, (__bridge CFDataRef)(certData));
}

static SecCertificateRef AFUTGeotrustRootCertificate() {
    NSString *certPath = [[NSBundle bundleForClass:[AFSecurityPolicyTests class]] pathForResource:@"Geotrust_Root_CA" ofType:@"cer"];
    NSCAssert(certPath != nil, @"Path for certificate should not be nil");
    NSData *certData = [NSData dataWithContentsOfFile:certPath];
    
    return SecCertificateCreateWithData(NULL, (__bridge CFDataRef)(certData));
}

static SecCertificateRef AFUTRapidSSLCertificate() {
    NSString *certPath = [[NSBundle bundleForClass:[AFSecurityPolicyTests class]] pathForResource:@"Rapid_SSL_CA" ofType:@"cer"];
    NSCAssert(certPath != nil, @"Path for certificate should not be nil");
    NSData *certData = [NSData dataWithContentsOfFile:certPath];
    
    return SecCertificateCreateWithData(NULL, (__bridge CFDataRef)(certData));
}

static SecCertificateRef AFUTSelfSignedCertificateWithoutDomain() {
    NSString *certPath = [[NSBundle bundleForClass:[AFSecurityPolicyTests class]] pathForResource:@"NoDomains" ofType:@"cer"];
    NSCAssert(certPath != nil, @"Path for certificate should not be nil");
    NSData *certData = [NSData dataWithContentsOfFile:certPath];

    return SecCertificateCreateWithData(NULL, (__bridge CFDataRef)(certData));
}

static SecCertificateRef AFUTSelfSignedCertificateWithCommonNameDomain() {
    NSString *certPath = [[NSBundle bundleForClass:[AFSecurityPolicyTests class]] pathForResource:@"foobar.com" ofType:@"cer"];
    NSCAssert(certPath != nil, @"Path for certificate should not be nil");
    NSData *certData = [NSData dataWithContentsOfFile:certPath];

    return SecCertificateCreateWithData(NULL, (__bridge CFDataRef)(certData));
}

static SecCertificateRef AFUTSelfSignedCertificateWithDNSNameDomain() {
    NSString *certPath = [[NSBundle bundleForClass:[AFSecurityPolicyTests class]] pathForResource:@"AltName" ofType:@"cer"];
    NSCAssert(certPath != nil, @"Path for certificate should not be nil");
    NSData *certData = [NSData dataWithContentsOfFile:certPath];

    return SecCertificateCreateWithData(NULL, (__bridge CFDataRef)(certData));
}

static NSArray * AFCertificateTrustChainForServerTrust(SecTrustRef serverTrust) {
    CFIndex certificateCount = SecTrustGetCertificateCount(serverTrust);
    NSMutableArray *trustChain = [NSMutableArray arrayWithCapacity:(NSUInteger)certificateCount];
    
    for (CFIndex i = 0; i < certificateCount; i++) {
        SecCertificateRef certificate = SecTrustGetCertificateAtIndex(serverTrust, i);
        [trustChain addObject:(__bridge_transfer NSData *)SecCertificateCopyData(certificate)];
    }
    
    return [NSArray arrayWithArray:trustChain];
}

static SecTrustRef AFUTTrustWithCertificate(SecCertificateRef certificate) {
    NSArray *certs  = [NSArray arrayWithObject:(__bridge id)(certificate)];

    SecPolicyRef policy = SecPolicyCreateBasicX509();
    SecTrustRef trust = NULL;
    SecTrustCreateWithCertificates((__bridge CFTypeRef)(certs), policy, &trust);
    CFRelease(policy);

    return trust;
}

#pragma mark -

@implementation AFSecurityPolicyTests

- (void)testLeafPublicKeyPinningIsEnforcedForHTTPBinOrgPinnedCertificateAgainstHTTPBinOrgServerTrust {
    AFSecurityPolicy *policy = [[AFSecurityPolicy alloc] init];
    
    SecCertificateRef geotrustRootCertificate = AFUTGeotrustRootCertificate();
    SecCertificateRef rapidSSLCertificate = AFUTRapidSSLCertificate();
    SecCertificateRef httpBinCertificate = AFUTHTTPBinOrgCertificate();
    
    [policy setPinnedCertificates:@[(__bridge_transfer NSData *)SecCertificateCopyData(geotrustRootCertificate),
                                    (__bridge_transfer NSData *)SecCertificateCopyData(rapidSSLCertificate),
                                    (__bridge_transfer NSData *)SecCertificateCopyData(httpBinCertificate)]];
    
    CFRelease(geotrustRootCertificate);
    CFRelease(rapidSSLCertificate);
    CFRelease(httpBinCertificate);
    
    [policy setSSLPinningMode:AFSSLPinningModePublicKey];
    [policy setValidatesCertificateChain:NO];
    
    SecTrustRef trust = AFUTHTTPBinOrgServerTrust();
    XCTAssert([policy evaluateServerTrust:trust forDomain:nil], @"HTTPBin.org Public Key Pinning Mode Failed");
    CFRelease(trust);
}

- (void)testPublicKeyChainPinningIsEnforcedForHTTPBinOrgPinnedCertificateAgainstHTTPBinOrgServerTrust {
    AFSecurityPolicy *policy = [[AFSecurityPolicy alloc] init];
    SecTrustRef clientTrust = AFUTHTTPBinOrgServerTrust();
    NSArray * certificates = AFCertificateTrustChainForServerTrust(clientTrust);
    CFRelease(clientTrust);
    [policy setPinnedCertificates:certificates];
    [policy setSSLPinningMode:AFSSLPinningModePublicKey];

    SecTrustRef trust = AFUTHTTPBinOrgServerTrust();
    XCTAssert([policy evaluateServerTrust:trust forDomain:@"httpbin.org"], @"HTTPBin.org Public Key Pinning Mode Failed");
    CFRelease(trust);
}

- (void)testLeafCertificatePinningIsEnforcedForHTTPBinOrgPinnedCertificateAgainstHTTPBinOrgServerTrust {
    AFSecurityPolicy *policy = [[AFSecurityPolicy alloc] init];
    
    SecCertificateRef geotrustRootCertificate = AFUTGeotrustRootCertificate();
    SecCertificateRef rapidSSLCertificate = AFUTRapidSSLCertificate();
    SecCertificateRef httpBinCertificate = AFUTHTTPBinOrgCertificate();
    
    [policy setPinnedCertificates:@[(__bridge_transfer NSData *)SecCertificateCopyData(geotrustRootCertificate),
                                    (__bridge_transfer NSData *)SecCertificateCopyData(rapidSSLCertificate),
                                    (__bridge_transfer NSData *)SecCertificateCopyData(httpBinCertificate)]];
    
    CFRelease(geotrustRootCertificate);
    CFRelease(rapidSSLCertificate);
    CFRelease(httpBinCertificate);
    
    [policy setSSLPinningMode:AFSSLPinningModeCertificate];
    [policy setValidatesCertificateChain:NO];
    
    SecTrustRef trust = AFUTHTTPBinOrgServerTrust();
    XCTAssert([policy evaluateServerTrust:trust forDomain:nil], @"HTTPBin.org Public Key Pinning Mode Failed");
    CFRelease(trust);
}

- (void)testCertificateChainPinningIsEnforcedForHTTPBinOrgPinnedCertificateAgainstHTTPBinOrgServerTrust {
    AFSecurityPolicy *policy = [[AFSecurityPolicy alloc] init];
    SecTrustRef clientTrust = AFUTHTTPBinOrgServerTrust();
    NSArray * certificates = AFCertificateTrustChainForServerTrust(clientTrust);
    CFRelease(clientTrust);
    [policy setPinnedCertificates:certificates];
    [policy setSSLPinningMode:AFSSLPinningModeCertificate];

    SecTrustRef trust = AFUTHTTPBinOrgServerTrust();
    XCTAssert([policy evaluateServerTrust:trust forDomain:@"httpbin.org"], @"HTTPBin.org Public Key Pinning Mode Failed");
    CFRelease(trust);
}

- (void)testNoPinningIsEnforcedForHTTPBinOrgPinnedCertificateAgainstHTTPBinOrgServerTrust {
    AFSecurityPolicy *policy = [[AFSecurityPolicy alloc] init];
    SecCertificateRef certificate = AFUTHTTPBinOrgCertificate();
    [policy setPinnedCertificates:@[(__bridge_transfer NSData *)SecCertificateCopyData(certificate)]];
    CFRelease(certificate);
    [policy setSSLPinningMode:AFSSLPinningModeNone];
    [policy setAllowInvalidCertificates:YES];

    SecTrustRef trust = AFUTHTTPBinOrgServerTrust();
    XCTAssert([policy evaluateServerTrust:trust forDomain:@"httpbin.org"], @"HTTPBin.org Pinning should not have been enforced");
    CFRelease(trust);
}

- (void)testPublicKeyPinningFailsForHTTPBinOrgIfNoCertificateIsPinned {
    AFSecurityPolicy *policy = [[AFSecurityPolicy alloc] init];
    [policy setSSLPinningMode:AFSSLPinningModePublicKey];
    [policy setPinnedCertificates:@[]];

    SecTrustRef trust = AFUTHTTPBinOrgServerTrust();
    XCTAssert([policy evaluateServerTrust:trust forDomain:@"httpbin.org"] == NO, @"HTTPBin.org Public Key Pinning Should have failed with no pinned certificate");
    CFRelease(trust);
}

- (void)testCertificatePinningIsEnforcedForHTTPBinOrgPinnedCertificateWithDomainNameValidationAgainstHTTPBinOrgServerTrust {
    AFSecurityPolicy *policy = [[AFSecurityPolicy alloc] init];
    
    SecCertificateRef geotrustRootCertificate = AFUTGeotrustRootCertificate();
    SecCertificateRef rapidSSLCertificate = AFUTRapidSSLCertificate();
    SecCertificateRef httpBinCertificate = AFUTHTTPBinOrgCertificate();
    
    [policy setPinnedCertificates:@[(__bridge_transfer NSData *)SecCertificateCopyData(geotrustRootCertificate),
                                    (__bridge_transfer NSData *)SecCertificateCopyData(rapidSSLCertificate),
                                    (__bridge_transfer NSData *)SecCertificateCopyData(httpBinCertificate)]];
    
    CFRelease(geotrustRootCertificate);
    CFRelease(rapidSSLCertificate);
    CFRelease(httpBinCertificate);
    
    policy.validatesDomainName = YES;
    [policy setSSLPinningMode:AFSSLPinningModeCertificate];
    
    SecTrustRef trust = AFUTHTTPBinOrgServerTrust();
    XCTAssert([policy evaluateServerTrust:trust forDomain:@"httpbin.org"], @"HTTPBin.org Public Key Pinning Mode Failed");
    CFRelease(trust);
}

- (void)testCertificatePinningIsEnforcedForHTTPBinOrgPinnedCertificateWithCaseInsensitiveDomainNameValidationAgainstHTTPBinOrgServerTrust {
    AFSecurityPolicy *policy = [[AFSecurityPolicy alloc] init];
    
    SecCertificateRef geotrustRootCertificate = AFUTGeotrustRootCertificate();
    SecCertificateRef rapidSSLCertificate = AFUTRapidSSLCertificate();
    SecCertificateRef httpBinCertificate = AFUTHTTPBinOrgCertificate();
    
    [policy setPinnedCertificates:@[(__bridge_transfer NSData *)SecCertificateCopyData(geotrustRootCertificate),
                                    (__bridge_transfer NSData *)SecCertificateCopyData(rapidSSLCertificate),
                                    (__bridge_transfer NSData *)SecCertificateCopyData(httpBinCertificate)]];
    
    CFRelease(geotrustRootCertificate);
    CFRelease(rapidSSLCertificate);
    CFRelease(httpBinCertificate);
    
    policy.validatesDomainName = YES;
    [policy setSSLPinningMode:AFSSLPinningModePublicKey];
    
    SecTrustRef trust = AFUTHTTPBinOrgServerTrust();
    XCTAssert([policy evaluateServerTrust:trust forDomain:@"httpbin.org"], @"HTTPBin.org Public Key Pinning Mode Failed");
    CFRelease(trust);
}

- (void)testCertificatePinningIsEnforcedForHTTPBinOrgPinnedPublicKeyWithDomainNameValidationAgainstHTTPBinOrgServerTrust {
    AFSecurityPolicy *policy = [[AFSecurityPolicy alloc] init];
    
    SecCertificateRef geotrustRootCertificate = AFUTGeotrustRootCertificate();
    SecCertificateRef rapidSSLCertificate = AFUTRapidSSLCertificate();
    SecCertificateRef httpBinCertificate = AFUTHTTPBinOrgCertificate();
    
    [policy setPinnedCertificates:@[(__bridge_transfer NSData *)SecCertificateCopyData(geotrustRootCertificate),
                                    (__bridge_transfer NSData *)SecCertificateCopyData(rapidSSLCertificate),
                                    (__bridge_transfer NSData *)SecCertificateCopyData(httpBinCertificate)]];
    
    CFRelease(geotrustRootCertificate);
    CFRelease(rapidSSLCertificate);
    CFRelease(httpBinCertificate);
    
    policy.validatesDomainName = YES;
    [policy setSSLPinningMode:AFSSLPinningModePublicKey];
    
    SecTrustRef trust = AFUTHTTPBinOrgServerTrust();
    XCTAssert([policy evaluateServerTrust:trust forDomain:@"httpbin.org"], @"HTTPBin.org Public Key Pinning Mode Failed");
    CFRelease(trust);
}

- (void)testCertificatePinningFailsForHTTPBinOrgIfNoCertificateIsPinned {
    AFSecurityPolicy *policy = [[AFSecurityPolicy alloc] init];
    [policy setPinnedCertificates:@[]];
    [policy setSSLPinningMode:AFSSLPinningModeCertificate];
    
    SecTrustRef trust = AFUTHTTPBinOrgServerTrust();
    XCTAssert([policy evaluateServerTrust:trust forDomain:@"httpbin.org"] == NO, @"HTTPBin.org Certificate Pinning Should have failed with no pinned certificate");
    CFRelease(trust);
}

- (void)testCertificatePinningFailsForHTTPBinOrgIfDomainNameDoesntMatch {
    AFSecurityPolicy *policy = [[AFSecurityPolicy alloc] init];
    SecCertificateRef certificate = AFUTHTTPBinOrgCertificate();
    [policy setPinnedCertificates:@[(__bridge_transfer NSData *)SecCertificateCopyData(certificate)]];
    CFRelease(certificate);
    policy.validatesDomainName = YES;
    [policy setSSLPinningMode:AFSSLPinningModePublicKey];
    
    SecTrustRef trust = AFUTHTTPBinOrgServerTrust();
    XCTAssert([policy evaluateServerTrust:trust forDomain:@"www.httpbin.org"] == NO, @"HTTPBin.org Certificate Pinning Should have failed with no pinned certificate");
    CFRelease(trust);
}

- (void)testNoPinningIsEnforcedForHTTPBinOrgIfNoCertificateIsPinned {
    AFSecurityPolicy *policy = [[AFSecurityPolicy alloc] init];
    [policy setPinnedCertificates:@[]];
    [policy setSSLPinningMode:AFSSLPinningModeNone];

    SecTrustRef trust = AFUTHTTPBinOrgServerTrust();
    XCTAssert([policy evaluateServerTrust:trust forDomain:@"httpbin.org"], @"HTTPBin.org Pinning should not have been enforced");
    CFRelease(trust);
}

- (void)testPublicKeyPinningForHTTPBinOrgFailsWhenPinnedAgainstADNServerTrust {
    AFSecurityPolicy *policy = [[AFSecurityPolicy alloc] init];
    SecCertificateRef certificate = AFUTHTTPBinOrgCertificate();
    [policy setPinnedCertificates:@[(__bridge_transfer NSData *)SecCertificateCopyData(certificate)]];
    [policy setValidatesCertificateChain:NO];
    [policy setSSLPinningMode:AFSSLPinningModePublicKey];

    SecTrustRef trust = AFUTADNNetServerTrust();
    XCTAssert([policy evaluateServerTrust:trust forDomain:@"httpbin.org"] == NO, @"HTTPBin.org Public Key Pinning Should have failed against ADN");
    CFRelease(trust);
}

- (void)testCertificatePinningForHTTPBinOrgFailsWhenPinnedAgainstADNServerTrust {
    AFSecurityPolicy *policy = [[AFSecurityPolicy alloc] init];
    SecCertificateRef certificate = AFUTHTTPBinOrgCertificate();
    [policy setPinnedCertificates:@[(__bridge_transfer NSData *)SecCertificateCopyData(certificate)]];
    [policy setSSLPinningMode:AFSSLPinningModeCertificate];
    [policy setValidatesCertificateChain:NO];

    SecTrustRef trust = AFUTADNNetServerTrust();
    XCTAssert([policy evaluateServerTrust:trust forDomain:@"httpbin.org"] == NO, @"HTTPBin.org Certificate Pinning Should have failed against ADN");
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

- (void)testCertificatePinningIsEnforcedWhenPinningSelfSignedCertificateWithoutDomain {
    SecCertificateRef certificate = AFUTSelfSignedCertificateWithoutDomain();
    SecTrustRef trust = AFUTTrustWithCertificate(certificate);

    AFSecurityPolicy *policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
    policy.pinnedCertificates = @[ (__bridge_transfer id)SecCertificateCopyData(certificate) ];
    policy.allowInvalidCertificates = YES;
    policy.validatesDomainName = NO;
    XCTAssert([policy evaluateServerTrust:trust forDomain:@"foo.bar"], @"Certificate should be trusted");

    CFRelease(trust);
    CFRelease(certificate);
}

- (void)testCertificatePinningWhenPinningSelfSignedCertificateWithoutDomain {
    SecCertificateRef certificate = AFUTSelfSignedCertificateWithoutDomain();
    SecTrustRef trust = AFUTTrustWithCertificate(certificate);

    AFSecurityPolicy *policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
    policy.pinnedCertificates = @[ (__bridge_transfer id)SecCertificateCopyData(certificate) ];
    policy.allowInvalidCertificates = YES;
    XCTAssert([policy evaluateServerTrust:trust forDomain:@"foo.bar"] == NO, @"Certificate should not be trusted");

    CFRelease(trust);
    CFRelease(certificate);
}

- (void)testCertificatePinningIsEnforcedWhenPinningSelfSignedCertificateWithCommonNameDomain {
    SecCertificateRef certificate = AFUTSelfSignedCertificateWithCommonNameDomain();
    SecTrustRef trust = AFUTTrustWithCertificate(certificate);

    AFSecurityPolicy *policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
    policy.pinnedCertificates = @[ (__bridge_transfer id)SecCertificateCopyData(certificate) ];
    policy.allowInvalidCertificates = YES;
    XCTAssert([policy evaluateServerTrust:trust forDomain:@"foobar.com"], @"Certificate should be trusted");

    CFRelease(trust);
    CFRelease(certificate);
}

- (void)testCertificatePinningWhenPinningSelfSignedCertificateWithCommonNameDomain {
    SecCertificateRef certificate = AFUTSelfSignedCertificateWithCommonNameDomain();
    SecTrustRef trust = AFUTTrustWithCertificate(certificate);

    AFSecurityPolicy *policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
    policy.pinnedCertificates = @[ (__bridge_transfer id)SecCertificateCopyData(certificate) ];
    policy.allowInvalidCertificates = YES;
    XCTAssert([policy evaluateServerTrust:trust forDomain:@"foo.bar"] == NO, @"Certificate should not be trusted");

    CFRelease(trust);
    CFRelease(certificate);
}

- (void)testCertificatePinningIsEnforcedWhenPinningSelfSignedCertificateWithDNSNameDomain {
    SecCertificateRef certificate = AFUTSelfSignedCertificateWithDNSNameDomain();
    SecTrustRef trust = AFUTTrustWithCertificate(certificate);

    AFSecurityPolicy *policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
    policy.pinnedCertificates = @[ (__bridge_transfer id)SecCertificateCopyData(certificate) ];
    policy.allowInvalidCertificates = YES;
    XCTAssert([policy evaluateServerTrust:trust forDomain:@"foobar.com"], @"Certificate should be trusted");

    CFRelease(trust);
    CFRelease(certificate);
}

- (void)testCertificatePinningWhenPinningSelfSignedCertificateWithDNSNameDomain {
    SecCertificateRef certificate = AFUTSelfSignedCertificateWithDNSNameDomain();
    SecTrustRef trust = AFUTTrustWithCertificate(certificate);

    AFSecurityPolicy *policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
    policy.pinnedCertificates = @[ (__bridge_transfer id)SecCertificateCopyData(certificate) ];
    policy.allowInvalidCertificates = YES;
    XCTAssert([policy evaluateServerTrust:trust forDomain:@"foo.bar"] == NO, @"Certificate should not be trusted");

    CFRelease(trust);
    CFRelease(certificate);
}

- (void)testDefaultPolicySetToCertificateChain {
    AFSecurityPolicy *policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
    SecTrustRef trust = AFUTADNNetServerTrust();
    XCTAssert([policy evaluateServerTrust:trust forDomain:nil], @"Pinning with Default Certficiate Chain Failed");
    CFRelease(trust);
}

- (void)testDefaultPolicySetToLeafCertificate {
    AFSecurityPolicy *policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
    [policy setValidatesCertificateChain:NO];
    SecTrustRef trust = AFUTADNNetServerTrust();
    XCTAssert([policy evaluateServerTrust:trust forDomain:nil], @"Pinning with Default Leaf Certficiate Failed");
    CFRelease(trust);
}

- (void)testDefaultPolicySetToPublicKeyChain {
    AFSecurityPolicy *policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModePublicKey];
    SecTrustRef trust = AFUTADNNetServerTrust();
    XCTAssert([policy evaluateServerTrust:trust forDomain:nil], @"Pinning with Default Public Key Chain Failed");
    CFRelease(trust);
}

- (void)testDefaultPolicySetToLeafPublicKey {
    AFSecurityPolicy *policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModePublicKey];
    [policy setValidatesCertificateChain:NO];
    SecTrustRef trust = AFUTADNNetServerTrust();
    XCTAssert([policy evaluateServerTrust:trust forDomain:nil], @"Pinning with Default Leaf Public Key Failed");
    CFRelease(trust);
}

- (void)testDefaultPolicySetToCertificateChainFailsWithMissingChain {
    AFSecurityPolicy *policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
    
    // By default the cer files are picked up from the bundle, this forces them to be cleared to emulate having none available
    [policy setPinnedCertificates:@[]];
    
    SecTrustRef trust = AFUTHTTPBinOrgServerTrust();
    XCTAssert([policy evaluateServerTrust:trust forDomain:nil] == NO, @"Pinning with Certificate Chain Mode and Missing Chain should have failed");
    CFRelease(trust);
}

- (void)testDefaultPolicySetToPublicKeyChainFailsWithMissingChain {
    AFSecurityPolicy *policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModePublicKey];
    
    // By default the cer files are picked up from the bundle, this forces them to be cleared to emulate having none available
    [policy setPinnedCertificates:@[]];
    
    SecTrustRef trust = AFUTHTTPBinOrgServerTrust();
    XCTAssert([policy evaluateServerTrust:trust forDomain:nil] == NO, @"Pinning with Public Key Chain Mode and Missing Chain should have failed");
    CFRelease(trust);
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

- (void)testPolicyWithPinningModeIsSetToValidatesDomainName {
    AFSecurityPolicy *policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
    
    XCTAssert(policy.validatesDomainName == YES, @"policyWithPinningMode: should not allow invalid ssl certificates by default.");
}

- (void)testThatSSLPinningPolicyClassMethodContainsDefaultCertificates{
    AFSecurityPolicy *policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModePublicKey];
    [policy setValidatesCertificateChain:NO];
    XCTAssertNotNil(policy.pinnedCertificates, @"Default certificate array should not be empty for SSL pinning mode policy");
}

- (void)testThatDefaultPinningPolicyClassMethodContainsNoDefaultCertificates{
    AFSecurityPolicy *policy = [AFSecurityPolicy defaultPolicy];
    XCTAssertNil(policy.pinnedCertificates, @"Default certificate array should be empty for default policy.");
}

@end
