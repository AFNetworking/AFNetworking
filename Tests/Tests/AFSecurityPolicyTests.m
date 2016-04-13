// AFSecurityPolicyTests.m
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

//static SecTrustRef AFUTGoogleComServerTrustPath1() {
//    NSString *bundlePath = [[NSBundle bundleForClass:[AFSecurityPolicyTests class]] resourcePath];
//    NSString *serverCertDirectoryPath = [bundlePath stringByAppendingPathComponent:@"GoogleComServerTrustChainPath1"];
//    
//    return AFUTTrustChainForCertsInDirectory(serverCertDirectoryPath);
//}
//
//static SecTrustRef AFUTGoogleComServerTrustPath2() {
//    NSString *bundlePath = [[NSBundle bundleForClass:[AFSecurityPolicyTests class]] resourcePath];
//    NSString *serverCertDirectoryPath = [bundlePath stringByAppendingPathComponent:@"GoogleComServerTrustChainPath2"];
//
//    return AFUTTrustChainForCertsInDirectory(serverCertDirectoryPath);
//}

static SecCertificateRef AFUTHTTPBinOrgCertificate() {
    NSString *certPath = [[NSBundle bundleForClass:[AFSecurityPolicyTests class]] pathForResource:@"httpbinorg_01192017" ofType:@"cer"];
    NSCAssert(certPath != nil, @"Path for certificate should not be nil");
    NSData *certData = [NSData dataWithContentsOfFile:certPath];

    return SecCertificateCreateWithData(NULL, (__bridge CFDataRef)(certData));
}

static SecCertificateRef AFUTCOMODORSADomainValidationSecureServerCertificate() {
    NSString *certPath = [[NSBundle bundleForClass:[AFSecurityPolicyTests class]] pathForResource:@"COMODO_RSA_Domain_Validation_Secure_Server_CA" ofType:@"cer"];
    NSCAssert(certPath != nil, @"Path for certificate should not be nil");
    NSData *certData = [NSData dataWithContentsOfFile:certPath];

    return SecCertificateCreateWithData(NULL, (__bridge CFDataRef)(certData));
}

static SecCertificateRef AFUTCOMODORSACertificate() {
    NSString *certPath = [[NSBundle bundleForClass:[AFSecurityPolicyTests class]] pathForResource:@"COMODO_RSA_Certification_Authority" ofType:@"cer"];
    NSCAssert(certPath != nil, @"Path for certificate should not be nil");
    NSData *certData = [NSData dataWithContentsOfFile:certPath];

    return SecCertificateCreateWithData(NULL, (__bridge CFDataRef)(certData));
}

static SecCertificateRef AFUTAddTrustExternalRootCertificate() {
    NSString *certPath = [[NSBundle bundleForClass:[AFSecurityPolicyTests class]] pathForResource:@"AddTrust_External_CA_Root" ofType:@"cer"];
    NSCAssert(certPath != nil, @"Path for certificate should not be nil");
    NSData *certData = [NSData dataWithContentsOfFile:certPath];

    return SecCertificateCreateWithData(NULL, (__bridge CFDataRef)(certData));
}

//static SecCertificateRef AFUTGoogleComEquifaxSecureCARootCertificate() {
//    NSString *certPath = [[NSBundle bundleForClass:[AFSecurityPolicyTests class]] pathForResource:@"Equifax_Secure_Certificate_Authority_Root" ofType:@"cer"];
//    NSCAssert(certPath != nil, @"Path for certificate should not be nil");
//    NSData *certData = [NSData dataWithContentsOfFile:certPath];
//    
//    return SecCertificateCreateWithData(NULL, (__bridge CFDataRef)(certData));
//}
//
//static SecCertificateRef AFUTGoogleComGeoTrustGlobalCARootCertificate() {
//    NSString *certPath = [[NSBundle bundleForClass:[AFSecurityPolicyTests class]] pathForResource:@"GeoTrust_Global_CA_Root" ofType:@"cer"];
//    NSCAssert(certPath != nil, @"Path for certificate should not be nil");
//    NSData *certData = [NSData dataWithContentsOfFile:certPath];
//    
//    return SecCertificateCreateWithData(NULL, (__bridge CFDataRef)(certData));
//}

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

static SecTrustRef AFUTTrustWithCertificate(SecCertificateRef certificate) {
    NSArray *certs  = @[(__bridge id)(certificate)];

    SecPolicyRef policy = SecPolicyCreateBasicX509();
    SecTrustRef trust = NULL;
    SecTrustCreateWithCertificates((__bridge CFTypeRef)(certs), policy, &trust);
    CFRelease(policy);

    return trust;
}

@implementation AFSecurityPolicyTests

#pragma mark - Default Policy Tests
#pragma mark Default Values Test

