//
// AFSecurityPolicyPerformDefaultEvaluationTests.m
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

@interface AFSecurityPolicyPerformDefaultEvaluationTests : AFSecurityPolicyTests

@end

@implementation AFSecurityPolicyPerformDefaultEvaluationTests

#pragma mark - Do NOT Validate Host

- (void)testThatValidCertificateChainPassesEvaluationWithoutHostValidation {
    // Given
    NSString *host = @"test.alamofire.org";
    SecTrustRef serverTrust = [AFTestTrusts leafValidDNSName];
    AFSecurityPolicy *securityPolicy = [AFSecurityPolicy defaultPolicy];
    securityPolicy.validatesDomainName = NO;
    
    // When
    [self setRootCertificateAsLoneAnchorCertificateForTrust:serverTrust];
    BOOL serverTrustIsValid = [securityPolicy evaluateServerTrust:serverTrust
                                                        forDomain:host];
    
    // Then
    XCTAssertTrue(serverTrustIsValid, "server trust should pass evaluation");
}

- (void)testThatNonAnchoredRootCertificateChainFailsEvaluationWithoutHostValidation {
    // Given
    NSString *host = @"test.alamofire.org";
    SecTrustRef serverTrust =
    AFTrustRefWithCertificates([AFTestCertificates leafValidDNSName],
                               [AFTestCertificates intermediateCA2],
                               NULL);
    AFSecurityPolicy *securityPolicy = [AFSecurityPolicy defaultPolicy];
    securityPolicy.validatesDomainName = NO;

    // When
    BOOL serverTrustIsValid = [securityPolicy evaluateServerTrust:serverTrust
                                                        forDomain:host];
    
    // Then
    XCTAssertFalse(serverTrustIsValid, "server trust should not pass evaluation");
}

- (void)testThatMissingDNSNameLeafCertificatePassesEvaluationWithoutHostValidation {
    // Given
    NSString *host = @"test.alamofire.org";
    SecTrustRef serverTrust = [AFTestTrusts leafMissingDNSNameAndURI];
    AFSecurityPolicy *securityPolicy = [AFSecurityPolicy defaultPolicy];
    securityPolicy.validatesDomainName = NO;

    // When
    [self setRootCertificateAsLoneAnchorCertificateForTrust:serverTrust];
    BOOL serverTrustIsValid = [securityPolicy evaluateServerTrust:serverTrust
                                                        forDomain:host];
    
    // Then
    XCTAssertTrue(serverTrustIsValid, "server trust should pass evaluation");
}

- (void)testThatExpiredCertificateChainFailsEvaluationWithoutHostValidation {
    // Given
    NSString *host = @"test.alamofire.org";
    SecTrustRef serverTrust = [AFTestTrusts leafExpired];
    AFSecurityPolicy *securityPolicy = [AFSecurityPolicy defaultPolicy];
    securityPolicy.validatesDomainName = NO;

    // When
    [self setRootCertificateAsLoneAnchorCertificateForTrust:serverTrust];
    BOOL serverTrustIsValid = [securityPolicy evaluateServerTrust:serverTrust
                                                        forDomain:host];
    
    // Then
    XCTAssertFalse(serverTrustIsValid, "server trust should not pass evaluation");
}

- (void)testThatMissingIntermediateCertificateInChainFailsEvaluationWithoutHostValidation {
    // Given
    NSString *host = @"test.alamofire.org";
    SecTrustRef serverTrust = [AFTestTrusts leafValidDNSNameMissingIntermediate];
    AFSecurityPolicy *securityPolicy = [AFSecurityPolicy defaultPolicy];
    securityPolicy.validatesDomainName = NO;

    // When
    [self setRootCertificateAsLoneAnchorCertificateForTrust:serverTrust];
    BOOL serverTrustIsValid = [securityPolicy evaluateServerTrust:serverTrust
                                                        forDomain:host];
    
    // Then
    XCTAssertFalse(serverTrustIsValid, "server trust should not pass evaluation");
}

#pragma mark - Validate Host

