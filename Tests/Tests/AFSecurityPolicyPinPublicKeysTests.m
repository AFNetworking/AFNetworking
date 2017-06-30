// AFSecurityPolicyPinPublicKeysTests.m
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

@interface AFSecurityPolicyPinPublicKeysTests : AFSecurityPolicyTests

@end

@implementation AFSecurityPolicyPinPublicKeysTests

#pragma mark - Validate Certificate Chain Without Validating Host

- (void)testThatPinningLeafKeyPassesEvaluationWithoutHostValidation {
    // Given
    NSString *host = @"test.alamofire.org";
    SecTrustRef serverTrust = [AFTestTrusts leafValidDNSName];
    SecCertificateRef certificate = [AFTestCertificates leafValidDNSName];
    
    NSData *certificateData = (__bridge NSData *)SecCertificateCopyData(certificate);
    
    AFSecurityPolicy *securityPolicy =
    [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModePublicKey
                     withPinnedCertificates:[NSSet setWithObject:certificateData]];
    securityPolicy.validatesDomainName = NO;
    
    // When
    [self setRootCertificateAsLoneAnchorCertificateForTrust:serverTrust];
    BOOL serverTrustIsValid = [securityPolicy evaluateServerTrust:serverTrust
                                                        forDomain:host];
    
    // Then
    XCTAssertTrue(serverTrustIsValid, @"server trust should pass evaluation");
}

- (void)testThatPinningIntermediateKeyPassesEvaluationWithoutHostValidation {
    // Given
    NSString *host = @"test.alamofire.org";
    SecTrustRef serverTrust = [AFTestTrusts leafValidDNSName];
    SecCertificateRef certificate = [AFTestCertificates intermediateCA2];
    
    NSData *certificateData = (__bridge NSData *)SecCertificateCopyData(certificate);
    
    AFSecurityPolicy *securityPolicy =
    [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModePublicKey
                     withPinnedCertificates:[NSSet setWithObject:certificateData]];
    securityPolicy.validatesDomainName = NO;
    
    // When
    [self setRootCertificateAsLoneAnchorCertificateForTrust:serverTrust];
    BOOL serverTrustIsValid = [securityPolicy evaluateServerTrust:serverTrust
                                                        forDomain:host];
    
    // Then
    XCTAssertTrue(serverTrustIsValid, @"server trust should pass evaluation");
}

- (void)testThatPinningRootKeyPassesEvaluationWithoutHostValidation {
    // Given
    NSString *host = @"test.alamofire.org";
    SecTrustRef serverTrust = [AFTestTrusts leafValidDNSName];
    SecCertificateRef certificate = [AFTestCertificates rootCA];
    
    NSData *certificateData = (__bridge NSData *)SecCertificateCopyData(certificate);
    
    AFSecurityPolicy *securityPolicy =
    [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModePublicKey
                     withPinnedCertificates:[NSSet setWithObject:certificateData]];
    securityPolicy.validatesDomainName = NO;
    
    // When
    [self setRootCertificateAsLoneAnchorCertificateForTrust:serverTrust];
    BOOL serverTrustIsValid = [securityPolicy evaluateServerTrust:serverTrust
                                                        forDomain:host];
    
    // Then
    XCTAssertTrue(serverTrustIsValid, @"server trust should pass evaluation");
}

- (void)testThatPinningKeyNotInCertificateChainFailsEvaluationWithoutHostValidation {
    // Given
    // Given
    NSString *host = @"test.alamofire.org";
    SecTrustRef serverTrust = [AFTestTrusts leafValidDNSName];
    SecCertificateRef certificate = [AFTestCertificates leafSignedByCA2];
    
    NSData *certificateData = (__bridge NSData *)SecCertificateCopyData(certificate);
    
    AFSecurityPolicy *securityPolicy =
    [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModePublicKey
                     withPinnedCertificates:[NSSet setWithObject:certificateData]];
    securityPolicy.validatesDomainName = NO;
    
    // When
    BOOL serverTrustIsValid = [securityPolicy evaluateServerTrust:serverTrust
                                                        forDomain:host];
    
    // Then
    XCTAssertFalse(serverTrustIsValid, @"server trust should not pass evaluation");
}