- (void)testDefaultPolicyPinningModeIsSetToNone {
    AFSecurityPolicy *policy = [AFSecurityPolicy defaultPolicy];
    XCTAssertTrue(policy.SSLPinningMode == AFSSLPinningModeNone, @"Pinning Mode should be set to by default");
}

- (void)testDefaultPolicyHasInvalidCertificatesAreDisabledByDefault {
    AFSecurityPolicy *policy = [AFSecurityPolicy defaultPolicy];
    XCTAssertFalse(policy.allowInvalidCertificates, @"Invalid Certificates Should Be Disabled by Default");
}

- (void)testDefaultPolicyHasDomainNamesAreValidatedByDefault {
    AFSecurityPolicy *policy = [AFSecurityPolicy defaultPolicy];
    XCTAssertTrue(policy.validatesDomainName, @"Domain names should be validated by default");
}

- (void)testDefaultPolicyHasNoPinnedCertificates {
    AFSecurityPolicy *policy = [AFSecurityPolicy defaultPolicy];
    XCTAssertTrue(policy.pinnedCertificates.count == 0, @"The default policy should not have any pinned certificates");
}

#pragma mark Positive Server Trust Evaluation Tests

- (void)testDefaultPolicyDoesAllowHTTPBinOrgCertificate {
    AFSecurityPolicy *policy = [AFSecurityPolicy defaultPolicy];
    SecTrustRef trust = AFUTHTTPBinOrgServerTrust();
    XCTAssertTrue([policy evaluateServerTrust:trust forDomain:nil], @"Valid Certificate should be allowed by default.");
}

- (void)testDefaultPolicyDoesAllowHTTPBinOrgCertificateForValidDomainName {
    AFSecurityPolicy *policy = [AFSecurityPolicy defaultPolicy];
    SecTrustRef trust = AFUTHTTPBinOrgServerTrust();
    XCTAssertTrue([policy evaluateServerTrust:trust forDomain:@"httpbin.org"], @"Valid Certificate should be allowed by default.");
}

#pragma mark Negative Server Trust Evaluation Tests

- (void)testDefaultPolicyDoesNotAllowInvalidCertificate {
    AFSecurityPolicy *policy = [AFSecurityPolicy defaultPolicy];
    SecCertificateRef certificate = AFUTSelfSignedCertificateWithoutDomain();
    SecTrustRef trust = AFUTTrustWithCertificate(certificate);
    XCTAssertFalse([policy evaluateServerTrust:trust forDomain:nil], @"Invalid Certificates should not be allowed");
}

- (void)testDefaultPolicyDoesNotAllowCertificateWithInvalidDomainName {
    AFSecurityPolicy *policy = [AFSecurityPolicy defaultPolicy];
    SecTrustRef trust = AFUTHTTPBinOrgServerTrust();
    XCTAssertFalse([policy evaluateServerTrust:trust forDomain:@"apple.com"], @"Certificate should not be allowed because the domain names do not match.");
}

#pragma mark - Public Key Pinning Tests
#pragma mark Default Values Tests

- (void)testPolicyWithPublicKeyPinningModeHasPinnedCertificates {
    AFSecurityPolicy *policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModePublicKey];
    XCTAssertTrue(policy.pinnedCertificates > 0, @"Policy should contain default pinned certificates");
}

- (void)testPolicyWithPublicKeyPinningModeHasHTTPBinOrgPinnedCertificate {
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    AFSecurityPolicy *policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModePublicKey withPinnedCertificates:[AFSecurityPolicy certificatesInBundle:bundle]];

    SecCertificateRef cert = AFUTHTTPBinOrgCertificate();
    NSData *certData = (__bridge NSData *)(SecCertificateCopyData(cert));
    CFRelease(cert);
    NSSet *set = [policy.pinnedCertificates objectsPassingTest:^BOOL(NSData *data, BOOL *stop) {
        return [data isEqualToData:certData];
    }];

    XCTAssertEqual(set.count, 1U, @"HTTPBin.org certificate not found in the default certificates");
}

#pragma mark Positive Server Trust Evaluation Tests
- (void)testPolicyWithPublicKeyPinningAllowsHTTPBinOrgServerTrustWithHTTPBinOrgLeafCertificatePinned {
    AFSecurityPolicy *policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModePublicKey];

    SecCertificateRef certificate = AFUTHTTPBinOrgCertificate();
    policy.pinnedCertificates = [NSSet setWithObject:(__bridge_transfer id)SecCertificateCopyData(certificate)];
    XCTAssertTrue([policy evaluateServerTrust:AFUTHTTPBinOrgServerTrust() forDomain:nil], @"Policy should allow server trust");
}

