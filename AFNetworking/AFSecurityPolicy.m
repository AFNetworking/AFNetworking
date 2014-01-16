// AFSecurity.m
//
// Copyright (c) 2013 AFNetworking (http://afnetworking.com)
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

#import "AFSecurityPolicy.h"

#if !defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
static NSData * AFSecKeyGetData(SecKeyRef key) {
    CFDataRef data = NULL;
    
#if defined(NS_BLOCK_ASSERTIONS)
    SecItemExport(key, kSecFormatUnknown, kSecItemPemArmour, NULL, &data);
#else
    OSStatus status = SecItemExport(key, kSecFormatUnknown, kSecItemPemArmour, NULL, &data);
    NSCAssert(status == errSecSuccess, @"SecItemExport error: %ld", (long int)status);
#endif
    
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

static id AFPublicKeyForCertificate(NSData *certificate) {
    SecCertificateRef allowedCertificate = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)certificate);
    NSCParameterAssert(allowedCertificate);
    
    SecCertificateRef allowedCertificates[] = {allowedCertificate};
    CFArrayRef tempCertificates = CFArrayCreate(NULL, (const void **)allowedCertificates, 1, NULL);
    
    SecPolicyRef policy = SecPolicyCreateBasicX509();
    SecTrustRef allowedTrust = NULL;
#if defined(NS_BLOCK_ASSERTIONS)
    SecTrustCreateWithCertificates(tempCertificates, policy, &allowedTrust);
#else
    OSStatus status = SecTrustCreateWithCertificates(tempCertificates, policy, &allowedTrust);
    NSCAssert(status == errSecSuccess, @"SecTrustCreateWithCertificates error: %ld", (long int)status);
#endif
    
    SecTrustResultType result = 0;
    
#if defined(NS_BLOCK_ASSERTIONS)
    SecTrustEvaluate(allowedTrust, &result);
#else
    status = SecTrustEvaluate(allowedTrust, &result);
    NSCAssert(status == errSecSuccess, @"SecTrustEvaluate error: %ld", (long int)status);
#endif
    
    SecKeyRef allowedPublicKey = SecTrustCopyPublicKey(allowedTrust);
    NSCParameterAssert(allowedPublicKey);
    
    CFRelease(allowedTrust);
    CFRelease(policy);
    CFRelease(tempCertificates);
    CFRelease(allowedCertificate);
    
    return (__bridge_transfer id)allowedPublicKey;
}

static BOOL AFServerTrustIsValid(SecTrustRef serverTrust) {
    SecTrustResultType result = 0;
    
#if defined(NS_BLOCK_ASSERTIONS)
    SecTrustEvaluate(serverTrust, &result);
#else
    OSStatus status = SecTrustEvaluate(serverTrust, &result);
    NSCAssert(status == errSecSuccess, @"SecTrustEvaluate error: %ld", (long int)status);
#endif
    
    return (result == kSecTrustResultUnspecified || result == kSecTrustResultProceed);
}

static NSArray * AFCertificateTrustChainForServerTrust(SecTrustRef serverTrust) {
    CFIndex certificateCount = SecTrustGetCertificateCount(serverTrust);
    NSMutableArray *trustChain = [NSMutableArray arrayWithCapacity:(NSUInteger)certificateCount];
    
    for (CFIndex i = 0; i < certificateCount; i++) {
        SecCertificateRef certificate = SecTrustGetCertificateAtIndex(serverTrust, i);
        [trustChain addObject:(__bridge_transfer NSData *)SecCertificateCopyData(certificate)];
    }
    
    return [NSArray arrayWithArray:trustChain];
}

static NSArray * AFPublicKeyTrustChainForServerTrust(SecTrustRef serverTrust) {
    SecPolicyRef policy = SecPolicyCreateBasicX509();
    CFIndex certificateCount = SecTrustGetCertificateCount(serverTrust);
    NSMutableArray *trustChain = [NSMutableArray arrayWithCapacity:(NSUInteger)certificateCount];
    for (CFIndex i = 0; i < certificateCount; i++) {
        SecCertificateRef certificate = SecTrustGetCertificateAtIndex(serverTrust, i);
        
        SecCertificateRef someCertificates[] = {certificate};
        CFArrayRef certificates = CFArrayCreate(NULL, (const void **)someCertificates, 1, NULL);
        
        SecTrustRef trust = NULL;
        
#if defined(NS_BLOCK_ASSERTIONS)
        SecTrustCreateWithCertificates(certificates, policy, &trust);
        
        SecTrustResultType result;
        SecTrustEvaluate(trust, &result);
#else
        OSStatus status = SecTrustCreateWithCertificates(certificates, policy, &trust);
        NSCAssert(status == errSecSuccess, @"SecTrustCreateWithCertificates error: %ld", (long int)status);
        
        SecTrustResultType result;
        status = SecTrustEvaluate(trust, &result);
        NSCAssert(status == errSecSuccess, @"SecTrustEvaluate error: %ld", (long int)status);
#endif
        
        [trustChain addObject:(__bridge_transfer id)SecTrustCopyPublicKey(trust)];
        
        CFRelease(trust);
        CFRelease(certificates);
    }
    CFRelease(policy);
    
    return [NSArray arrayWithArray:trustChain];
}

static NSComparisonResult AFDomainComponentCompare(NSString *component1, NSString *component2) {
    if ([component1 isEqualToString:@"*"] || [component2 isEqualToString:@"*"]) {
        return NSOrderedSame;
    }

    return [component1 compare:component2];
}

