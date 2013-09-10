//
//  AFSecurityPolicyTests.m
//  AFNetworking Tests
//
//  Created by Kevin Harwood on 9/10/13.
//  Copyright (c) 2013 AFNetworking. All rights reserved.
//

#import "AFTestCase.h"
@interface AFSecurityPolicyTests : AFTestCase

@end

static SecTrustRef HTTPBinOrgServerTrust(){
    NSString * bundlePath = [[NSBundle bundleForClass:[AFSecurityPolicyTests class]] bundlePath];
    NSString * serverCertDirectoryPath = [bundlePath stringByAppendingPathComponent:@"HTTPBinOrgServerTrustChain"];
    NSArray * certFileNames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:serverCertDirectoryPath error:nil];
    NSMutableArray * certs  = [NSMutableArray arrayWithCapacity:[certFileNames count]];
    for(NSString * path in certFileNames){
        NSData * certData = [NSData dataWithContentsOfFile:[serverCertDirectoryPath stringByAppendingPathComponent:path]];
        SecCertificateRef cert = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)(certData));
        [certs addObject:(__bridge id)(cert)];
    }
    SecPolicyRef policy = SecPolicyCreateBasicX509();
    SecTrustRef trust = NULL;
    SecTrustCreateWithCertificates((__bridge CFTypeRef)(certs), policy, &trust);
    return trust;
}

static SecCertificateRef HTTPBinOrgCertificate(){
    NSString * certPath = [[NSBundle bundleForClass:[AFSecurityPolicyTests class]] pathForResource:@"httpbinorg_10242013" ofType:@"cer"];
    assert(certPath!=nil);
    NSData * certData = [NSData dataWithContentsOfFile:certPath];
    return SecCertificateCreateWithData(NULL, (__bridge CFDataRef)(certData));
}

@implementation AFSecurityPolicyTests

-(void)testPublicKeyPinningIsEnforcedForHTTPBinOrg{
    AFSecurityPolicy * policy = [[AFSecurityPolicy alloc] init];
    SecCertificateRef certificate = HTTPBinOrgCertificate();
    [policy setPinnedCertificates:@[(__bridge_transfer NSData *)SecCertificateCopyData(certificate)]];
    [policy setSSLPinningMode:AFSSLPinningModePublicKey];
    XCTAssert([policy evaluateServerTrust:HTTPBinOrgServerTrust()], @"HTTPBin.org Public Key Pinning Mode Failed");
}

-(void)testCertificatePinningIsEnforcedForHTTPBinOrg{
    AFSecurityPolicy * policy = [[AFSecurityPolicy alloc] init];
    SecCertificateRef certificate = HTTPBinOrgCertificate();
    [policy setPinnedCertificates:@[(__bridge_transfer NSData *)SecCertificateCopyData(certificate)]];
    [policy setSSLPinningMode:AFSSLPinningModeCertificate];
    XCTAssert([policy evaluateServerTrust:HTTPBinOrgServerTrust()], @"HTTPBin.org Public Key Pinning Mode Failed");
}

-(void)testNoPinningIsEnforcedForHTTPBinOrg{
    AFSecurityPolicy * policy = [[AFSecurityPolicy alloc] init];
    SecCertificateRef certificate = HTTPBinOrgCertificate();
    [policy setPinnedCertificates:@[(__bridge_transfer NSData *)SecCertificateCopyData(certificate)]];
    [policy setSSLPinningMode:AFSSLPinningModeNone];
    XCTAssert([policy evaluateServerTrust:HTTPBinOrgServerTrust()], @"HTTPBin.org Pinning should not have been enforced");
}

-(void)testPublicKeyPinningFailsForHTTPBinOrgIfNoCertificateIsPinned{
    AFSecurityPolicy * policy = [[AFSecurityPolicy alloc] init];
    [policy setPinnedCertificates:@[]];
    [policy setSSLPinningMode:AFSSLPinningModePublicKey];
    XCTAssert([policy evaluateServerTrust:HTTPBinOrgServerTrust()] == NO, @"HTTPBin.org Public Key Pinning Should have failed with no pinned certificate");
}

-(void)testCertificatePinningFailsForHTTPBinOrgIfNoCertificateIsPinned{
    AFSecurityPolicy * policy = [[AFSecurityPolicy alloc] init];
    [policy setPinnedCertificates:@[]];
    [policy setSSLPinningMode:AFSSLPinningModeCertificate];
    XCTAssert([policy evaluateServerTrust:HTTPBinOrgServerTrust()] == NO, @"HTTPBin.org Certificate Pinning Should have failed with no pinned certificate");
}

-(void)testNoPinningIsEnforcedForHTTPBinOrgIfNoCertificateIsPinned{
    AFSecurityPolicy * policy = [[AFSecurityPolicy alloc] init];
    [policy setPinnedCertificates:@[]];
    [policy setSSLPinningMode:AFSSLPinningModeNone];
    XCTAssert([policy evaluateServerTrust:HTTPBinOrgServerTrust()], @"HTTPBin.org Pinning should not have been enforced");
}

@end