- (void)testPolicyWithPublicKeyPinningAllowsHTTPBinOrgServerTrustWithHTTPBinOrgIntermediate1CertificatePinned {
    AFSecurityPolicy *policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModePublicKey];

    SecCertificateRef certificate = AFUTCOMODORSADomainValidationSecureServerCertificate();
    policy.pinnedCertificates = [NSSet setWithObject:(__bridge_transfer id)SecCertificateCopyData(certificate)];
    XCTAssertTrue([policy evaluateServerTrust:AFUTHTTPBinOrgServerTrust() forDomain:nil], @"Policy should allow server trust");
}

- (void)testPolicyWithPublicKeyPinningAllowsHTTPBinOrgServerTrustWithHTTPBinOrgIntermediate2CertificatePinned {
    AFSecurityPolicy *policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModePublicKey];

    SecCertificateRef certificate = AFUTCOMODORSACertificate();
    policy.pinnedCertificates = [NSSet setWithObject:(__bridge_transfer id)SecCertificateCopyData(certificate)];
    XCTAssertTrue([policy evaluateServerTrust:AFUTHTTPBinOrgServerTrust() forDomain:nil], @"Policy should allow server trust");
}

- (void)testPolicyWithPublicKeyPinningAllowsHTTPBinOrgServerTrustWithHTTPBinOrgRootCertificatePinned {
    AFSecurityPolicy *policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModePublicKey];

    SecCertificateRef certificate = AFUTAddTrustExternalRootCertificate();
    policy.pinnedCertificates = [NSSet setWithObject:(__bridge_transfer id)SecCertificateCopyData(certificate)];
    XCTAssertTrue([policy evaluateServerTrust:AFUTHTTPBinOrgServerTrust() forDomain:nil], @"Policy should allow server trust");
}

- (void)testPolicyWithPublicKeyPinningAllowsHTTPBinOrgServerTrustWithEntireCertificateChainPinned {
    AFSecurityPolicy *policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModePublicKey];

    SecCertificateRef httpBinCertificate = AFUTHTTPBinOrgCertificate();
    SecCertificateRef intermedaite1Certificate = AFUTCOMODORSADomainValidationSecureServerCertificate();
    SecCertificateRef intermedaite2Certificate = AFUTCOMODORSACertificate();
    SecCertificateRef rootCertificate = AFUTAddTrustExternalRootCertificate();
    [policy setPinnedCertificates:[NSSet setWithObjects:(__bridge_transfer NSData *)SecCertificateCopyData(httpBinCertificate),
                                                        (__bridge_transfer NSData *)SecCertificateCopyData(intermedaite1Certificate),
                                                        (__bridge_transfer NSData *)SecCertificateCopyData(intermedaite2Certificate),
                                                        (__bridge_transfer NSData *)SecCertificateCopyData(rootCertificate), nil]];
    XCTAssertTrue([policy evaluateServerTrust:AFUTHTTPBinOrgServerTrust() forDomain:nil], @"Policy should allow HTTPBinOrg server trust because at least one of the pinned certificates is valid");

}

- (void)testPolicyWithPublicKeyPinningAllowsHTTPBirnOrgServerTrustWithHTTPbinOrgPinnedCertificateAndAdditionalPinnedCertificates {
    AFSecurityPolicy *policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModePublicKey];

    SecCertificateRef httpBinCertificate = AFUTHTTPBinOrgCertificate();
    SecCertificateRef selfSignedCertificate = AFUTSelfSignedCertificateWithCommonNameDomain();
    [policy setPinnedCertificates:[NSSet setWithObjects:(__bridge_transfer NSData *)SecCertificateCopyData(httpBinCertificate),
                                                        (__bridge_transfer NSData *)SecCertificateCopyData(selfSignedCertificate), nil]];
    XCTAssertTrue([policy evaluateServerTrust:AFUTHTTPBinOrgServerTrust() forDomain:nil], @"Policy should allow HTTPBinOrg server trust because at least one of the pinned certificates is valid");
}

- (void)testPolicyWithPublicKeyPinningAllowsHTTPBinOrgServerTrustWithHTTPBinOrgLeafCertificatePinnedAndValidDomainName {
    AFSecurityPolicy *policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModePublicKey];

    SecCertificateRef certificate = AFUTHTTPBinOrgCertificate();
    policy.pinnedCertificates = [NSSet setWithObject:(__bridge_transfer id)SecCertificateCopyData(certificate)];
    XCTAssertTrue([policy evaluateServerTrust:AFUTHTTPBinOrgServerTrust() forDomain:@"httpbin.org"], @"Policy should allow server trust");
}

#pragma mark Negative Server Trust Evaluation Tests

- (void)testPolicyWithPublicKeyPinningAndNoPinnedCertificatesDoesNotAllowHTTPBinOrgServerTrust {
    AFSecurityPolicy *policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModePublicKey];
    policy.pinnedCertificates = [NSSet set];
    XCTAssertFalse([policy evaluateServerTrust:AFUTHTTPBinOrgServerTrust() forDomain:nil], @"Policy should not allow server trust because the policy is set to public key pinning and it does not contain any pinned certificates.");
}

