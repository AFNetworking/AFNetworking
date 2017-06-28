// AFSecurityPolicyPinCertificatesTests.m
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

#import "AFSecurityPolicyTests.h"

@interface AFSecurityPolicyPinCertificatesTests : AFSecurityPolicyTests

@end

@implementation AFSecurityPolicyPinCertificatesTests

// MARK: Validate Certificate Chain Without Validating Host

// TODO: These tests fail because AFServerTrustIsValid is called before setting the
//       anchor certificates to the passed-in server trust. Move that evaluation to
//       the "no SSL pinning mode" switch case?

- (void)testThatPinnedLeafCertificatePassesEvaluationWithoutHostValidation {
    // Given
    NSString *host = @"test.alamofire.org";
    SecTrustRef serverTrust = AFTestTrusts.leafValidDNSName;
    SecCertificateRef certificate = AFTestCertificates.leafValidDNSName;
    
    NSData *certificateData = (__bridge NSData *)SecCertificateCopyData(certificate);
    
    AFSecurityPolicy *securityPolicy =
    [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate
                     withPinnedCertificates:[NSSet setWithObject:certificateData]];
    securityPolicy.validatesDomainName = NO;
    
    // When
    BOOL serverTrustIsValid = [securityPolicy evaluateServerTrust:serverTrust
                                                        forDomain:host];
    
    // Then
    XCTAssertTrue(serverTrustIsValid, @"server trust should pass evaluation");
}

//- (void)testThatPinnedIntermediateCertificatePassesEvaluationWithoutHostValidation {
//    // Given
//    NSString *host = @"test.alamofire.org";
//    SecTrustRef serverTrust = AFTestTrusts.leafValidDNSName;
//    SecCertificateRef certificate = AFTestCertificates.intermediateCA2;
//    
//    NSData *certificateData = (__bridge NSData *)SecCertificateCopyData(certificate);
//    
//    AFSecurityPolicy *securityPolicy =
//    [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate
//                     withPinnedCertificates:[NSSet setWithObject:certificateData]];
//    securityPolicy.validatesDomainName = NO;
//    
//    // When
//    BOOL serverTrustIsValid = [securityPolicy evaluateServerTrust:serverTrust
//                                                        forDomain:host];
//    
//    // Then
//    XCTAssertTrue(serverTrustIsValid, @"server trust should pass evaluation");
//}

//- (void)testThatPinnedRootCertificatePassesEvaluationWithoutHostValidation {
//    // Given
//    NSString *host = @"test.alamofire.org";
//    SecTrustRef serverTrust = AFTestTrusts.leafValidDNSName;
//    SecCertificateRef certificate = AFTestCertificates.rootCA;
//    
//    NSData *certificateData = (__bridge NSData *)SecCertificateCopyData(certificate);
//    
//    AFSecurityPolicy *securityPolicy =
//    [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate
//                     withPinnedCertificates:[NSSet setWithObject:certificateData]];
//    securityPolicy.validatesDomainName = NO;
//    
//    // When
//    BOOL serverTrustIsValid = [securityPolicy evaluateServerTrust:serverTrust
//                                                        forDomain:host];
//    
//    // Then
//    XCTAssertTrue(serverTrustIsValid, @"server trust should pass evaluation");
//}

- (void)testThatPinningLeafCertificateNotInCertificateChainFailsEvaluationWithoutHostValidation {
    // Given
    NSString *host = @"test.alamofire.org";
    SecTrustRef serverTrust = AFTestTrusts.leafValidDNSName;
    SecCertificateRef certificate = AFTestCertificates.leafSignedByCA2;
    
    NSData *certificateData = (__bridge NSData *)SecCertificateCopyData(certificate);
    
    AFSecurityPolicy *securityPolicy =
    [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate
                     withPinnedCertificates:[NSSet setWithObject:certificateData]];
    securityPolicy.validatesDomainName = NO;
    
    // When
    BOOL serverTrustIsValid = [securityPolicy evaluateServerTrust:serverTrust
                                                        forDomain:host];
    
    // Then
    XCTAssertFalse(serverTrustIsValid, @"server trust should not pass evaluation");
}

