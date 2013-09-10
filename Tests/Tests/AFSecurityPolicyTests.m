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

static SecTrustRef AFUTTrustChainForCertsInDirectory(NSString *directoryPath){
    NSArray * certFileNames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directoryPath error:nil];
    NSMutableArray * certs  = [NSMutableArray arrayWithCapacity:[certFileNames count]];
    for(NSString * path in certFileNames){
        NSData * certData = [NSData dataWithContentsOfFile:[directoryPath stringByAppendingPathComponent:path]];
        SecCertificateRef cert = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)(certData));
        [certs addObject:(__bridge id)(cert)];
    }
    SecPolicyRef policy = SecPolicyCreateBasicX509();
    SecTrustRef trust = NULL;
    SecTrustCreateWithCertificates((__bridge CFTypeRef)(certs), policy, &trust);
    return trust;
}

static SecTrustRef AFUTHTTPBinOrgServerTrust(){
    NSString * bundlePath = [[NSBundle bundleForClass:[AFSecurityPolicyTests class]] bundlePath];
    NSString * serverCertDirectoryPath = [bundlePath stringByAppendingPathComponent:@"HTTPBinOrgServerTrustChain"];
    return AFUTTrustChainForCertsInDirectory(serverCertDirectoryPath);
}

static SecTrustRef AFUTADNNetServerTrust(){
    NSString * bundlePath = [[NSBundle bundleForClass:[AFSecurityPolicyTests class]] bundlePath];
    NSString * serverCertDirectoryPath = [bundlePath stringByAppendingPathComponent:@"ADNNetServerTrustChain"];
    return AFUTTrustChainForCertsInDirectory(serverCertDirectoryPath);
}

static SecCertificateRef AFUTHTTPBinOrgCertificate(){
    NSString * certPath = [[NSBundle bundleForClass:[AFSecurityPolicyTests class]] pathForResource:@"httpbinorg_10242013" ofType:@"cer"];
    assert(certPath!=nil);
    NSData * certData = [NSData dataWithContentsOfFile:certPath];
    return SecCertificateCreateWithData(NULL, (__bridge CFDataRef)(certData));
}

@implementation AFSecurityPolicyTests

-(void)testPublicKeyPinningIsEnforcedForHTTPBinOrgPinnedCertificateAgainstHTTPBinOrgServerTrust{
    AFSecurityPolicy * policy = [[AFSecurityPolicy alloc] init];
    SecCertificateRef certificate = AFUTHTTPBinOrgCertificate();
    [policy setPinnedCertificates:@[(__bridge_transfer NSData *)SecCertificateCopyData(certificate)]];
    [policy setSSLPinningMode:AFSSLPinningModePublicKey];
    XCTAssert([policy evaluateServerTrust:AFUTHTTPBinOrgServerTrust()], @"HTTPBin.org Public Key Pinning Mode Failed");
}

-(void)testCertificatePinningIsEnforcedForHTTPBinOrgPinnedCertificateAgainstHTTPBinOrgServerTrust{
    AFSecurityPolicy * policy = [[AFSecurityPolicy alloc] init];
    SecCertificateRef certificate = AFUTHTTPBinOrgCertificate();
    [policy setPinnedCertificates:@[(__bridge_transfer NSData *)SecCertificateCopyData(certificate)]];
    [policy setSSLPinningMode:AFSSLPinningModeCertificate];
    XCTAssert([policy evaluateServerTrust:AFUTHTTPBinOrgServerTrust()], @"HTTPBin.org Public Key Pinning Mode Failed");
}

-(void)testNoPinningIsEnforcedForHTTPBinOrgPinnedCertificateAgainstHTTPBinOrgServerTrust{
    AFSecurityPolicy * policy = [[AFSecurityPolicy alloc] init];
    SecCertificateRef certificate = AFUTHTTPBinOrgCertificate();
    [policy setPinnedCertificates:@[(__bridge_transfer NSData *)SecCertificateCopyData(certificate)]];
    [policy setSSLPinningMode:AFSSLPinningModeNone];
    XCTAssert([policy evaluateServerTrust:AFUTHTTPBinOrgServerTrust()], @"HTTPBin.org Pinning should not have been enforced");
}

-(void)testPublicKeyPinningFailsForHTTPBinOrgIfNoCertificateIsPinned{
    AFSecurityPolicy * policy = [[AFSecurityPolicy alloc] init];
    [policy setPinnedCertificates:@[]];
    [policy setSSLPinningMode:AFSSLPinningModePublicKey];
    XCTAssert([policy evaluateServerTrust:AFUTHTTPBinOrgServerTrust()] == NO, @"HTTPBin.org Public Key Pinning Should have failed with no pinned certificate");
}

-(void)testCertificatePinningFailsForHTTPBinOrgIfNoCertificateIsPinned{
    AFSecurityPolicy * policy = [[AFSecurityPolicy alloc] init];
    [policy setPinnedCertificates:@[]];
    [policy setSSLPinningMode:AFSSLPinningModeCertificate];
    XCTAssert([policy evaluateServerTrust:AFUTHTTPBinOrgServerTrust()] == NO, @"HTTPBin.org Certificate Pinning Should have failed with no pinned certificate");
}

-(void)testNoPinningIsEnforcedForHTTPBinOrgIfNoCertificateIsPinned{
    AFSecurityPolicy * policy = [[AFSecurityPolicy alloc] init];
    [policy setPinnedCertificates:@[]];
    [policy setSSLPinningMode:AFSSLPinningModeNone];
    XCTAssert([policy evaluateServerTrust:AFUTHTTPBinOrgServerTrust()], @"HTTPBin.org Pinning should not have been enforced");
}

-(void)testPublicKeyPinningForHTTPBinOrgFailsWhenPinnedAgainstADNServerTrust{
    AFSecurityPolicy * policy = [[AFSecurityPolicy alloc] init];
    [policy setPinnedCertificates:@[]];
    [policy setSSLPinningMode:AFSSLPinningModePublicKey];
    XCTAssert([policy evaluateServerTrust:AFUTADNNetServerTrust()] == NO, @"HTTPBin.org Public Key Pinning Should have failed against ADN");
}

-(void)testCertificatePinningForHTTPBinOrgFailsWhenPinnedAgainstADNServerTrust{
    AFSecurityPolicy * policy = [[AFSecurityPolicy alloc] init];
    [policy setPinnedCertificates:@[]];
    [policy setSSLPinningMode:AFSSLPinningModeCertificate];
    XCTAssert([policy evaluateServerTrust:AFUTADNNetServerTrust()] == NO, @"HTTPBin.org Certificate Pinning Should have failed against ADN");
}

@end