- (void)testPolicyWithPublicKeyPinningDoesNotAllowADNServerTrustWithHTTPBinOrgPinnedCertificate {
    AFSecurityPolicy *policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModePublicKey];

    SecCertificateRef certificate = AFUTHTTPBinOrgCertificate();
    policy.pinnedCertificates = [NSSet setWithObject:(__bridge_transfer id)SecCertificateCopyData(certificate)];
    XCTAssertFalse([policy evaluateServerTrust:AFUTADNNetServerTrust() forDomain:nil], @"Policy should not allow ADN server trust for pinned HTTPBin.org certificate");
}

- (void)testPolicyWithPublicKeyPinningDoesNotAllowHTTPBinOrgServerTrustWithHTTPBinOrgLeafCertificatePinnedAndInvalidDomainName {
    AFSecurityPolicy *policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModePublicKey];

    SecCertificateRef certificate = AFUTHTTPBinOrgCertificate();
    policy.pinnedCertificates = [NSSet setWithObject:(__bridge_transfer id)SecCertificateCopyData(certificate)];
    XCTAssertFalse([policy evaluateServerTrust:AFUTHTTPBinOrgServerTrust() forDomain:@"invaliddomainname.com"], @"Policy should not allow server trust");
}

- (void)testPolicyWithPublicKeyPinningDoesNotAllowADNServerTrustWithMultipleInvalidPinnedCertificates {
    AFSecurityPolicy *policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModePublicKey];

    SecCertificateRef httpBinCertificate = AFUTHTTPBinOrgCertificate();
    SecCertificateRef selfSignedCertificate = AFUTSelfSignedCertificateWithCommonNameDomain();
    [policy setPinnedCertificates:[NSSet setWithObjects:(__bridge_transfer NSData *)SecCertificateCopyData(httpBinCertificate),
                                                        (__bridge_transfer NSData *)SecCertificateCopyData(selfSignedCertificate), nil]];
    XCTAssertFalse([policy evaluateServerTrust:AFUTADNNetServerTrust() forDomain:nil], @"Policy should not allow ADN server trust because there are no matching pinned certificates");
}

#pragma mark - Certificate Pinning Tests
#pragma mark Default Values Tests

- (void)testPolicyWithCertificatePinningModeHasPinnedCertificates {
    AFSecurityPolicy *policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
    XCTAssertTrue(policy.pinnedCertificates > 0, @"Policy should contain default pinned certificates");
}

- (void)testPolicyWithCertificatePinningModeHasHTTPBinOrgPinnedCertificate {
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    AFSecurityPolicy *policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate withPinnedCertificates:[AFSecurityPolicy certificatesInBundle:bundle]];

    SecCertificateRef cert = AFUTHTTPBinOrgCertificate();
    NSData *certData = (__bridge NSData *)(SecCertificateCopyData(cert));
    CFRelease(cert);
    NSSet *set = [policy.pinnedCertificates objectsPassingTest:^BOOL(NSData *data, BOOL *stop) {
        return [data isEqualToData:certData];
    }];

    XCTAssertEqual(set.count, 1U, @"HTTPBin.org certificate not found in the default certificates");
}

#pragma mark Positive Server Trust Evaluation Tests
- (void)testPolicyWithCertificatePinningAllowsHTTPBinOrgServerTrustWithHTTPBinOrgLeafCertificatePinned {
    AFSecurityPolicy *policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];

    SecCertificateRef certificate = AFUTHTTPBinOrgCertificate();
    policy.pinnedCertificates = [NSSet setWithObject:(__bridge_transfer id)SecCertificateCopyData(certificate)];
    XCTAssertTrue([policy evaluateServerTrust:AFUTHTTPBinOrgServerTrust() forDomain:nil], @"Policy should allow server trust");
}

- (void)testPolicyWithCertificatePinningAllowsHTTPBinOrgServerTrustWithHTTPBinOrgIntermediate1CertificatePinned {
    AFSecurityPolicy *policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];

    SecCertificateRef certificate = AFUTCOMODORSADomainValidationSecureServerCertificate();
    policy.pinnedCertificates = [NSSet setWithObject:(__bridge_transfer id)SecCertificateCopyData(certificate)];
    XCTAssertTrue([policy evaluateServerTrust:AFUTHTTPBinOrgServerTrust() forDomain:nil], @"Policy should allow server trust");
}

- (void)testPolicyWithCertificatePinningAllowsHTTPBinOrgServerTrustWithHTTPBinOrgIntermediate2CertificatePinned {
    AFSecurityPolicy *policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];

    SecCertificateRef certificate = AFUTCOMODORSACertificate();
    policy.pinnedCertificates = [NSSet setWithObject:(__bridge_transfer id)SecCertificateCopyData(certificate)];
    XCTAssertTrue([policy evaluateServerTrust:AFUTHTTPBinOrgServerTrust() forDomain:nil], @"Policy should allow server trust");
}