- (void)testThatPinningBackupKeyPassesEvaluationWithoutHostValidation {
    // Given
    NSString *host = @"test.alamofire.org";
    SecTrustRef serverTrust = [AFTestTrusts leafValidDNSName];
    
    NSMutableSet<NSData *> *certificateData = [[NSMutableSet alloc] init];

    void (^addCertificateDataToSet)(SecCertificateRef) = ^(SecCertificateRef cert) {
        CFDataRef data = SecCertificateCopyData(cert);
        [certificateData addObject:(__bridge_transfer NSData *)data];
    };
    
    addCertificateDataToSet([AFTestCertificates leafSignedByCA1]);
    addCertificateDataToSet([AFTestCertificates intermediateCA1]);
    addCertificateDataToSet([AFTestCertificates leafValidDNSName]);
    
    AFSecurityPolicy *securityPolicy =
    [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModePublicKey
                     withPinnedCertificates:certificateData];
    securityPolicy.validatesDomainName = NO;
    
    // When
    [self setRootCertificateAsLoneAnchorCertificateForTrust:serverTrust];
    BOOL serverTrustIsValid = [securityPolicy evaluateServerTrust:serverTrust
                                                        forDomain:host];
    
    // Then
    XCTAssertTrue(serverTrustIsValid, @"server trust should pass evaluation");
}

#pragma mark - Validate Certificate Chain and Host

- (void)testThatPinningLeafKeyPassesEvaluationWithHostValidation {
    // Given
    NSString *host = @"test.alamofire.org";
    SecTrustRef serverTrust = [AFTestTrusts leafValidDNSName];
    SecCertificateRef certificate = [AFTestCertificates leafValidDNSName];
    
    NSData *certificateData = (__bridge NSData *)SecCertificateCopyData(certificate);
    
    AFSecurityPolicy *securityPolicy =
    [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModePublicKey
                     withPinnedCertificates:[NSSet setWithObject:certificateData]];
    
    // When
    [self setRootCertificateAsLoneAnchorCertificateForTrust:serverTrust];
    BOOL serverTrustIsValid = [securityPolicy evaluateServerTrust:serverTrust
                                                        forDomain:host];
    
    // Then
    XCTAssertTrue(serverTrustIsValid, @"server trust should pass evaluation");
}

- (void)testThatPinningIntermediateKeyPassesEvaluationWithHostValidation {
    // Given
    NSString *host = @"test.alamofire.org";
    SecTrustRef serverTrust = [AFTestTrusts leafValidDNSName];
    SecCertificateRef certificate = [AFTestCertificates intermediateCA2];
    
    NSData *certificateData = (__bridge NSData *)SecCertificateCopyData(certificate);
    
    AFSecurityPolicy *securityPolicy =
    [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModePublicKey
                     withPinnedCertificates:[NSSet setWithObject:certificateData]];
    
    // When
    [self setRootCertificateAsLoneAnchorCertificateForTrust:serverTrust];
    BOOL serverTrustIsValid = [securityPolicy evaluateServerTrust:serverTrust
                                                        forDomain:host];
    
    // Then
    XCTAssertTrue(serverTrustIsValid, @"server trust should pass evaluation");
}

- (void)testThatPinningRootKeyPassesEvaluationWithHostValidation {
    // Given
    NSString *host = @"test.alamofire.org";
    SecTrustRef serverTrust = [AFTestTrusts leafValidDNSName];
    SecCertificateRef certificate = [AFTestCertificates rootCA];
    
    NSData *certificateData = (__bridge NSData *)SecCertificateCopyData(certificate);
    
    AFSecurityPolicy *securityPolicy =
    [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModePublicKey
                     withPinnedCertificates:[NSSet setWithObject:certificateData]];
    
    // When
    [self setRootCertificateAsLoneAnchorCertificateForTrust:serverTrust];
    BOOL serverTrustIsValid = [securityPolicy evaluateServerTrust:serverTrust
                                                        forDomain:host];
    
    // Then
    XCTAssertTrue(serverTrustIsValid, @"server trust should pass evaluation");
}

