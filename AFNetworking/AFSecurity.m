//
//  AFSecurity.m
//  
//
//  Created by Kevin Harwood on 7/31/13.
//
//

#import "AFSecurity.h"

#if !defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
static NSData *AFSecKeyGetData(SecKeyRef key) {
    CFDataRef data = NULL;
    
    OSStatus status = SecItemExport(key, kSecFormatUnknown, kSecItemPemArmour, NULL, &data);
    NSCAssert(status == errSecSuccess, @"SecItemExport error: %ld", (long int)status);
    NSCParameterAssert(data);
    
    return (__bridge_transfer NSData *)data;
}
#endif

static BOOL AFSecKeyIsEqualToKey(SecKeyRef key1, SecKeyRef key2) {
#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
    return [(__bridge id)key1 isEqual:(__bridge id)key2];
#else
    return [AFSecKeyGetData(key1) isEqual:AFSecKeyGetData(key2)];
#endif
}

@implementation AFSecurity
+ (NSArray*)defaultPinnedCertificates{
    static NSArray *_defaultPinnedCertificates = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSBundle *bundle = [NSBundle bundleForClass:[self class]];
        NSArray *paths = [bundle pathsForResourcesOfType:@"cer" inDirectory:@"."];
        
        NSMutableArray *certificates = [NSMutableArray arrayWithCapacity:[paths count]];
        for (NSString *path in paths) {
            NSData *certificateData = [NSData dataWithContentsOfFile:path];
            [certificates addObject:certificateData];
        }
        
        _defaultPinnedCertificates = [[NSArray alloc] initWithArray:certificates];
    });
    
    return _defaultPinnedCertificates;
}

+ (NSArray*)publicKeysForCertificates:(NSArray*)certificates{
    NSMutableArray *publicKeys = [NSMutableArray arrayWithCapacity:[certificates count]];
    
    for (NSData *data in certificates) {
        SecCertificateRef allowedCertificate = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)data);
        NSParameterAssert(allowedCertificate);
        
        SecCertificateRef allowedCertificates[] = {allowedCertificate};
        CFArrayRef tempCertificates = CFArrayCreate(NULL, (const void **)allowedCertificates, 1, NULL);
        
        SecPolicyRef policy = SecPolicyCreateBasicX509();
        SecTrustRef allowedTrust = NULL;
        OSStatus status = SecTrustCreateWithCertificates(tempCertificates, policy, &allowedTrust);
        NSAssert(status == errSecSuccess, @"SecTrustCreateWithCertificates error: %ld", (long int)status);
        
        SecTrustResultType result = 0;
        status = SecTrustEvaluate(allowedTrust, &result);
        NSAssert(status == errSecSuccess, @"SecTrustEvaluate error: %ld", (long int)status);
        
        SecKeyRef allowedPublicKey = SecTrustCopyPublicKey(allowedTrust);
        NSParameterAssert(allowedPublicKey);
        [publicKeys addObject:(__bridge_transfer id)allowedPublicKey];
        
        CFRelease(allowedTrust);
        CFRelease(policy);
        CFRelease(tempCertificates);
        CFRelease(allowedCertificate);
    }
    
    return [NSArray arrayWithArray:publicKeys];
}

+ (NSArray*)certificateTrustChainForServerTrust:(SecTrustRef)serverTrust{
    CFIndex certificateCount = SecTrustGetCertificateCount(serverTrust);
    NSMutableArray *trustChain = [NSMutableArray arrayWithCapacity:certificateCount];
    
    for (CFIndex i = 0; i < certificateCount; i++) {
        SecCertificateRef certificate = SecTrustGetCertificateAtIndex(serverTrust, i);
        [trustChain addObject:(__bridge_transfer NSData *)SecCertificateCopyData(certificate)];
    }
    return [NSArray arrayWithArray:trustChain];
}

+ (NSArray*)publicKeyTrustChainForServerTrust:(SecTrustRef)serverTrust{
    SecPolicyRef policy = SecPolicyCreateBasicX509();
    CFIndex certificateCount = SecTrustGetCertificateCount(serverTrust);
    NSMutableArray *trustChain = [NSMutableArray arrayWithCapacity:certificateCount];
    for (CFIndex i = 0; i < certificateCount; i++) {
        SecCertificateRef certificate = SecTrustGetCertificateAtIndex(serverTrust, i);
        
        SecCertificateRef someCertificates[] = {certificate};
        CFArrayRef certificates = CFArrayCreate(NULL, (const void **)someCertificates, 1, NULL);
        
        SecTrustRef trust = NULL;
        
        OSStatus status = SecTrustCreateWithCertificates(certificates, policy, &trust);
        NSAssert(status == errSecSuccess, @"SecTrustCreateWithCertificates error: %ld", (long int)status);
        
        SecTrustResultType result;
        status = SecTrustEvaluate(trust, &result);
        NSAssert(status == errSecSuccess, @"SecTrustEvaluate error: %ld", (long int)status);
        
        [trustChain addObject:(__bridge_transfer id)SecTrustCopyPublicKey(trust)];
        
        CFRelease(trust);
        CFRelease(certificates);
    }
    CFRelease(policy);
    return [NSArray arrayWithArray:trustChain];
}

+ (BOOL)trustChain:(NSArray*)trustChain containsPublicKeyInPinnedPublicKeys:(NSArray*)pinnedPublicKeys{
    for (id publicKey in trustChain) {
        for (id pinnedPublicKey in pinnedPublicKeys) {
            if (AFSecKeyIsEqualToKey((__bridge SecKeyRef)publicKey, (__bridge SecKeyRef)pinnedPublicKey)) {
                return YES;
            }
        }
    }
    return NO;
}

+ (BOOL)trustChain:(NSArray*)trustChain containsCertificateInPinnedCertificates:(NSArray*)pinnedCertificates{
    for (id serverCertificateData in trustChain) {
        if ([pinnedCertificates containsObject:serverCertificateData]) {
            return YES;
        }
    }
    return NO;
}

+ (BOOL)shouldTrustServerTrust:(SecTrustRef)serverTrust{
    SecTrustResultType result = 0;
    OSStatus status = SecTrustEvaluate(serverTrust, &result);
    NSAssert(status == errSecSuccess, @"SecTrustEvaluate error: %ld", (long int)status);
    return (result == kSecTrustResultUnspecified || result == kSecTrustResultProceed);
}
@end