- (void)testPolicyWithCertificatePinningAllowsHTTPBinOrgServerTrustWithHTTPBinOrgRootCertificatePinned {
    AFSecurityPolicy *policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];

    SecCertificateRef certificate = AFUTAddTrustExternalRootCertificate();
    policy.pinnedCertificates = [NSSet setWithObject:(__bridge_transfer id)SecCertificateCopyData(certificate)];
    XCTAssertTrue([policy evaluateServerTrust:AFUTHTTPBinOrgServerTrust() forDomain:nil], @"Policy should allow server trust");
}

- (void)testPolicyWithCertificatePinningAllowsHTTPBinOrgServerTrustWithEntireCertificateChainPinned {
    AFSecurityPolicy *policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];

    SecCertificateRef httpBinCertificate = AFUTHTTPBinOrgCertificate();
    SecCertificateRef intermedaite1Certificate = AFUTCOMODORSADomainValidationSecureServerCertificate();
    SecCertificateRef intermedaite2Certificate = AFUTCOMODORSACertificate();
    SecCertificateRef rootCertificate = AFUTAddTrustExternalRootCertificate();
    [policy setPinnedCertificates:[NSSet setWithObjects:(__bridge_transfer NSData *)SecCertificateCopyData(httpBinCertificate),
                                                        (__bridge_transfer NSData *)SecCertificateCopyData(intermedaite1Certificate),
                                                        (__bridge_transfer NSData *)SecCertificateCopyData(intermedaite2Certificate),
                                                        (__bridge_transfer NSData *)SecCertificateCopyData(rootCertificate), nil]];
    XCTAssertTrue([policy evaluateServerTrust:AFUTHTTPBinOrgServerTrust() forDomain:nil], @"Policy should allow HTTPBinOrg server trust because at least one of the pinned certificates is valid");

}

- (void)testPolicyWithCertificatePinningAllowsHTTPBirnOrgServerTrustWithHTTPbinOrgPinnedCertificateAndAdditionalPinnedCertificates {
    AFSecurityPolicy *policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];

    SecCertificateRef httpBinCertificate = AFUTHTTPBinOrgCertificate();
    SecCertificateRef selfSignedCertificate = AFUTSelfSignedCertificateWithCommonNameDomain();
    [policy setPinnedCertificates:[NSSet setWithObjects:(__bridge_transfer NSData *)SecCertificateCopyData(httpBinCertificate),
                                                        (__bridge_transfer NSData *)SecCertificateCopyData(selfSignedCertificate), nil]];
    XCTAssertTrue([policy evaluateServerTrust:AFUTHTTPBinOrgServerTrust() forDomain:nil], @"Policy should allow HTTPBinOrg server trust because at least one of the pinned certificates is valid");
}

- (void)testPolicyWithCertificatePinningAllowsHTTPBinOrgServerTrustWithHTTPBinOrgLeafCertificatePinnedAndValidDomainName {
    AFSecurityPolicy *policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];

    SecCertificateRef certificate = AFUTHTTPBinOrgCertificate();
    policy.pinnedCertificates = [NSSet setWithObject:(__bridge_transfer id)SecCertificateCopyData(certificate)];
    XCTAssertTrue([policy evaluateServerTrust:AFUTHTTPBinOrgServerTrust() forDomain:@"httpbin.org"], @"Policy should allow server trust");
}