- (void)testThatValidCertificateChainPassesEvaluationWithHostValidation {
    // Given
    NSString *host = @"test.alamofire.org";
    SecTrustRef serverTrust = [AFTestTrusts leafValidDNSName];
    AFSecurityPolicy *securityPolicy = [AFSecurityPolicy defaultPolicy];
    
    // When
    [self setRootCertificateAsLoneAnchorCertificateForTrust:serverTrust];
    BOOL serverTrustIsValid = [securityPolicy evaluateServerTrust:serverTrust
                                                        forDomain:host];
    
    // Then
    XCTAssertTrue(serverTrustIsValid, "server trust should pass evaluation");
}

- (void)testThatNonAnchoredRootCertificateChainFailsEvaluationWithHostValidation {
    // Given
    NSString *host = @"test.alamofire.org";
    SecTrustRef serverTrust =
    AFTrustRefWithCertificates([AFTestCertificates leafValidDNSName],
                               [AFTestCertificates intermediateCA2],
                               NULL);
    AFSecurityPolicy *securityPolicy = [AFSecurityPolicy defaultPolicy];
    
    // When
    BOOL serverTrustIsValid = [securityPolicy evaluateServerTrust:serverTrust
                                                        forDomain:host];
    
    // Then
    XCTAssertFalse(serverTrustIsValid, "server trust should not pass evaluation");
}

- (void)testThatMissingDNSNameLeafCertificateFailsEvaluationWithHostValidation {
    // Given
    NSString *host = @"test.alamofire.org";
    SecTrustRef serverTrust = [AFTestTrusts leafMissingDNSNameAndURI];
    AFSecurityPolicy *securityPolicy = [AFSecurityPolicy defaultPolicy];
    
    // When
    [self setRootCertificateAsLoneAnchorCertificateForTrust:serverTrust];
    BOOL serverTrustIsValid = [securityPolicy evaluateServerTrust:serverTrust
                                                        forDomain:host];
    
    // Then
    XCTAssertFalse(serverTrustIsValid, "server trust should not pass evaluation");
}

- (void)testThatWildcardedLeafCertificateChainPassesEvaluationWithHostValidation {
    // Given
    NSString *host = @"test.alamofire.org";
    SecTrustRef serverTrust = [AFTestTrusts leafWildcard];
    AFSecurityPolicy *securityPolicy = [AFSecurityPolicy defaultPolicy];
    
    // When
    [self setRootCertificateAsLoneAnchorCertificateForTrust:serverTrust];
    BOOL serverTrustIsValid = [securityPolicy evaluateServerTrust:serverTrust
                                                        forDomain:host];
    
    // Then
    XCTAssertTrue(serverTrustIsValid, "server trust should pass evaluation");
}

- (void)testThatExpiredCertificateChainFailsEvaluationWithHostValidation {
    // Given
    NSString *host = @"test.alamofire.org";
    SecTrustRef serverTrust = [AFTestTrusts leafExpired];
    AFSecurityPolicy *securityPolicy = [AFSecurityPolicy defaultPolicy];
    
    // When
    [self setRootCertificateAsLoneAnchorCertificateForTrust:serverTrust];
    BOOL serverTrustIsValid = [securityPolicy evaluateServerTrust:serverTrust
                                                        forDomain:host];
    
    // Then
    XCTAssertFalse(serverTrustIsValid, "server trust should not pass evaluation");
}

- (void)testThatMissingIntermediateCertificateInChainFailsEvaluationWithHostValidation {
    // Given
    NSString *host = @"test.alamofire.org";
    SecTrustRef serverTrust = [AFTestTrusts leafValidDNSNameMissingIntermediate];
    AFSecurityPolicy *securityPolicy = [AFSecurityPolicy defaultPolicy];
    
    // When
    [self setRootCertificateAsLoneAnchorCertificateForTrust:serverTrust];
    BOOL serverTrustIsValid = [securityPolicy evaluateServerTrust:serverTrust
                                                        forDomain:host];
    
    // Then
    XCTAssertFalse(serverTrustIsValid, "server trust should not pass evaluation");
}

@end