- (void)testThatPinningKeyNotInCertificateChainFailsEvaluationWithHostValidation {
    // Given
    NSString *host = @"test.alamofire.org";
    SecTrustRef serverTrust = [AFTestTrusts leafValidDNSName];
    SecCertificateRef certificate = [AFTestCertificates leafSignedByCA2];
    
    NSData *certificateData = (__bridge NSData *)SecCertificateCopyData(certificate);
    
    AFSecurityPolicy *securityPolicy =
    [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModePublicKey
                     withPinnedCertificates:[NSSet setWithObject:certificateData]];
    
    // When
    [self setRootCertificateAsLoneAnchorCertificateForTrust:serverTrust];
    BOOL serverTrustIsValid = [securityPolicy evaluateServerTrust:serverTrust
                                                        forDomain:host];
    
    // Then
    XCTAssertFalse(serverTrustIsValid, @"server trust should not pass evaluation");
}

- (void)testThatPinningBackupKeyPassesEvaluationWithHostValidation {
    // Given
    NSString *host = @"test.alamofire.org";
    SecTrustRef serverTrust = [AFTestTrusts leafValidDNSName];

    NSMutableSet<NSData *> *certificateData = [[NSMutableSet alloc] init];
    
    void (^addCertificateDataToSet)(SecCertificateRef) = ^(SecCertificateRef cert) {
        CFDataRef data = SecCertificateCopyData(cert);
        [certificateData addObject:(__bridge_transfer NSData *)data];
    };
    
    addCertificateDataToSet([AFTestCertificates leafSignedByCA1]);
    addCertificateDataToSet([AFTestCertificates intermediateCA1]);
    addCertificateDataToSet([AFTestCertificates leafValidDNSName]);
    
    AFSecurityPolicy *securityPolicy =
    [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModePublicKey
                     withPinnedCertificates:certificateData];
    securityPolicy.validatesDomainName = NO;
    
    // When
    [self setRootCertificateAsLoneAnchorCertificateForTrust:serverTrust];
    BOOL serverTrustIsValid = [securityPolicy evaluateServerTrust:serverTrust
                                                        forDomain:host];
    
    // Then
    XCTAssertTrue(serverTrustIsValid, @"server trust should pass evaluation");
}

#pragma mark - Do NOT Validate Certificate Chain or Host

- (void)testThatPinningLeafKeyWithoutCertificateChainValidationPassesEvaluationWithMissingIntermediateCertificate {
    // Given
    NSString *host = @"test.alamofire.org";
    SecTrustRef serverTrust = [AFTestTrusts leafValidDNSNameMissingIntermediate];
    SecCertificateRef certificate = [AFTestCertificates leafValidDNSName];
    
    NSData *certificateData = (__bridge NSData *)SecCertificateCopyData(certificate);
    
    AFSecurityPolicy *securityPolicy =
    [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModePublicKey
                     withPinnedCertificates:[NSSet setWithObject:certificateData]];
    securityPolicy.validatesDomainName = NO;
    securityPolicy.allowInvalidCertificates = YES;
    
    // When
    [self setRootCertificateAsLoneAnchorCertificateForTrust:serverTrust];
    BOOL serverTrustIsValid = [securityPolicy evaluateServerTrust:serverTrust
                                                        forDomain:host];
    
    // Then
    XCTAssertTrue(serverTrustIsValid, @"server trust should pass evaluation");
}

// TODO: See comment at top of AFSecurityPolicyPinCertificatesTests.m.
//
//- (void)testThatPinningRootKeyWithoutCertificateChainValidationFailsEvaluationWithMissingIntermediateCertificate {
//    // Given
//    NSString *host = @"test.alamofire.org";
//    SecTrustRef serverTrust = [AFTestTrusts leafValidDNSName]MissingIntermediate;
//    SecCertificateRef certificate = [AFTestCertificates rootCA];
//    
//    NSData *certificateData = (__bridge NSData *)SecCertificateCopyData(certificate);
//    
//    AFSecurityPolicy *securityPolicy =
//    [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModePublicKey
//                     withPinnedCertificates:[NSSet setWithObject:certificateData]];
//    securityPolicy.validatesDomainName = NO;
//    securityPolicy.allowInvalidCertificates = YES;
//    
//    // When
//    [self setRootCertificateAsLoneAnchorCertificateForTrust:serverTrust];
//    BOOL serverTrustIsValid = [securityPolicy evaluateServerTrust:serverTrust
//                                                        forDomain:host];
//    
//    // Then
//    XCTAssertTrue(serverTrustIsValid, @"server trust should pass evaluation");
//}

