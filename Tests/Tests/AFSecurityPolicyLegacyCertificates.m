//
//  AFSecurityPolicyLegacyCertificates.m
//  AFNetworking
//
//  Created by Jeff Kelley on 7/10/17.
//  Copyright © 2017 AFNetworking. All rights reserved.
//

#import "AFSecurityPolicyLegacyCertificates.h"

SecTrustRef AFUTTrustChainForCertsInDirectory(NSString *directoryPath) {
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

SecTrustRef AFUTHTTPBinOrgServerTrust() {
    NSString *bundlePath = [[NSBundle bundleForClass:NSClassFromString(@"AFSecurityPolicyTests")] resourcePath];
    NSString *serverCertDirectoryPath = [bundlePath stringByAppendingPathComponent:@"HTTPBinOrgServerTrustChain"];
    
    return AFUTTrustChainForCertsInDirectory(serverCertDirectoryPath);
}

SecTrustRef AFUTADNNetServerTrust() {
    NSString *bundlePath = [[NSBundle bundleForClass:NSClassFromString(@"AFSecurityPolicyTests")] resourcePath];
    NSString *serverCertDirectoryPath = [bundlePath stringByAppendingPathComponent:@"ADNNetServerTrustChain"];
    
    return AFUTTrustChainForCertsInDirectory(serverCertDirectoryPath);
}

//static SecTrustRef AFUTGoogleComServerTrustPath1() {
//    NSString *bundlePath = [[NSBundle bundleForClass:NSClassFromString(@"AFSecurityPolicyTests")] resourcePath];
//    NSString *serverCertDirectoryPath = [bundlePath stringByAppendingPathComponent:@"GoogleComServerTrustChainPath1"];
//
//    return AFUTTrustChainForCertsInDirectory(serverCertDirectoryPath);
//}
//
//static SecTrustRef AFUTGoogleComServerTrustPath2() {
//    NSString *bundlePath = [[NSBundle bundleForClass:NSClassFromString(@"AFSecurityPolicyTests")] resourcePath];
//    NSString *serverCertDirectoryPath = [bundlePath stringByAppendingPathComponent:@"GoogleComServerTrustChainPath2"];
//
//    return AFUTTrustChainForCertsInDirectory(serverCertDirectoryPath);
//}

SecCertificateRef AFUTHTTPBinOrgCertificate() {
    NSString *certPath = [[NSBundle bundleForClass:NSClassFromString(@"AFSecurityPolicyTests")] pathForResource:@"httpbinorg_08132017" ofType:@"cer"];
    NSCAssert(certPath != nil, @"Path for certificate should not be nil");
    NSData *certData = [NSData dataWithContentsOfFile:certPath];
    
    return SecCertificateCreateWithData(NULL, (__bridge CFDataRef)(certData));
}

SecCertificateRef AFUTLetsEncryptAuthorityCertificate() {
    NSString *certPath = [[NSBundle bundleForClass:NSClassFromString(@"AFSecurityPolicyTests")] pathForResource:@"Let's Encrypt Authority X3" ofType:@"cer"];
    NSCAssert(certPath != nil, @"Path for certificate should not be nil");
    NSData *certData = [NSData dataWithContentsOfFile:certPath];
    
    return SecCertificateCreateWithData(NULL, (__bridge CFDataRef)(certData));
}

SecCertificateRef AFUTAddTrustExternalRootCertificate() {
    NSString *certPath = [[NSBundle bundleForClass:NSClassFromString(@"AFSecurityPolicyTests")] pathForResource:@"AddTrust_External_CA_Root" ofType:@"cer"];
    NSCAssert(certPath != nil, @"Path for certificate should not be nil");
    NSData *certData = [NSData dataWithContentsOfFile:certPath];
    
    return SecCertificateCreateWithData(NULL, (__bridge CFDataRef)(certData));
}

//static SecCertificateRef AFUTGoogleComEquifaxSecureCARootCertificate() {
//    NSString *certPath = [[NSBundle bundleForClass:NSClassFromString(@"AFSecurityPolicyTests")] pathForResource:@"Equifax_Secure_Certificate_Authority_Root" ofType:@"cer"];
//    NSCAssert(certPath != nil, @"Path for certificate should not be nil");
//    NSData *certData = [NSData dataWithContentsOfFile:certPath];
//
//    return SecCertificateCreateWithData(NULL, (__bridge CFDataRef)(certData));
//}
//
//static SecCertificateRef AFUTGoogleComGeoTrustGlobalCARootCertificate() {
//    NSString *certPath = [[NSBundle bundleForClass:NSClassFromString(@"AFSecurityPolicyTests")] pathForResource:@"GeoTrust_Global_CA_Root" ofType:@"cer"];
//    NSCAssert(certPath != nil, @"Path for certificate should not be nil");
//    NSData *certData = [NSData dataWithContentsOfFile:certPath];
//
//    return SecCertificateCreateWithData(NULL, (__bridge CFDataRef)(certData));
//}

SecCertificateRef AFUTSelfSignedCertificateWithoutDomain() {
    NSString *certPath = [[NSBundle bundleForClass:NSClassFromString(@"AFSecurityPolicyTests")] pathForResource:@"NoDomains" ofType:@"cer"];
    NSCAssert(certPath != nil, @"Path for certificate should not be nil");
    NSData *certData = [NSData dataWithContentsOfFile:certPath];
    
    return SecCertificateCreateWithData(NULL, (__bridge CFDataRef)(certData));
}

SecCertificateRef AFUTSelfSignedCertificateWithCommonNameDomain() {
    NSString *certPath = [[NSBundle bundleForClass:NSClassFromString(@"AFSecurityPolicyTests")] pathForResource:@"foobar.com" ofType:@"cer"];
    NSCAssert(certPath != nil, @"Path for certificate should not be nil");
    NSData *certData = [NSData dataWithContentsOfFile:certPath];
    
    return SecCertificateCreateWithData(NULL, (__bridge CFDataRef)(certData));
}

SecCertificateRef AFUTSelfSignedCertificateWithDNSNameDomain() {
    NSString *certPath = [[NSBundle bundleForClass:NSClassFromString(@"AFSecurityPolicyTests")] pathForResource:@"AltName" ofType:@"cer"];
    NSCAssert(certPath != nil, @"Path for certificate should not be nil");
    NSData *certData = [NSData dataWithContentsOfFile:certPath];
    
    return SecCertificateCreateWithData(NULL, (__bridge CFDataRef)(certData));
}

SecTrustRef AFUTTrustWithCertificate(SecCertificateRef certificate) {
    NSArray *certs  = @[(__bridge id)(certificate)];
    
    SecPolicyRef policy = SecPolicyCreateBasicX509();
    SecTrustRef trust = NULL;
    SecTrustCreateWithCertificates((__bridge CFTypeRef)(certs), policy, &trust);
    CFRelease(policy);
    
    return trust;
}