//- (void)testPolicyWithCertificatePinningAllowsGoogleComServerTrustIncompleteChainWithRootCertificatePinnedAndValidDomainName {
//    //TODO THIS TEST HAS BEEN DISABLED UNTIL CERTS HAVE BEEN UPDATED.
//    //Please see conversation here: https://github.com/AFNetworking/AFNetworking/pull/3159#issuecomment-178647437
//    //
//    // Fix certificate validation for servers providing incomplete chains (#3159) - test case
//    //
//    // google.com has two certification paths and both send incomplete certificate chains, i.e. don't include the Root CA
//    // (this can be validated in https://www.ssllabs.com/ssltest/analyze.html?d=google.com)
//    //
//    // The two certification paths are:
//    // - Path 1: *.google.com, Google Internet Authority G2 (with GeoTrust Global CA Root)
//    // - Path 2: *.google.com, Google Internet Authority G2, GeoTrust Global CA (cross signed) (with Equifax Secure CA Root)
//    //
//    // The common goal of using certificate pinning is to prevent MiTM (man-in-the-middle) attacks, so the Root CA's should be pinned to protect the entire chains.
//    // Since there's no Root CA being sent, when `-evaluateServerTrust:` invokes `AFCertificateTrustChainForServerTrust(serverTrust)`, the Root CA isn't present
//    // Therefore, even though `AFServerTrustIsValid(serverTrust)` succeeds, the next validation fails since no pinned certificate matches the `pinnedCertificates`.
//    // By fetching the `AFCertificateTrustChainForServerTrust(serverTrust)` *after* the `AFServerTrustIsValid(serverTrust)` validation, the complete chain is obtained and the Root CA's match.
//    
//    AFSecurityPolicy *policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
//
//    // certification path 1
//    SecCertificateRef certificate = AFUTGoogleComGeoTrustGlobalCARootCertificate();
//    policy.pinnedCertificates = [NSSet setWithObject:(__bridge_transfer id)SecCertificateCopyData(certificate)];
//    
//    XCTAssertTrue([policy evaluateServerTrust:AFUTGoogleComServerTrustPath1() forDomain:@"google.com"], @"Policy should allow server trust");
//
//    // certification path 2
//    certificate = AFUTGoogleComEquifaxSecureCARootCertificate();
//    policy.pinnedCertificates = [NSSet setWithObject:(__bridge_transfer id)SecCertificateCopyData(certificate)];
//
//    XCTAssertTrue([policy evaluateServerTrust:AFUTGoogleComServerTrustPath2() forDomain:@"google.com"], @"Policy should allow server trust");
//}

#pragma mark Negative Server Trust Evaluation Tests

- (void)testPolicyWithCertificatePinningAndNoPinnedCertificatesDoesNotAllowHTTPBinOrgServerTrust {
    AFSecurityPolicy *policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
    policy.pinnedCertificates = [NSSet set];
    XCTAssertFalse([policy evaluateServerTrust:AFUTHTTPBinOrgServerTrust() forDomain:nil], @"Policy should not allow server trust because the policy does not contain any pinned certificates.");
}

- (void)testPolicyWithCertificatePinningDoesNotAllowADNServerTrustWithHTTPBinOrgPinnedCertificate {
    AFSecurityPolicy *policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];

    SecCertificateRef certificate = AFUTHTTPBinOrgCertificate();
    policy.pinnedCertificates = [NSSet setWithObject:(__bridge_transfer id)SecCertificateCopyData(certificate)];
    XCTAssertFalse([policy evaluateServerTrust:AFUTADNNetServerTrust() forDomain:nil], @"Policy should not allow ADN server trust for pinned HTTPBin.org certificate");
}

- (void)testPolicyWithCertificatePinningDoesNotAllowHTTPBinOrgServerTrustWithHTTPBinOrgLeafCertificatePinnedAndInvalidDomainName {
    AFSecurityPolicy *policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];

    SecCertificateRef certificate = AFUTHTTPBinOrgCertificate();
    policy.pinnedCertificates = [NSSet setWithObject:(__bridge_transfer id)SecCertificateCopyData(certificate)];
    XCTAssertFalse([policy evaluateServerTrust:AFUTHTTPBinOrgServerTrust() forDomain:@"invaliddomainname.com"], @"Policy should not allow server trust");
}

- (void)testPolicyWithCertificatePinningDoesNotAllowADNServerTrustWithMultipleInvalidPinnedCertificates {
    AFSecurityPolicy *policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];

    SecCertificateRef httpBinCertificate = AFUTHTTPBinOrgCertificate();
    SecCertificateRef selfSignedCertificate = AFUTSelfSignedCertificateWithCommonNameDomain();
    [policy setPinnedCertificates:[NSSet setWithObjects:(__bridge_transfer NSData *)SecCertificateCopyData(httpBinCertificate),
                                                        (__bridge_transfer NSData *)SecCertificateCopyData(selfSignedCertificate), nil]];
    XCTAssertFalse([policy evaluateServerTrust:AFUTADNNetServerTrust() forDomain:nil], @"Policy should not allow ADN server trust because there are no matching pinned certificates");
}

#pragma mark - Domain Name Validation Tests
#pragma mark Positive Evaluation Tests

- (void)testThatPolicyWithoutDomainNameValidationAllowsServerTrustWithInvalidDomainName {
    AFSecurityPolicy *policy = [AFSecurityPolicy defaultPolicy];
    [policy setValidatesDomainName:NO];
    XCTAssertTrue([policy evaluateServerTrust:AFUTHTTPBinOrgServerTrust() forDomain:@"invalid.org"], @"Policy should allow server trust because domain name validation is disabled");
}

- (void)testThatPolicyWithDomainNameValidationAllowsServerTrustWithValidWildcardDomainName {
    AFSecurityPolicy *policy = [AFSecurityPolicy defaultPolicy];
    XCTAssertTrue([policy evaluateServerTrust:AFUTHTTPBinOrgServerTrust() forDomain:@"test.httpbin.org"], @"Policy should allow server trust");
}

