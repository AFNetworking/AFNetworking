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

+ (BOOL)shouldTrustServerTrust:(SecTrustRef)serverTrust
               withPinningMode:(AFSSLPinningMode)pinningMode
            pinnedCertificates:(NSArray*)pinnedCertificates
   allowInvalidSSLCertificates:(BOOL)allowInvalidSSLCertificates;
@end
