//
//  AFSecurity.h
//  
//
//  Created by Kevin Harwood on 7/31/13.
//
//

#import <Foundation/Foundation.h>
#import <Security/Security.h>

typedef NS_ENUM(NSUInteger, AFSSLPinningMode) {
    AFSSLPinningModeNone,
    AFSSLPinningModePublicKey,
    AFSSLPinningModeCertificate,
};

@interface AFSecurity : NSObject
+ (NSArray*)defaultPinnedCertificates;

+ (NSArray*)publicKeysForCertificates:(NSArray*)certificates;

+ (NSArray*)certificateTrustChainForServerTrust:(SecTrustRef)serverTrust;

+ (NSArray*)publicKeyTrustChainForServerTrust:(SecTrustRef)serverTrust;

+ (BOOL)trustChain:(NSArray*)trustChain containsPublicKeyInPinnedPublicKeys:(NSArray*)pinnedPublicKeys;

+ (BOOL)trustChain:(NSArray*)trustChain containsCertificateInPinnedCertificates:(NSArray*)pinnedCertificates;

+ (BOOL)shouldTrustServerTrust:(SecTrustRef)serverTrust;
@end