- (void)testThatPolicyWithDomainNameValidationAndSelfSignedCommonNameCertificateAllowsServerTrust {
    AFSecurityPolicy *policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModePublicKey];

    SecCertificateRef certificate = AFUTSelfSignedCertificateWithCommonNameDomain();
    SecTrustRef trust = AFUTTrustWithCertificate(certificate);
    [policy setPinnedCertificates:[NSSet setWithObject:(__bridge_transfer NSData *)SecCertificateCopyData(certificate)]];
    [policy setAllowInvalidCertificates:YES];

    XCTAssertTrue([policy evaluateServerTrust:trust forDomain:@"foobar.com"], @"Policy should allow server trust");
}

- (void)testThatPolicyWithDomainNameValidationAndSelfSignedDNSCertificateAllowsServerTrust {
    AFSecurityPolicy *policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModePublicKey];

    SecCertificateRef certificate = AFUTSelfSignedCertificateWithDNSNameDomain();
    SecTrustRef trust = AFUTTrustWithCertificate(certificate);
    [policy setPinnedCertificates:[NSSet setWithObject:(__bridge_transfer NSData *)SecCertificateCopyData(certificate)]];
    [policy setAllowInvalidCertificates:YES];

    XCTAssertTrue([policy evaluateServerTrust:trust forDomain:@"foobar.com"], @"Policy should allow server trust");
}

#pragma mark Negative Evaluation Tests

- (void)testThatPolicyWithDomainNameValidationDoesNotAllowServerTrustWithInvalidDomainName {
    AFSecurityPolicy *policy = [AFSecurityPolicy defaultPolicy];
    XCTAssertFalse([policy evaluateServerTrust:AFUTHTTPBinOrgServerTrust() forDomain:@"invalid.org"], @"Policy should not allow allow server trust");
}

- (void)testThatPolicyWithDomainNameValidationAndSelfSignedNoDomainCertificateDoesNotAllowServerTrust {
    AFSecurityPolicy *policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];

    SecCertificateRef certificate = AFUTSelfSignedCertificateWithoutDomain();
    SecTrustRef trust = AFUTTrustWithCertificate(certificate);
    [policy setPinnedCertificates:[NSSet setWithObject:(__bridge_transfer NSData *)SecCertificateCopyData(certificate)]];
    [policy setAllowInvalidCertificates:YES];

    XCTAssertFalse([policy evaluateServerTrust:trust forDomain:@"foobar.com"], @"Policy should not allow server trust");
}

#pragma mark - Self Signed Certificate Tests
#pragma mark Positive Test Cases

- (void)testThatPolicyWithInvalidCertificatesAllowedAllowsSelfSignedServerTrust {
    AFSecurityPolicy *policy = [AFSecurityPolicy defaultPolicy];
    [policy setAllowInvalidCertificates:YES];

    SecCertificateRef certificate = AFUTSelfSignedCertificateWithDNSNameDomain();
    SecTrustRef trust = AFUTTrustWithCertificate(certificate);

    XCTAssertTrue([policy evaluateServerTrust:trust forDomain:nil], @"Policy should allow server trust because invalid certificates are allowed");
}

- (void)testThatPolicyWithInvalidCertificatesAllowedAndValidPinnedCertificatesDoesAllowSelfSignedServerTrustForValidDomainName {
    AFSecurityPolicy *policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModePublicKey];
    [policy setAllowInvalidCertificates:YES];
    SecCertificateRef certificate = AFUTSelfSignedCertificateWithDNSNameDomain();
    SecTrustRef trust = AFUTTrustWithCertificate(certificate);
    [policy setPinnedCertificates:[NSSet setWithObject:(__bridge_transfer NSData *)SecCertificateCopyData(certificate)]];

    XCTAssertTrue([policy evaluateServerTrust:trust forDomain:@"foobar.com"], @"Policy should allow server trust because invalid certificates are allowed");
}

- (void)testThatPolicyWithInvalidCertificatesAllowedAndNoSSLPinningAndDomainNameValidationDisabledDoesAllowSelfSignedServerTrustForValidDomainName {
    AFSecurityPolicy *policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
    [policy setAllowInvalidCertificates:YES];
    [policy setValidatesDomainName:NO];

    SecCertificateRef certificate = AFUTSelfSignedCertificateWithDNSNameDomain();
    SecTrustRef trust = AFUTTrustWithCertificate(certificate);

    XCTAssertTrue([policy evaluateServerTrust:trust forDomain:@"foobar.com"], @"Policy should allow server trust because invalid certificates are allowed");
}

#pragma mark Negative Test Cases