static BOOL AFCertificateHostMatchesDomain(NSString *certificateHost, NSString *domain) {
    certificateHost = [certificateHost lowercaseString];
    domain = [domain lowercaseString];
    
    if ([certificateHost isEqualToString:domain]) {
        return YES;
    }

    NSArray *certificateHostComponents = [certificateHost componentsSeparatedByString:@"."];
    NSArray *domainComponents = [domain componentsSeparatedByString:@"."];
    
    if ([certificateHostComponents count] != [domainComponents count]) {
        return NO;
    }
    
    BOOL certificateHostMatchesDomain = ([certificateHostComponents indexOfObjectPassingTest:^BOOL(NSString *certificateHostComponent, NSUInteger idx, __unused BOOL *stop) {
        NSString *domainComponent = [domainComponents objectAtIndex:idx];

        return AFDomainComponentCompare(certificateHostComponent, domainComponent) != NSOrderedSame;
    }] == NSNotFound);
    
    return certificateHostMatchesDomain;
}

#pragma mark -

@interface AFSecurityPolicy()
@property (readwrite, nonatomic, strong) NSArray *pinnedPublicKeys;
@end

@implementation AFSecurityPolicy

+ (NSArray *)defaultPinnedCertificates {
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

+ (instancetype)defaultPolicy {
    AFSecurityPolicy *securityPolicy = [[self alloc] init];
    securityPolicy.SSLPinningMode = AFSSLPinningModeNone;
    
    return securityPolicy;
}

+ (instancetype)policyWithPinningMode:(AFSSLPinningMode)pinningMode {
    AFSecurityPolicy *securityPolicy = [[self alloc] init];
    securityPolicy.SSLPinningMode = pinningMode;
    securityPolicy.validatesDomainName = YES;
    [securityPolicy setPinnedCertificates:[self defaultPinnedCertificates]];
    
    return securityPolicy;
}

- (id)init {
    self = [super init];
    if (!self) {
        return nil;
    }

    self.validatesCertificateChain = YES;

    return self;
}

#pragma mark -

- (void)setPinnedCertificates:(NSArray *)pinnedCertificates {
    _pinnedCertificates = pinnedCertificates;
    
    if (self.pinnedCertificates) {
        NSMutableArray *mutablePinnedPublicKeys = [NSMutableArray arrayWithCapacity:[self.pinnedCertificates count]];
        for (NSData *certificate in self.pinnedCertificates) {
            [mutablePinnedPublicKeys addObject:AFPublicKeyForCertificate(certificate)];
        }
        self.pinnedPublicKeys = [NSArray arrayWithArray:mutablePinnedPublicKeys];
    } else {
        self.pinnedPublicKeys = nil;
    }
}

#pragma mark -

- (BOOL)evaluateServerTrust:(SecTrustRef)serverTrust {
    return [self evaluateServerTrust:serverTrust forDomain:nil];
}

- (BOOL)evaluateServerTrust:(SecTrustRef)serverTrust
                  forDomain:(NSString *)domain
{
    __block NSData *matchingCertificateData = nil;
    __block BOOL shouldTrustServer = NO;
    
    if (self.SSLPinningMode == AFSSLPinningModeNone && self.allowInvalidCertificates) {
        return YES;
    }

    if (!AFServerTrustIsValid(serverTrust)) {
        return NO;
    }

    NSArray *serverCertificates = AFCertificateTrustChainForServerTrust(serverTrust);
    switch (self.SSLPinningMode) {
        case AFSSLPinningModeNone:
            return YES;
        case AFSSLPinningModeCertificate: {
            if (!self.validatesCertificateChain) {
                return [self.pinnedCertificates containsObject:[serverCertificates firstObject]];
            }

            NSUInteger trustedCertificateCount = 0;
            for (NSData *trustChainCertificate in serverCertificates) {
                if ([self.pinnedCertificates containsObject:trustChainCertificate]) {
                    trustedCertificateCount++;
                }
            }

            return trustedCertificateCount > 0 && ((self.validatesCertificateChain && trustedCertificateCount == [serverCertificates count]) || (!self.validatesCertificateChain && trustedCertificateCount >= 1));
        }
            break;
        case AFSSLPinningModePublicKey: {
            NSUInteger trustedPublicKeyCount = 0;
            NSArray *publicKeys = AFPublicKeyTrustChainForServerTrust(serverTrust);
            if (!self.validatesCertificateChain && [publicKeys count] > 0) {
                publicKeys = @[[publicKeys firstObject]];
            }

            for (id trustChainPublicKey in publicKeys) {
                for (id pinnedPublicKey in self.pinnedPublicKeys) {
                    if (AFSecKeyIsEqualToKey((__bridge SecKeyRef)trustChainPublicKey, (__bridge SecKeyRef)pinnedPublicKey)) {
                        trustedPublicKeyCount += 1;
                    }
                }
            }

            return trustedPublicKeyCount > 0 && ((self.validatesCertificateChain && trustedPublicKeyCount == [serverCertificates count]) || (!self.validatesCertificateChain && trustedPublicKeyCount >= 1));
        }
            break;
        default:
            break;
    }
    
    if (shouldTrustServer && domain && self.validatesDomainName) {
        SecCertificateRef matchingCertificate = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)matchingCertificateData);
        NSParameterAssert(matchingCertificate);

        shouldTrustServer = AFCertificateHostMatchesDomain((__bridge_transfer NSString *)SecCertificateCopySubjectSummary(matchingCertificate), domain);

        CFRelease(matchingCertificate);
    }

    return shouldTrustServer;
}

#pragma mark - NSKeyValueObserving

+ (NSSet *)keyPathsForValuesAffectingPinnedPublicKeys {
    return [NSSet setWithObject:@"pinnedCertificates"];
}

@end