- (void)testThatPinningIntermediateCertificateNotInCertificateChainFailsEvaluationWithoutHostValidation {
    // Given
    NSString *host = @"test.alamofire.org";
    SecTrustRef serverTrust = AFTestTrusts.leafValidDNSName;
    SecCertificateRef certificate = AFTestCertificates.intermediateCA1;
    
    NSData *certificateData = (__bridge NSData *)SecCertificateCopyData(certificate);
    
    AFSecurityPolicy *securityPolicy =
    [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate
                     withPinnedCertificates:[NSSet setWithObject:certificateData]];
    securityPolicy.validatesDomainName = NO;
    
    // When
    BOOL serverTrustIsValid = [securityPolicy evaluateServerTrust:serverTrust
                                                        forDomain:host];
    
    // Then
    XCTAssertFalse(serverTrustIsValid, @"server trust should not pass evaluation");
}

- (void)testThatPinningExpiredLeafCertificateFailsEvaluationWithoutHostValidation {
    // Given
    NSString *host = @"test.alamofire.org";
    SecTrustRef serverTrust = AFTestTrusts.leafExpired;
    SecCertificateRef certificate = AFTestCertificates.leafExpired;
    
    NSData *certificateData = (__bridge NSData *)SecCertificateCopyData(certificate);
    
    AFSecurityPolicy *securityPolicy =
    [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate
                     withPinnedCertificates:[NSSet setWithObject:certificateData]];
    securityPolicy.validatesDomainName = NO;
    
    // When
    BOOL serverTrustIsValid = [securityPolicy evaluateServerTrust:serverTrust
                                                        forDomain:host];
    
    // Then
    XCTAssertFalse(serverTrustIsValid, @"server trust should not pass evaluation");
}

- (void)testThatPinningIntermediateCertificateWithExpiredLeafCertificateFailsEvaluationWithoutHostValidation {
    // Given
    NSString *host = @"test.alamofire.org";
    SecTrustRef serverTrust = AFTestTrusts.leafExpired;
    SecCertificateRef certificate = AFTestCertificates.intermediateCA2;
    
    NSData *certificateData = (__bridge NSData *)SecCertificateCopyData(certificate);
    
    AFSecurityPolicy *securityPolicy =
    [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate
                     withPinnedCertificates:[NSSet setWithObject:certificateData]];
    securityPolicy.validatesDomainName = NO;
    
    // When
    BOOL serverTrustIsValid = [securityPolicy evaluateServerTrust:serverTrust
                                                        forDomain:host];
    
    // Then
    XCTAssertFalse(serverTrustIsValid, @"server trust should not pass evaluation");
}

#pragma mark - Validate Certificate Chain and Host

// TODO: See above TODO about AFServerTrustIsValid

//- (void)testThatPinnedLeafCertificatePassesEvaluationWithHostValidation {
//    // Given
//    NSString *host = @"test.alamofire.org";
//    SecTrustRef serverTrust = AFTestTrusts.leafValidDNSName;
//    SecCertificateRef certificate = AFTestCertificates.leafValidDNSName;
//    
//    NSData *certificateData = (__bridge NSData *)SecCertificateCopyData(certificate);
//    
//    AFSecurityPolicy *securityPolicy =
//    [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate
//                     withPinnedCertificates:[NSSet setWithObject:certificateData]];
//    
//    // When
//    BOOL serverTrustIsValid = [securityPolicy evaluateServerTrust:serverTrust
//                                                        forDomain:host];
//    
//    // Then
//    XCTAssertTrue(serverTrustIsValid, "server trust should pass evaluation");
//}

//- (void)testThatPinnedIntermediateCertificatePassesEvaluationWithHostValidation {
//    // Given
//    NSString *host = @"test.alamofire.org";
//    SecTrustRef serverTrust = AFTestTrusts.leafValidDNSName;
//    SecCertificateRef certificate = AFTestCertificates.intermediateCA2;
//    
//    NSData *certificateData = (__bridge NSData *)SecCertificateCopyData(certificate);
//    
//    AFSecurityPolicy *securityPolicy =
//    [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate
//                     withPinnedCertificates:[NSSet setWithObject:certificateData]];
//    
//    // When
//    BOOL serverTrustIsValid = [securityPolicy evaluateServerTrust:serverTrust
//                                                        forDomain:host];
//    
//    // Then
//    XCTAssertTrue(serverTrustIsValid, "server trust should pass evaluation");
//}