- (void)testThatPolicyWithInvalidCertificatesDisabledDoesNotAllowSelfSignedServerTrust {
    AFSecurityPolicy *policy = [AFSecurityPolicy defaultPolicy];

    SecCertificateRef certificate = AFUTSelfSignedCertificateWithDNSNameDomain();
    SecTrustRef trust = AFUTTrustWithCertificate(certificate);

    XCTAssertFalse([policy evaluateServerTrust:trust forDomain:nil], @"Policy should not allow server trust because invalid certificates are not allowed");
}

- (void)testThatPolicyWithInvalidCertificatesAllowedAndNoPinnedCertificatesAndPublicKeyPinningModeDoesNotAllowSelfSignedServerTrustForValidDomainName {
    AFSecurityPolicy *policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModePublicKey];
    [policy setAllowInvalidCertificates:YES];
    [policy setPinnedCertificates:[NSSet set]];
    SecCertificateRef certificate = AFUTSelfSignedCertificateWithDNSNameDomain();
    SecTrustRef trust = AFUTTrustWithCertificate(certificate);

    XCTAssertFalse([policy evaluateServerTrust:trust forDomain:@"foobar.com"], @"Policy should not allow server trust because invalid certificates are allowed but there are no pinned certificates");
}

- (void)testThatPolicyWithInvalidCertificatesAllowedAndValidPinnedCertificatesAndNoPinningModeDoesNotAllowSelfSignedServerTrustForValidDomainName {
    AFSecurityPolicy *policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
    [policy setAllowInvalidCertificates:YES];
    SecCertificateRef certificate = AFUTSelfSignedCertificateWithDNSNameDomain();
    SecTrustRef trust = AFUTTrustWithCertificate(certificate);
    [policy setPinnedCertificates:[NSSet setWithObject:(__bridge_transfer NSData *)SecCertificateCopyData(certificate)]];

    XCTAssertFalse([policy evaluateServerTrust:trust forDomain:@"foobar.com"], @"Policy should not allow server trust because invalid certificates are allowed but there are no pinned certificates");
}

- (void)testThatPolicyWithInvalidCertificatesAllowedAndNoValidPinnedCertificatesAndNoPinningModeAndDomainValidationDoesNotAllowSelfSignedServerTrustForValidDomainName {
    AFSecurityPolicy *policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
    [policy setAllowInvalidCertificates:YES];
    [policy setPinnedCertificates:[NSSet set]];

    SecCertificateRef certificate = AFUTSelfSignedCertificateWithDNSNameDomain();
    SecTrustRef trust = AFUTTrustWithCertificate(certificate);

    XCTAssertFalse([policy evaluateServerTrust:trust forDomain:@"foobar.com"], @"Policy should not allow server trust because invalid certificates are allowed but there are no pinned certificates");
}

#pragma mark - NSCopying
- (void)testThatPolicyCanBeCopied {
    AFSecurityPolicy *policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
    policy.allowInvalidCertificates = YES;
    policy.validatesDomainName = NO;
    policy.pinnedCertificates = [NSSet setWithObject:(__bridge_transfer id)SecCertificateCopyData(AFUTHTTPBinOrgCertificate())];

    AFSecurityPolicy *copiedPolicy = [policy copy];
    XCTAssertNotEqual(copiedPolicy, policy);
    XCTAssertEqual(copiedPolicy.allowInvalidCertificates, policy.allowInvalidCertificates);
    XCTAssertEqual(copiedPolicy.validatesDomainName, policy.validatesDomainName);
    XCTAssertEqual(copiedPolicy.SSLPinningMode, policy.SSLPinningMode);
    XCTAssertTrue([copiedPolicy.pinnedCertificates isEqualToSet:policy.pinnedCertificates]);
}

- (void)testThatPolicyCanBeEncodedAndDecoded {
    AFSecurityPolicy *policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
    policy.allowInvalidCertificates = YES;
    policy.validatesDomainName = NO;
    policy.pinnedCertificates = [NSSet setWithObject:(__bridge_transfer id)SecCertificateCopyData(AFUTHTTPBinOrgCertificate())];

    NSMutableData *archiveData = [NSMutableData new];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:archiveData];
    [archiver encodeObject:policy forKey:@"policy"];
    [archiver finishEncoding];

    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:archiveData];
    AFSecurityPolicy *unarchivedPolicy = [unarchiver decodeObjectOfClass:[AFSecurityPolicy class] forKey:@"policy"];

    XCTAssertNotEqual(unarchivedPolicy, policy);
    XCTAssertEqual(unarchivedPolicy.allowInvalidCertificates, policy.allowInvalidCertificates);
    XCTAssertEqual(unarchivedPolicy.validatesDomainName, policy.validatesDomainName);
    XCTAssertEqual(unarchivedPolicy.SSLPinningMode, policy.SSLPinningMode);
    XCTAssertTrue([unarchivedPolicy.pinnedCertificates isEqualToSet:policy.pinnedCertificates]);
}

@end