- (void)testThatPinningLeafKeyWithoutCertificateChainValidationPassesEvaluationWithIncorrectIntermediateCertificate {
    // Given
    NSString *host = @"test.alamofire.org";
    SecTrustRef serverTrust = [AFTestTrusts leafValidDNSNameWithIncorrectIntermediate];
    SecCertificateRef certificate = [AFTestCertificates leafValidDNSName];
    
    NSData *certificateData = (__bridge NSData *)SecCertificateCopyData(certificate);
    
    AFSecurityPolicy *securityPolicy =
    [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModePublicKey
                     withPinnedCertificates:[NSSet setWithObject:certificateData]];
    securityPolicy.validatesDomainName = NO;
    securityPolicy.allowInvalidCertificates = YES;
    
    // When
    [self setRootCertificateAsLoneAnchorCertificateForTrust:serverTrust];
    BOOL serverTrustIsValid = [securityPolicy evaluateServerTrust:serverTrust
                                                        forDomain:host];
    
    // Then
    XCTAssertTrue(serverTrustIsValid, @"server trust should pass evaluation");
}

- (void)testThatPinningLeafKeyWithoutCertificateChainValidationPassesEvaluationWithExpiredLeafCertificate {
    // Given
    NSString *host = @"test.alamofire.org";
    SecTrustRef serverTrust = [AFTestTrusts leafExpired];
    SecCertificateRef certificate = [AFTestCertificates leafExpired];
    
    NSData *certificateData = (__bridge NSData *)SecCertificateCopyData(certificate);
    
    AFSecurityPolicy *securityPolicy =
    [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModePublicKey
                     withPinnedCertificates:[NSSet setWithObject:certificateData]];
    securityPolicy.validatesDomainName = NO;
    securityPolicy.allowInvalidCertificates = YES;
    
    // When
    [self setRootCertificateAsLoneAnchorCertificateForTrust:serverTrust];
    BOOL serverTrustIsValid = [securityPolicy evaluateServerTrust:serverTrust
                                                        forDomain:host];
    
    // Then
    XCTAssertTrue(serverTrustIsValid, @"server trust should pass evaluation");
}

- (void)testThatPinningIntermediateKeyWithoutCertificateChainValidationPassesEvaluationWithExpiredLeafCertificate {
    // Given
    NSString *host = @"test.alamofire.org";
    SecTrustRef serverTrust = [AFTestTrusts leafExpired];
    SecCertificateRef certificate = [AFTestCertificates intermediateCA2];
    
    NSData *certificateData = (__bridge NSData *)SecCertificateCopyData(certificate);
    
    AFSecurityPolicy *securityPolicy =
    [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModePublicKey
                     withPinnedCertificates:[NSSet setWithObject:certificateData]];
    securityPolicy.validatesDomainName = NO;
    securityPolicy.allowInvalidCertificates = YES;
    
    // When
    [self setRootCertificateAsLoneAnchorCertificateForTrust:serverTrust];
    BOOL serverTrustIsValid = [securityPolicy evaluateServerTrust:serverTrust
                                                        forDomain:host];
    
    // Then
    XCTAssertTrue(serverTrustIsValid, @"server trust should pass evaluation");
}

- (void)testThatPinningRootKeyWithoutCertificateChainValidationPassesEvaluationWithExpiredLeafCertificate {
    // Given
    NSString *host = @"test.alamofire.org";
    SecTrustRef serverTrust = [AFTestTrusts leafExpired];
    SecCertificateRef certificate = [AFTestCertificates rootCA];
    
    NSData *certificateData = (__bridge NSData *)SecCertificateCopyData(certificate);
    
    AFSecurityPolicy *securityPolicy =
    [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModePublicKey
                     withPinnedCertificates:[NSSet setWithObject:certificateData]];
    securityPolicy.validatesDomainName = NO;
    securityPolicy.allowInvalidCertificates = YES;
    
    // When
    [self setRootCertificateAsLoneAnchorCertificateForTrust:serverTrust];
    BOOL serverTrustIsValid = [securityPolicy evaluateServerTrust:serverTrust
                                                        forDomain:host];
    
    // Then
    XCTAssertTrue(serverTrustIsValid, @"server trust should pass evaluation");
}

@end
