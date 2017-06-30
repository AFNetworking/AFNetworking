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

#import "AFSecurityPolicyTests.h"

@implementation AFSecurityPolicyTests

- (void)setRootCertificateAsLoneAnchorCertificateForTrust:(SecTrustRef)trust {
    SecCertificateRef rootCA = AFTestCertificates.rootCA;
    
    CFArrayRef anchorCertificats = CFArrayCreate(kCFAllocatorDefault,
                                                 (const void **)&rootCA,
                                                 1,
                                                 &kCFTypeArrayCallBacks);
    
    SecTrustSetAnchorCertificates(trust, anchorCertificats);
    SecTrustSetAnchorCertificatesOnly(trust, YES);
    
    CFRelease(anchorCertificats);
}

- (BOOL)trustIsValid:(SecTrustRef)trust {
    BOOL isValid = NO;
    
    SecTrustResultType result;
    
    OSStatus status = SecTrustEvaluate(trust, &result);
    
    if (status == errSecSuccess) {
        isValid = (result == kSecTrustResultUnspecified ||
                   result == kSecTrustResultProceed);
    }
    
    return isValid;
}

@end

@interface AFSecurityPolicyDefaultValueTests : AFSecurityPolicyTests

@end

@implementation AFSecurityPolicyDefaultValueTests

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

@end

@interface AFSecurityPolicySerializationTests : AFSecurityPolicyTests

@end

@implementation AFSecurityPolicySerializationTests

- (void)testThatPolicyCanBeCopied {
    AFSecurityPolicy *policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
    policy.allowInvalidCertificates = YES;
    policy.validatesDomainName = NO;
    policy.pinnedCertificates = [NSSet setWithObject:(__bridge_transfer id)SecCertificateCopyData([AFTestCertificates leafSignedByCA1])];
    
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
    policy.pinnedCertificates = [NSSet setWithObject:(__bridge_transfer id)SecCertificateCopyData([AFTestCertificates leafSignedByCA1])];
    
    NSMutableData *archiveData = [NSMutableData new];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:archiveData];
    [archiver encodeObject:policy forKey:@"policy"];
    [archiver finishEncoding];
    
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:archiveData];
    AFSecurityPolicy *unarchivedPolicy = [unarchiver decodeObjectForKey:@"policy"];
    
    XCTAssertNotEqual(unarchivedPolicy, policy);
    XCTAssertEqual(unarchivedPolicy.allowInvalidCertificates, policy.allowInvalidCertificates);
    XCTAssertEqual(unarchivedPolicy.validatesDomainName, policy.validatesDomainName);
    XCTAssertEqual(unarchivedPolicy.SSLPinningMode, policy.SSLPinningMode);
    XCTAssertTrue([unarchivedPolicy.pinnedCertificates isEqualToSet:policy.pinnedCertificates]);
}

- (void)testThatPolicyCanBeEncodedAndDecodedSecurely {
    XCTAssertTrue([AFSecurityPolicy supportsSecureCoding]);
    
    AFSecurityPolicy *policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
    policy.allowInvalidCertificates = YES;
    policy.validatesDomainName = NO;
    policy.pinnedCertificates = [NSSet setWithObject:(__bridge_transfer id)SecCertificateCopyData([AFTestCertificates leafSignedByCA1])];
    
    NSMutableData *archiveData = [NSMutableData new];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:archiveData];
    archiver.requiresSecureCoding = YES;
    [archiver encodeObject:policy forKey:@"policy"];
    [archiver finishEncoding];
    
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:archiveData];
    unarchiver.requiresSecureCoding = YES;
    AFSecurityPolicy *unarchivedPolicy = [unarchiver decodeObjectOfClass:[AFSecurityPolicy class] forKey:@"policy"];
    
    XCTAssertNotEqual(unarchivedPolicy, policy);
    XCTAssertEqual(unarchivedPolicy.allowInvalidCertificates, policy.allowInvalidCertificates);
    XCTAssertEqual(unarchivedPolicy.validatesDomainName, policy.validatesDomainName);
    XCTAssertEqual(unarchivedPolicy.SSLPinningMode, policy.SSLPinningMode);
    XCTAssertTrue([unarchivedPolicy.pinnedCertificates isEqualToSet:policy.pinnedCertificates]);
}

@end