//- (void)testThatPinnedRootCertificatePassesEvaluationWithHostValidation {
//    // Given
//    NSString *host = @"test.alamofire.org";
//    SecTrustRef serverTrust = AFTestTrusts.leafValidDNSName;
//    SecCertificateRef certificate = AFTestCertificates.rootCA;
//    
//    NSData *certificateData = (__bridge NSData *)SecCertificateCopyData(certificate);
//    
//    AFSecurityPolicy *securityPolicy =
//    [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate
//                     withPinnedCertificates:[NSSet setWithObject:certificateData]];
//    
//    // When
//    BOOL serverTrustIsValid = [securityPolicy evaluateServerTrust:serverTrust
//                                                        forDomain:host];
//    
//    // Then
//    XCTAssertTrue(serverTrustIsValid, "server trust should pass evaluation");
//}

- (void)testThatPinningLeafCertificateNotInCertificateChainFailsEvaluationWithHostValidation {
    // Given
    NSString *host = @"test.alamofire.org";
    SecTrustRef serverTrust = AFTestTrusts.leafValidDNSName;
    SecCertificateRef certificate = AFTestCertificates.leafSignedByCA2;
    
    NSData *certificateData = (__bridge NSData *)SecCertificateCopyData(certificate);
    
    AFSecurityPolicy *securityPolicy =
    [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate
                     withPinnedCertificates:[NSSet setWithObject:certificateData]];
    
    // When
    BOOL serverTrustIsValid = [securityPolicy evaluateServerTrust:serverTrust
                                                        forDomain:host];
    
    // Then
    XCTAssertFalse(serverTrustIsValid, "server trust should not pass evaluation");
}

- (void)testThatPinningIntermediateCertificateNotInCertificateChainFailsEvaluationWithHostValidation {
    // Given
    NSString *host = @"test.alamofire.org";
    SecTrustRef serverTrust = AFTestTrusts.leafValidDNSName;
    SecCertificateRef certificate = AFTestCertificates.intermediateCA1;
    
    NSData *certificateData = (__bridge NSData *)SecCertificateCopyData(certificate);
    
    AFSecurityPolicy *securityPolicy =
    [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate
                     withPinnedCertificates:[NSSet setWithObject:certificateData]];
    
    // When
    BOOL serverTrustIsValid = [securityPolicy evaluateServerTrust:serverTrust
                                                        forDomain:host];
    
    // Then
    XCTAssertFalse(serverTrustIsValid, "server trust should not pass evaluation");
}

- (void)testThatPinningExpiredLeafCertificateFailsEvaluationWithHostValidation {
    // Given
    NSString *host = @"test.alamofire.org";
    SecTrustRef serverTrust = AFTestTrusts.leafExpired;
    SecCertificateRef certificate = AFTestCertificates.leafExpired;
    
    NSData *certificateData = (__bridge NSData *)SecCertificateCopyData(certificate);
    
    AFSecurityPolicy *securityPolicy =
    [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate
                     withPinnedCertificates:[NSSet setWithObject:certificateData]];
    
    // When
    BOOL serverTrustIsValid = [securityPolicy evaluateServerTrust:serverTrust
                                                        forDomain:host];
    
    // Then
    XCTAssertFalse(serverTrustIsValid, "server trust should not pass evaluation");
}

- (void)testThatPinningIntermediateCertificateWithExpiredLeafCertificateFailsEvaluationWithHostValidation {
    // Given
    NSString *host = @"test.alamofire.org";
    SecTrustRef serverTrust = AFTestTrusts.leafExpired;
    SecCertificateRef certificate = AFTestCertificates.intermediateCA2;
    
    NSData *certificateData = (__bridge NSData *)SecCertificateCopyData(certificate);
    
    AFSecurityPolicy *securityPolicy =
    [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate
                     withPinnedCertificates:[NSSet setWithObject:certificateData]];
    
    // When
    BOOL serverTrustIsValid = [securityPolicy evaluateServerTrust:serverTrust
                                                        forDomain:host];
    
    // Then
    XCTAssertFalse(serverTrustIsValid, "server trust should not pass evaluation");
}

#pragma mark - Do NOT Validate Certificate Chain or Host

- (void)testThatPinnedLeafCertificateWithoutCertificateChainValidationPassesEvaluation {
    // Given
    NSString *host = @"test.alamofire.org";
    SecTrustRef serverTrust = AFTestTrusts.leafValidDNSName;
    SecCertificateRef certificate = AFTestCertificates.leafValidDNSName;
    
    NSData *certificateData = (__bridge NSData *)SecCertificateCopyData(certificate);
    
    AFSecurityPolicy *securityPolicy =
    [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate
                     withPinnedCertificates:[NSSet setWithObject:certificateData]];
    securityPolicy.validatesDomainName = NO;
    securityPolicy.allowInvalidCertificates = YES;
    
    // When
    BOOL serverTrustIsValid = [securityPolicy evaluateServerTrust:serverTrust
                                                        forDomain:host];
    
    // Then
    XCTAssertTrue(serverTrustIsValid, @"server trust should pass evaluation");
}

