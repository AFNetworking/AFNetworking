// AFSecurityPolicyExplorationBasicX509PolicyValidationTests.m
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

@interface AFSecurityPolicyExplorationBasicX509PolicyValidationTests : AFSecurityPolicyTests

@end

@implementation AFSecurityPolicyExplorationBasicX509PolicyValidationTests

- (void)testThatAnchoredRootCertificatePassesBasicX509ValidationWithRootInTrust {
    // Given
    SecTrustRef trust =
    AFTrustRefWithCertificates([AFTestCertificates leafDNSNameAndURI],
                               [AFTestCertificates intermediateCA1],
                               [AFTestCertificates rootCA],
                               NULL);
    
    [self setRootCertificateAsLoneAnchorCertificateForTrust:trust];
    
    // When
    SecTrustSetPolicies(trust, SecPolicyCreateBasicX509());
    
    // Then
    XCTAssertTrue([self trustIsValid:trust]);
}

- (void)testThatAnchoredRootCertificatePassesBasicX509ValidationWithoutRootInTrust {
    // Given
    SecTrustRef trust = [AFTestTrusts leafDNSNameAndURI];
    [self setRootCertificateAsLoneAnchorCertificateForTrust:trust];
    
    // When
    SecTrustSetPolicies(trust, SecPolicyCreateBasicX509());
    
    // Then
    XCTAssertTrue([self trustIsValid:trust], @"trust should be valid");
}

- (void)testThatCertificateMissingDNSNamePassesBasicX509Validation {
    // Given
    SecTrustRef trust = [AFTestTrusts leafMissingDNSNameAndURI];
    [self setRootCertificateAsLoneAnchorCertificateForTrust:trust];
    
    // When
    SecTrustSetPolicies(trust, SecPolicyCreateBasicX509());
    
    // Then
    XCTAssertTrue([self trustIsValid:trust], @"trust should be valid");
}

- (void)testThatExpiredCertificateFailsBasicX509Validation {
    // Given
    SecTrustRef trust = [AFTestTrusts leafExpired];
    [self setRootCertificateAsLoneAnchorCertificateForTrust:trust];
    
    // When
    SecTrustSetPolicies(trust, SecPolicyCreateBasicX509());
    
    // Then
    XCTAssertFalse([self trustIsValid:trust], @"trust should not be valid");
}

@end
