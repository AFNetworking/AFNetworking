//
//  AFSecurityPolicyLegacyCertificates.h
//  AFNetworking
//
//  Created by Jeff Kelley on 7/10/17.
//  Copyright © 2017 AFNetworking. All rights reserved.
//

#import <Foundation/Foundation.h>

SecTrustRef AFUTTrustChainForCertsInDirectory(NSString *directoryPath);
SecTrustRef AFUTHTTPBinOrgServerTrust(void);
SecTrustRef AFUTADNNetServerTrust(void);
SecCertificateRef AFUTHTTPBinOrgCertificate(void);
SecCertificateRef AFUTCOMODORSADomainValidationSecureServerCertificate(void);
SecCertificateRef AFUTCOMODORSACertificate(void);
SecCertificateRef AFUTAddTrustExternalRootCertificate(void);
SecCertificateRef AFUTSelfSignedCertificateWithoutDomain(void);
SecCertificateRef AFUTSelfSignedCertificateWithCommonNameDomain(void);
SecCertificateRef AFUTSelfSignedCertificateWithDNSNameDomain(void);
SecTrustRef AFUTTrustWithCertificate(SecCertificateRef certificate);