- (void)testThatPinnedIntermediateCertificateWithoutCertificateChainValidationPassesEvaluation {
    // Given
    NSString *host = @"test.alamofire.org";
    SecTrustRef serverTrust = AFTestTrusts.leafValidDNSName;
    SecCertificateRef certificate = AFTestCertificates.intermediateCA2;
    
    NSData *certificateData = (__bridge NSData *)SecCertificateCopyData(certificate);
    
    AFSecurityPolicy *securityPolicy =
    [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate
                     withPinnedCertificates:[NSSet setWithObject:certificateData]];
    securityPolicy.validatesDomainName = NO;
    securityPolicy.allowInvalidCertificates = YES;
    
    // When
    BOOL serverTrustIsValid = [securityPolicy evaluateServerTrust:serverTrust
                                                        forDomain:host];
    
    // Then
    XCTAssertTrue(serverTrustIsValid, @"server trust should pass evaluation");
}

- (void)testThatPinnedRootCertificateWithoutCertificateChainValidationPassesEvaluation {
    // Given
    NSString *host = @"test.alamofire.org";
    SecTrustRef serverTrust = AFTestTrusts.leafValidDNSName;
    SecCertificateRef certificate = AFTestCertificates.rootCA;
    
    NSData *certificateData = (__bridge NSData *)SecCertificateCopyData(certificate);
    
    AFSecurityPolicy *securityPolicy =
    [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate
                     withPinnedCertificates:[NSSet setWithObject:certificateData]];
    securityPolicy.validatesDomainName = NO;
    securityPolicy.allowInvalidCertificates = YES;
    
    // When
    BOOL serverTrustIsValid = [securityPolicy evaluateServerTrust:serverTrust
                                                        forDomain:host];
    
    // Then
    XCTAssertTrue(serverTrustIsValid, @"server trust should pass evaluation");
}

- (void)testThatPinningLeafCertificateNotInCertificateChainWithoutCertificateChainValidationFailsEvaluation {
    // Given
    NSString *host = @"test.alamofire.org";
    SecTrustRef serverTrust = AFTestTrusts.leafValidDNSName;
    SecCertificateRef certificate = AFTestCertificates.leafSignedByCA2;
    
    NSData *certificateData = (__bridge NSData *)SecCertificateCopyData(certificate);
    
    AFSecurityPolicy *securityPolicy =
    [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate
                     withPinnedCertificates:[NSSet setWithObject:certificateData]];
    securityPolicy.validatesDomainName = NO;
    securityPolicy.allowInvalidCertificates = YES;
    
    // When
    BOOL serverTrustIsValid = [securityPolicy evaluateServerTrust:serverTrust
                                                        forDomain:host];
    
    // Then
    XCTAssertFalse(serverTrustIsValid, "server trust should not pass evaluation");
}

- (void)testThatPinningIntermediateCertificateNotInCertificateChainWithoutCertificateChainValidationFailsEvaluation {
    // Given
    NSString *host = @"test.alamofire.org";
    SecTrustRef serverTrust = AFTestTrusts.leafValidDNSName;
    SecCertificateRef certificate = AFTestCertificates.intermediateCA1;
    
    NSData *certificateData = (__bridge NSData *)SecCertificateCopyData(certificate);
    
    AFSecurityPolicy *securityPolicy =
    [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate
                     withPinnedCertificates:[NSSet setWithObject:certificateData]];
    securityPolicy.validatesDomainName = NO;
    securityPolicy.allowInvalidCertificates = YES;
    
    // When
    BOOL serverTrustIsValid = [securityPolicy evaluateServerTrust:serverTrust
                                                        forDomain:host];
    
    // Then
    XCTAssertFalse(serverTrustIsValid, "server trust should not pass evaluation");
}

// TODO: The following tests require that certificate validation be disabled while
//       also enabling SSL pinning, which is not currently supported, as there is a
//       call to AFServerTrustIsValid() for the passed server trust, even if

//- (void)testThatPinningExpiredLeafCertificateWithoutCertificateChainValidationPassesEvaluation {
//    // Given
//    NSString *host = @"test.alamofire.org";
//    SecTrustRef serverTrust = AFTestTrusts.leafExpired;
//    SecCertificateRef certificate = AFTestCertificates.leafExpired;
//    
//    NSData *certificateData = (__bridge NSData *)SecCertificateCopyData(certificate);
//    
//    AFSecurityPolicy *securityPolicy =
//    [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate
//                     withPinnedCertificates:[NSSet setWithObject:certificateData]];
//    securityPolicy.validatesDomainName = NO;
//    securityPolicy.allowInvalidCertificates = YES;
//    
//    // When
//    BOOL serverTrustIsValid = [securityPolicy evaluateServerTrust:serverTrust
//                                                        forDomain:host];
//    
//    // Then
//    XCTAssertTrue(serverTrustIsValid, "server trust should pass evaluation");
//}

//- (void)testThatPinningIntermediateCertificateWithExpiredLeafCertificateWithoutCertificateChainValidationPassesEvaluation {
//    // Given
//    NSString *host = @"test.alamofire.org";
//    SecTrustRef serverTrust = AFTestTrusts.leafExpired;
//    SecCertificateRef certificate = AFTestCertificates.intermediateCA2;
//    
//    NSData *certificateData = (__bridge NSData *)SecCertificateCopyData(certificate);
//    
//    AFSecurityPolicy *securityPolicy =
//    [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate
//                     withPinnedCertificates:[NSSet setWithObject:certificateData]];
//    securityPolicy.validatesDomainName = NO;
//    securityPolicy.allowInvalidCertificates = YES;
//    
//    // When
//    BOOL serverTrustIsValid = [securityPolicy evaluateServerTrust:serverTrust
//                                                        forDomain:host];
//    
//    // Then
//    XCTAssertTrue(serverTrustIsValid, "server trust should pass evaluation");
//}

//- (void)testThatPinningRootCertificateWithExpiredLeafCertificateWithoutCertificateChainValidationPassesEvaluation {
//    // Given
//    NSString *host = @"test.alamofire.org";
//    SecTrustRef serverTrust = AFTestTrusts.leafExpired;
//    SecCertificateRef certificate = AFTestCertificates.rootCA;
//    
//    NSData *certificateData = (__bridge NSData *)SecCertificateCopyData(certificate);
//    
//    AFSecurityPolicy *securityPolicy =
//    [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate
//                     withPinnedCertificates:[NSSet setWithObject:certificateData]];
//    securityPolicy.validatesDomainName = NO;
//    securityPolicy.allowInvalidCertificates = YES;
//    
//    // When
//    BOOL serverTrustIsValid = [securityPolicy evaluateServerTrust:serverTrust
//                                                        forDomain:host];
//    
//    // Then
//    XCTAssertTrue(serverTrustIsValid, "server trust should pass evaluation");
//}

//- (void)testThatPinningMultipleCertificatesWithoutCertificateChainValidationPassesEvaluation {
//    // Given
//    NSString *host = @"test.alamofire.org";
//    SecTrustRef serverTrust = AFTestTrusts.leafExpired;
//    
//    NSMutableSet<NSData *> *certificateData = [[NSMutableSet alloc] init];
//    
//    void (^addCertificateDataToSet)(SecCertificateRef) = ^(SecCertificateRef cert) {
//        CFDataRef data = SecCertificateCopyData(cert);
//        [certificateData addObject:(__bridge_transfer NSData *)data];
//    };
//    
//    addCertificateDataToSet(AFTestCertificates.leafMultipleDNSNames); // not in certificate chain
//    addCertificateDataToSet(AFTestCertificates.leafSignedByCA1);      // not in certificate chain
//    addCertificateDataToSet(AFTestCertificates.leafExpired);          // in certificate chain 👍🏼👍🏼
//    addCertificateDataToSet(AFTestCertificates.leafWildcard);         // not in certificate chain
//    addCertificateDataToSet(AFTestCertificates.leafDNSNameAndURI);    // not in certificate chain
//    
//    AFSecurityPolicy *securityPolicy =
//    [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate
//                     withPinnedCertificates:certificateData];
//    
//    securityPolicy.validatesDomainName = NO;
//    securityPolicy.allowInvalidCertificates = YES;
//    
//    // When
//    BOOL serverTrustIsValid = [securityPolicy evaluateServerTrust:serverTrust
//                                                        forDomain:host];
//    
//    // Then
//    XCTAssertTrue(serverTrustIsValid, @"server trust should pass evaluation");
//}

@end
