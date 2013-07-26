// AFJSONRequestOperationTests.m
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

#import "AFNetworkingTests.h"
#import "AFURLConnectionOperation.h"
#import "AFMockURLProtocol.h"
#import <objc/runtime.h>

static void class_swizzleSelector(Class class, SEL originalSelector, SEL newSelector)
{
    Method origMethod = class_getInstanceMethod(class, originalSelector);
    Method newMethod = class_getInstanceMethod(class, newSelector);
    if(class_addMethod(class, originalSelector, method_getImplementation(newMethod), method_getTypeEncoding(newMethod))) {
        class_replaceMethod(class, newSelector, method_getImplementation(origMethod), method_getTypeEncoding(origMethod));
    } else {
        method_exchangeImplementations(origMethod, newMethod);
    }
}



static NSArray *pinnedCertificates;

@interface AFURLConnectionOperation (AFURLConnectionOperationTests)

+ (NSArray *)__AFURLConnectionOperationTestsPinnedCertificates;
+ (NSArray *)__AFURLConnectionOperationTestsPinnedPublicKeys;
+ (void)setPinnedCertificates:(NSArray *)pinnedCertificates;

@end

@implementation AFURLConnectionOperation (AFURLConnectionOperationTests)

+ (NSArray *)__AFURLConnectionOperationTestsPinnedCertificates
{
    if (pinnedCertificates) {
        return pinnedCertificates;
    }
    
    return [self __AFURLConnectionOperationTestsPinnedCertificates];
}

+ (NSArray *)__AFURLConnectionOperationTestsPinnedPublicKeys
{
    NSArray *pinnedCertificates = [self __AFURLConnectionOperationTestsPinnedCertificates];
    NSMutableArray *publicKeys = [NSMutableArray arrayWithCapacity:[pinnedCertificates count]];
    
    for (NSData *data in pinnedCertificates) {
        SecCertificateRef allowedCertificate = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)data);
        NSParameterAssert(allowedCertificate);
        
        SecCertificateRef allowedCertificates[] = {allowedCertificate};
        CFArrayRef certificates = CFArrayCreate(NULL, (const void **)allowedCertificates, 1, NULL);
        
        SecPolicyRef policy = SecPolicyCreateBasicX509();
        SecTrustRef allowedTrust = NULL;
        OSStatus status = SecTrustCreateWithCertificates(certificates, policy, &allowedTrust);
        NSAssert(status == errSecSuccess, @"SecTrustCreateWithCertificates error: %ld", (long int)status);
        if (status == errSecSuccess && allowedTrust) {
            SecTrustResultType result = 0;
            status = SecTrustEvaluate(allowedTrust, &result);
            NSAssert(status == errSecSuccess, @"SecTrustEvaluate error: %ld", (long int)status);
            if (status == errSecSuccess) {
                SecKeyRef allowedPublicKey = SecTrustCopyPublicKey(allowedTrust);
                NSParameterAssert(allowedPublicKey);
                if (allowedPublicKey) {
                    [publicKeys addObject:(__bridge_transfer id)allowedPublicKey];
                }
            }
            
            CFRelease(allowedTrust);
        }
        
        CFRelease(policy);
        CFRelease(certificates);
        CFRelease(allowedCertificate);
    }
    
    return [[NSArray alloc] initWithArray:publicKeys];
}

+ (void)setPinnedCertificates:(NSArray *)thisPinnedCertificates
{
    pinnedCertificates = thisPinnedCertificates;
}

+ (void)load
{
    class_swizzleSelector(objc_getMetaClass("AFURLConnectionOperation"), @selector(pinnedCertificates), @selector(__AFURLConnectionOperationTestsPinnedCertificates));
    class_swizzleSelector(objc_getMetaClass("AFURLConnectionOperation"), @selector(pinnedPublicKeys), @selector(__AFURLConnectionOperationTestsPinnedPublicKeys));
}

@end



@interface AFURLConnectionOperationTests : SenTestCase
@property (readwrite, nonatomic, strong) NSURL *baseURL;
@end

@implementation AFURLConnectionOperationTests
@synthesize baseURL = _baseURL;

- (void)setUp {
    self.baseURL = [NSURL URLWithString:AFNetworkingTestsBaseURLString];
    [AFURLConnectionOperation setPinnedCertificates:nil];
}

- (void)tearDown {
    [AFURLConnectionOperation setPinnedCertificates:nil];
}

#pragma mark -

- (void)testThatAFURLConnectionOperationInvokesWillSendRequestForAuthenticationChallengeBlock {
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/path" relativeToURL:self.baseURL]];
    AFURLConnectionOperation *operation = [[AFURLConnectionOperation alloc] initWithRequest:request];
    
    __block BOOL willSendRequestForAuthenticationChallengeBlockInvoked = NO;
    [operation setWillSendRequestForAuthenticationChallengeBlock:^(NSURLConnection *connection, NSURLAuthenticationChallenge *challenge) {
        willSendRequestForAuthenticationChallengeBlockInvoked = YES;
    }];
    
    [AFMockURLProtocol handleNextRequestForURL:request.URL usingBlock:^(AFMockURLProtocol <AFMockURLProtocolProxy> * protocol) {
        
        void(^startOperation)(NSInvocation *invocation) = ^(NSInvocation *invocation) {
            __unsafe_unretained AFMockURLProtocol *protocol = nil;
            [invocation getArgument:&protocol atIndex:0];
            
            NSURLProtectionSpace *protectionSpace = [[NSURLProtectionSpace alloc] initWithHost:request.URL.host port:request.URL.port.integerValue protocol:request.URL.scheme realm:nil authenticationMethod:NSURLAuthenticationMethodDefault];
            NSURLAuthenticationChallenge *authenticationChallenge = [[NSURLAuthenticationChallenge alloc] initWithProtectionSpace:protectionSpace proposedCredential:nil previousFailureCount:0 failureResponse:nil error:nil sender:protocol];
            [protocol.client URLProtocol:protocol didReceiveAuthenticationChallenge:authenticationChallenge];
        };
        [[[protocol stub] andDo:startOperation] startLoading];
    }];
    
    [operation start];
    expect(willSendRequestForAuthenticationChallengeBlockInvoked).will.beTruthy();
    
    [operation cancel];
}

- (void)testThatAFURLConnectionOperationTrustsPublicKeysOfDerivedCertificates {
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://api.afnetworking.com/path"]];
    AFURLConnectionOperation *operation = [[AFURLConnectionOperation alloc] initWithRequest:request];
    operation.SSLPinningMode = AFSSLPinningModePublicKey;
    
    __block BOOL useCredentialInvoked = NO;
    
    NSURLProtectionSpace *protectionSpace = [[NSURLProtectionSpace alloc] initWithHost:request.URL.host port:request.URL.port.integerValue protocol:request.URL.scheme realm:nil authenticationMethod:NSURLAuthenticationMethodServerTrust];
    
    NSData *caCertificateData = [NSData dataWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"ca" ofType:@"cer"]];
    NSParameterAssert(caCertificateData);
    [AFURLConnectionOperation setPinnedCertificates:@[ caCertificateData ]];
    
    SecCertificateRef caCertificate = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)caCertificateData);
    NSParameterAssert(caCertificate);
    
    NSData *hostCertificateData = [NSData dataWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"api.afnetworking.com" ofType:@"cer"]];
    NSParameterAssert(hostCertificateData);
    
    SecCertificateRef hostCertificate = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)hostCertificateData);
    NSParameterAssert(hostCertificate);
    
    SecCertificateRef allowedCertificates[] = { hostCertificate, caCertificate };
    CFArrayRef certificates = CFArrayCreate(NULL, (const void **)allowedCertificates, 2, NULL);
    
    SecPolicyRef policy = SecPolicyCreateBasicX509();
    SecTrustRef trust = NULL;
    OSStatus status = SecTrustCreateWithCertificates(certificates, policy, &trust);
    NSAssert(status == errSecSuccess, @"SecTrustCreateWithCertificates error: %ld", (long int)status);
    
    SecTrustResultType result;
    status = SecTrustEvaluate(trust, &result);
    NSAssert(status == errSecSuccess, @"SecTrustEvaluate error: %ld", (long int)status);
    NSAssert(SecTrustGetCertificateCount(trust) == 2, @"trust has wrong certificate count");
    
    id mockedProtectionSpace = [OCMockObject partialMockForObject:protectionSpace];
    
    [[[mockedProtectionSpace stub] andDo:^(NSInvocation *invocation) {
        [invocation setReturnValue:(void *)&trust];
    }] serverTrust];
    
    AFMockURLProtocol *protocol = [[AFMockURLProtocol alloc] initWithRequest:request cachedResponse:nil client:nil];
    id mockedProtocol = [OCMockObject partialMockForObject:protocol];
    
    void(^useCredential)(NSInvocation *invocation) = ^(NSInvocation *invocation) {
        useCredentialInvoked = YES;
    };
    
    [[[mockedProtocol stub] andDo:useCredential] useCredential:OCMOCK_ANY forAuthenticationChallenge:OCMOCK_ANY];
    
    NSURLCredential *credential = [[NSURLCredential alloc] initWithTrust:trust];
    NSURLAuthenticationChallenge *authenticationChallenge = [[NSURLAuthenticationChallenge alloc] initWithProtectionSpace:protectionSpace proposedCredential:credential previousFailureCount:0 failureResponse:nil error:nil sender:mockedProtocol];
    [protocol.client URLProtocol:mockedProtocol didReceiveAuthenticationChallenge:authenticationChallenge];
    
    [operation connection:nil willSendRequestForAuthenticationChallenge:authenticationChallenge];
    
    CFRelease(trust);
    CFRelease(policy);
    CFRelease(certificates);
    CFRelease(caCertificate);
    CFRelease(hostCertificate);
    
    expect(useCredentialInvoked).will.beTruthy();
}

- (void)testThatAFURLConnectionOperationTrustsDerivedCertificates {
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://api.afnetworking.com/path"]];
    AFURLConnectionOperation *operation = [[AFURLConnectionOperation alloc] initWithRequest:request];
    operation.SSLPinningMode = AFSSLPinningModeCertificate;
    
    __block BOOL useCredentialInvoked = NO;
    
    NSURLProtectionSpace *protectionSpace = [[NSURLProtectionSpace alloc] initWithHost:request.URL.host port:request.URL.port.integerValue protocol:request.URL.scheme realm:nil authenticationMethod:NSURLAuthenticationMethodServerTrust];
    
    NSData *caCertificateData = [NSData dataWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"ca" ofType:@"cer"]];
    NSParameterAssert(caCertificateData);
    [AFURLConnectionOperation setPinnedCertificates:@[ caCertificateData ]];
    
    SecCertificateRef caCertificate = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)caCertificateData);
    NSParameterAssert(caCertificate);
    
    NSData *hostCertificateData = [NSData dataWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"api.afnetworking.com" ofType:@"cer"]];
    NSParameterAssert(hostCertificateData);
    
    SecCertificateRef hostCertificate = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)hostCertificateData);
    NSParameterAssert(hostCertificate);
    
    SecCertificateRef allowedCertificates[] = { hostCertificate, caCertificate };
    CFArrayRef certificates = CFArrayCreate(NULL, (const void **)allowedCertificates, 2, NULL);
    
    SecPolicyRef policy = SecPolicyCreateBasicX509();
    SecTrustRef trust = NULL;
    OSStatus status = SecTrustCreateWithCertificates(certificates, policy, &trust);
    NSAssert(status == errSecSuccess, @"SecTrustCreateWithCertificates error: %ld", (long int)status);
    
    SecTrustResultType result;
    status = SecTrustEvaluate(trust, &result);
    NSAssert(status == errSecSuccess, @"SecTrustEvaluate error: %ld", (long int)status);
    NSAssert(SecTrustGetCertificateCount(trust) == 2, @"trust has wrong certificate count");
    
    id mockedProtectionSpace = [OCMockObject partialMockForObject:protectionSpace];
    
    [[[mockedProtectionSpace stub] andDo:^(NSInvocation *invocation) {
        [invocation setReturnValue:(void *)&trust];
    }] serverTrust];
    
    AFMockURLProtocol *protocol = [[AFMockURLProtocol alloc] initWithRequest:request cachedResponse:nil client:nil];
    id mockedProtocol = [OCMockObject partialMockForObject:protocol];
    
    void(^useCredential)(NSInvocation *invocation) = ^(NSInvocation *invocation) {
        useCredentialInvoked = YES;
    };
    
    [[[mockedProtocol stub] andDo:useCredential] useCredential:OCMOCK_ANY forAuthenticationChallenge:OCMOCK_ANY];
    
    NSURLCredential *credential = [[NSURLCredential alloc] initWithTrust:trust];
    NSURLAuthenticationChallenge *authenticationChallenge = [[NSURLAuthenticationChallenge alloc] initWithProtectionSpace:protectionSpace proposedCredential:credential previousFailureCount:0 failureResponse:nil error:nil sender:mockedProtocol];
    [protocol.client URLProtocol:mockedProtocol didReceiveAuthenticationChallenge:authenticationChallenge];
    
    [operation connection:nil willSendRequestForAuthenticationChallenge:authenticationChallenge];
    
    CFRelease(trust);
    CFRelease(policy);
    CFRelease(certificates);
    CFRelease(caCertificate);
    CFRelease(hostCertificate);
    
    expect(useCredentialInvoked).will.beTruthy();
}

- (void)testThatAFURLConnectionOperationDoesTrustMatchingHostWithPinnedCertificate {
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://api.afnetworking.com/path"]];
    AFURLConnectionOperation *operation = [[AFURLConnectionOperation alloc] initWithRequest:request];
    operation.SSLPinningMode = AFSSLPinningModeCertificate;
    
    __block BOOL useCredentialInvoked = NO;
    
    NSURLProtectionSpace *protectionSpace = [[NSURLProtectionSpace alloc] initWithHost:request.URL.host port:request.URL.port.integerValue protocol:request.URL.scheme realm:nil authenticationMethod:NSURLAuthenticationMethodServerTrust];
    
    NSData *caCertificateData = [NSData dataWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"ca" ofType:@"cer"]];
    NSParameterAssert(caCertificateData);
    
    SecCertificateRef caCertificate = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)caCertificateData);
    NSParameterAssert(caCertificate);
    
    NSData *hostCertificateData = [NSData dataWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"api.afnetworking.com" ofType:@"cer"]];
    [AFURLConnectionOperation setPinnedCertificates:@[ hostCertificateData ]];
    NSParameterAssert(hostCertificateData);
    
    SecCertificateRef hostCertificate = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)hostCertificateData);
    NSParameterAssert(hostCertificate);
    
    SecCertificateRef allowedCertificates[] = { hostCertificate, caCertificate };
    CFArrayRef certificates = CFArrayCreate(NULL, (const void **)allowedCertificates, 2, NULL);
    
    SecPolicyRef policy = SecPolicyCreateBasicX509();
    SecTrustRef trust = NULL;
    OSStatus status = SecTrustCreateWithCertificates(certificates, policy, &trust);
    NSAssert(status == errSecSuccess, @"SecTrustCreateWithCertificates error: %ld", (long int)status);
    
    SecTrustResultType result;
    status = SecTrustEvaluate(trust, &result);
    NSAssert(status == errSecSuccess, @"SecTrustEvaluate error: %ld", (long int)status);
    NSAssert(SecTrustGetCertificateCount(trust) == 2, @"trust has wrong certificate count");
    
    id mockedProtectionSpace = [OCMockObject partialMockForObject:protectionSpace];
    
    [[[mockedProtectionSpace stub] andDo:^(NSInvocation *invocation) {
        [invocation setReturnValue:(void *)&trust];
    }] serverTrust];
    
    AFMockURLProtocol *protocol = [[AFMockURLProtocol alloc] initWithRequest:request cachedResponse:nil client:nil];
    id mockedProtocol = [OCMockObject partialMockForObject:protocol];
    
    void(^useCredential)(NSInvocation *invocation) = ^(NSInvocation *invocation) {
        useCredentialInvoked = YES;
    };
    
    [[[mockedProtocol stub] andDo:useCredential] useCredential:OCMOCK_ANY forAuthenticationChallenge:OCMOCK_ANY];
    
    NSURLCredential *credential = [[NSURLCredential alloc] initWithTrust:trust];
    NSURLAuthenticationChallenge *authenticationChallenge = [[NSURLAuthenticationChallenge alloc] initWithProtectionSpace:protectionSpace proposedCredential:credential previousFailureCount:0 failureResponse:nil error:nil sender:mockedProtocol];
    [protocol.client URLProtocol:mockedProtocol didReceiveAuthenticationChallenge:authenticationChallenge];
    
    [operation connection:nil willSendRequestForAuthenticationChallenge:authenticationChallenge];
    
    CFRelease(trust);
    CFRelease(policy);
    CFRelease(certificates);
    CFRelease(caCertificate);
    CFRelease(hostCertificate);
    
    expect(useCredentialInvoked).will.beTruthy();
}

- (void)testThatAFURLConnectionOperationDoesTrustWildcardHostWithPinnedCertificate {
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://api.afnetworking.com/path"]];
    AFURLConnectionOperation *operation = [[AFURLConnectionOperation alloc] initWithRequest:request];
    operation.SSLPinningMode = AFSSLPinningModeCertificate;
    
    __block BOOL useCredentialInvoked = NO;
    
    NSURLProtectionSpace *protectionSpace = [[NSURLProtectionSpace alloc] initWithHost:request.URL.host port:request.URL.port.integerValue protocol:request.URL.scheme realm:nil authenticationMethod:NSURLAuthenticationMethodServerTrust];
    
    NSData *caCertificateData = [NSData dataWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"ca" ofType:@"cer"]];
    NSParameterAssert(caCertificateData);
    
    SecCertificateRef caCertificate = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)caCertificateData);
    NSParameterAssert(caCertificate);
    
    NSData *hostCertificateData = [NSData dataWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"*.afnetworking.com" ofType:@"cer"]];
    [AFURLConnectionOperation setPinnedCertificates:@[ hostCertificateData ]];
    NSParameterAssert(hostCertificateData);
    
    SecCertificateRef hostCertificate = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)hostCertificateData);
    NSParameterAssert(hostCertificate);
    
    SecCertificateRef allowedCertificates[] = { hostCertificate, caCertificate };
    CFArrayRef certificates = CFArrayCreate(NULL, (const void **)allowedCertificates, 2, NULL);
    
    SecPolicyRef policy = SecPolicyCreateBasicX509();
    SecTrustRef trust = NULL;
    OSStatus status = SecTrustCreateWithCertificates(certificates, policy, &trust);
    NSAssert(status == errSecSuccess, @"SecTrustCreateWithCertificates error: %ld", (long int)status);
    
    SecTrustResultType result;
    status = SecTrustEvaluate(trust, &result);
    NSAssert(status == errSecSuccess, @"SecTrustEvaluate error: %ld", (long int)status);
    NSAssert(SecTrustGetCertificateCount(trust) == 2, @"trust has wrong certificate count");
    
    id mockedProtectionSpace = [OCMockObject partialMockForObject:protectionSpace];
    
    [[[mockedProtectionSpace stub] andDo:^(NSInvocation *invocation) {
        [invocation setReturnValue:(void *)&trust];
    }] serverTrust];
    
    AFMockURLProtocol *protocol = [[AFMockURLProtocol alloc] initWithRequest:request cachedResponse:nil client:nil];
    id mockedProtocol = [OCMockObject partialMockForObject:protocol];
    
    void(^useCredential)(NSInvocation *invocation) = ^(NSInvocation *invocation) {
        useCredentialInvoked = YES;
    };
    
    [[[mockedProtocol stub] andDo:useCredential] useCredential:OCMOCK_ANY forAuthenticationChallenge:OCMOCK_ANY];
    
    NSURLCredential *credential = [[NSURLCredential alloc] initWithTrust:trust];
    NSURLAuthenticationChallenge *authenticationChallenge = [[NSURLAuthenticationChallenge alloc] initWithProtectionSpace:protectionSpace proposedCredential:credential previousFailureCount:0 failureResponse:nil error:nil sender:mockedProtocol];
    [protocol.client URLProtocol:mockedProtocol didReceiveAuthenticationChallenge:authenticationChallenge];
    
    [operation connection:nil willSendRequestForAuthenticationChallenge:authenticationChallenge];
    
    CFRelease(trust);
    CFRelease(policy);
    CFRelease(certificates);
    CFRelease(caCertificate);
    CFRelease(hostCertificate);
    
    expect(useCredentialInvoked).will.beTruthy();
}

- (void)testThatAFURLConnectionOperationDoesTrustMatchingHostWithPinnedPublicKey {
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://api.afnetworking.com/path"]];
    AFURLConnectionOperation *operation = [[AFURLConnectionOperation alloc] initWithRequest:request];
    operation.SSLPinningMode = AFSSLPinningModePublicKey;
    
    __block BOOL useCredentialInvoked = NO;
    
    NSURLProtectionSpace *protectionSpace = [[NSURLProtectionSpace alloc] initWithHost:request.URL.host port:request.URL.port.integerValue protocol:request.URL.scheme realm:nil authenticationMethod:NSURLAuthenticationMethodServerTrust];
    
    NSData *caCertificateData = [NSData dataWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"ca" ofType:@"cer"]];
    NSParameterAssert(caCertificateData);
    
    SecCertificateRef caCertificate = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)caCertificateData);
    NSParameterAssert(caCertificate);
    
    NSData *hostCertificateData = [NSData dataWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"api.afnetworking.com" ofType:@"cer"]];
    [AFURLConnectionOperation setPinnedCertificates:@[ hostCertificateData ]];
    NSParameterAssert(hostCertificateData);
    
    SecCertificateRef hostCertificate = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)hostCertificateData);
    NSParameterAssert(hostCertificate);
    
    SecCertificateRef allowedCertificates[] = { hostCertificate, caCertificate };
    CFArrayRef certificates = CFArrayCreate(NULL, (const void **)allowedCertificates, 2, NULL);
    
    SecPolicyRef policy = SecPolicyCreateBasicX509();
    SecTrustRef trust = NULL;
    OSStatus status = SecTrustCreateWithCertificates(certificates, policy, &trust);
    NSAssert(status == errSecSuccess, @"SecTrustCreateWithCertificates error: %ld", (long int)status);
    
    SecTrustResultType result;
    status = SecTrustEvaluate(trust, &result);
    NSAssert(status == errSecSuccess, @"SecTrustEvaluate error: %ld", (long int)status);
    NSAssert(SecTrustGetCertificateCount(trust) == 2, @"trust has wrong certificate count");
    
    id mockedProtectionSpace = [OCMockObject partialMockForObject:protectionSpace];
    
    [[[mockedProtectionSpace stub] andDo:^(NSInvocation *invocation) {
        [invocation setReturnValue:(void *)&trust];
    }] serverTrust];
    
    AFMockURLProtocol *protocol = [[AFMockURLProtocol alloc] initWithRequest:request cachedResponse:nil client:nil];
    id mockedProtocol = [OCMockObject partialMockForObject:protocol];
    
    void(^useCredential)(NSInvocation *invocation) = ^(NSInvocation *invocation) {
        useCredentialInvoked = YES;
    };
    
    [[[mockedProtocol stub] andDo:useCredential] useCredential:OCMOCK_ANY forAuthenticationChallenge:OCMOCK_ANY];
    
    NSURLCredential *credential = [[NSURLCredential alloc] initWithTrust:trust];
    NSURLAuthenticationChallenge *authenticationChallenge = [[NSURLAuthenticationChallenge alloc] initWithProtectionSpace:protectionSpace proposedCredential:credential previousFailureCount:0 failureResponse:nil error:nil sender:mockedProtocol];
    [protocol.client URLProtocol:mockedProtocol didReceiveAuthenticationChallenge:authenticationChallenge];
    
    [operation connection:nil willSendRequestForAuthenticationChallenge:authenticationChallenge];
    
    CFRelease(trust);
    CFRelease(policy);
    CFRelease(certificates);
    CFRelease(caCertificate);
    CFRelease(hostCertificate);
    
    expect(useCredentialInvoked).will.beTruthy();
}

- (void)testThatAFURLConnectionOperationDoesTrustWildcardHostWithPinnedPublicKey {
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://api.afnetworking.com/path"]];
    AFURLConnectionOperation *operation = [[AFURLConnectionOperation alloc] initWithRequest:request];
    operation.SSLPinningMode = AFSSLPinningModePublicKey;
    
    __block BOOL useCredentialInvoked = NO;
    
    NSURLProtectionSpace *protectionSpace = [[NSURLProtectionSpace alloc] initWithHost:request.URL.host port:request.URL.port.integerValue protocol:request.URL.scheme realm:nil authenticationMethod:NSURLAuthenticationMethodServerTrust];
    
    NSData *caCertificateData = [NSData dataWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"ca" ofType:@"cer"]];
    NSParameterAssert(caCertificateData);
    
    SecCertificateRef caCertificate = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)caCertificateData);
    NSParameterAssert(caCertificate);
    
    NSData *hostCertificateData = [NSData dataWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"*.afnetworking.com" ofType:@"cer"]];
    [AFURLConnectionOperation setPinnedCertificates:@[ hostCertificateData ]];
    NSParameterAssert(hostCertificateData);
    
    SecCertificateRef hostCertificate = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)hostCertificateData);
    NSParameterAssert(hostCertificate);
    
    SecCertificateRef allowedCertificates[] = { hostCertificate, caCertificate };
    CFArrayRef certificates = CFArrayCreate(NULL, (const void **)allowedCertificates, 2, NULL);
    
    SecPolicyRef policy = SecPolicyCreateBasicX509();
    SecTrustRef trust = NULL;
    OSStatus status = SecTrustCreateWithCertificates(certificates, policy, &trust);
    NSAssert(status == errSecSuccess, @"SecTrustCreateWithCertificates error: %ld", (long int)status);
    
    SecTrustResultType result;
    status = SecTrustEvaluate(trust, &result);
    NSAssert(status == errSecSuccess, @"SecTrustEvaluate error: %ld", (long int)status);
    NSAssert(SecTrustGetCertificateCount(trust) == 2, @"trust has wrong certificate count");
    
    id mockedProtectionSpace = [OCMockObject partialMockForObject:protectionSpace];
    
    [[[mockedProtectionSpace stub] andDo:^(NSInvocation *invocation) {
        [invocation setReturnValue:(void *)&trust];
    }] serverTrust];
    
    AFMockURLProtocol *protocol = [[AFMockURLProtocol alloc] initWithRequest:request cachedResponse:nil client:nil];
    id mockedProtocol = [OCMockObject partialMockForObject:protocol];
    
    void(^useCredential)(NSInvocation *invocation) = ^(NSInvocation *invocation) {
        useCredentialInvoked = YES;
    };
    
    [[[mockedProtocol stub] andDo:useCredential] useCredential:OCMOCK_ANY forAuthenticationChallenge:OCMOCK_ANY];
    
    NSURLCredential *credential = [[NSURLCredential alloc] initWithTrust:trust];
    NSURLAuthenticationChallenge *authenticationChallenge = [[NSURLAuthenticationChallenge alloc] initWithProtectionSpace:protectionSpace proposedCredential:credential previousFailureCount:0 failureResponse:nil error:nil sender:mockedProtocol];
    [protocol.client URLProtocol:mockedProtocol didReceiveAuthenticationChallenge:authenticationChallenge];
    
    [operation connection:nil willSendRequestForAuthenticationChallenge:authenticationChallenge];
    
    CFRelease(trust);
    CFRelease(policy);
    CFRelease(certificates);
    CFRelease(caCertificate);
    CFRelease(hostCertificate);
    
    expect(useCredentialInvoked).will.beTruthy();
}

- (void)testThatAFURLConnectionOperationDoesntInvalidHostNotMatchingCertificatesHost {
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://ping.afnetworking.com/path"]];
    AFURLConnectionOperation *operation = [[AFURLConnectionOperation alloc] initWithRequest:request];
    operation.SSLPinningMode = AFSSLPinningModePublicKey;
    
    __block BOOL cancelAuthenticationChallengeInvoked = NO;
    
    NSURLProtectionSpace *protectionSpace = [[NSURLProtectionSpace alloc] initWithHost:request.URL.host port:request.URL.port.integerValue protocol:request.URL.scheme realm:nil authenticationMethod:NSURLAuthenticationMethodServerTrust];
    
    NSData *caCertificateData = [NSData dataWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"ca" ofType:@"cer"]];
    NSParameterAssert(caCertificateData);
    
    SecCertificateRef caCertificate = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)caCertificateData);
    NSParameterAssert(caCertificate);
    
    NSData *hostCertificateData = [NSData dataWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"api.afnetworking.com" ofType:@"cer"]];
    [AFURLConnectionOperation setPinnedCertificates:@[ hostCertificateData ]];
    NSParameterAssert(hostCertificateData);
    
    SecCertificateRef hostCertificate = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)hostCertificateData);
    NSParameterAssert(hostCertificate);
    
    SecCertificateRef allowedCertificates[] = { hostCertificate, caCertificate };
    CFArrayRef certificates = CFArrayCreate(NULL, (const void **)allowedCertificates, 2, NULL);
    
    SecPolicyRef policy = SecPolicyCreateBasicX509();
    SecTrustRef trust = NULL;
    OSStatus status = SecTrustCreateWithCertificates(certificates, policy, &trust);
    NSAssert(status == errSecSuccess, @"SecTrustCreateWithCertificates error: %ld", (long int)status);
    
    SecTrustResultType result;
    status = SecTrustEvaluate(trust, &result);
    NSAssert(status == errSecSuccess, @"SecTrustEvaluate error: %ld", (long int)status);
    NSAssert(SecTrustGetCertificateCount(trust) == 2, @"trust has wrong certificate count");
    
    id mockedProtectionSpace = [OCMockObject partialMockForObject:protectionSpace];
    
    [[[mockedProtectionSpace stub] andDo:^(NSInvocation *invocation) {
        [invocation setReturnValue:(void *)&trust];
    }] serverTrust];
    
    AFMockURLProtocol *protocol = [[AFMockURLProtocol alloc] initWithRequest:request cachedResponse:nil client:nil];
    id mockedProtocol = [OCMockObject partialMockForObject:protocol];
    
    void(^useCredential)(NSInvocation *invocation) = ^(NSInvocation *invocation) {
        cancelAuthenticationChallengeInvoked = YES;
    };
    
    [[[mockedProtocol stub] andDo:useCredential] cancelAuthenticationChallenge:OCMOCK_ANY];
    
    NSURLCredential *credential = [[NSURLCredential alloc] initWithTrust:trust];
    NSURLAuthenticationChallenge *authenticationChallenge = [[NSURLAuthenticationChallenge alloc] initWithProtectionSpace:protectionSpace proposedCredential:credential previousFailureCount:0 failureResponse:nil error:nil sender:mockedProtocol];
    [protocol.client URLProtocol:mockedProtocol didReceiveAuthenticationChallenge:authenticationChallenge];
    
    [operation connection:nil willSendRequestForAuthenticationChallenge:authenticationChallenge];
    
    CFRelease(trust);
    CFRelease(policy);
    CFRelease(certificates);
    CFRelease(caCertificate);
    CFRelease(hostCertificate);
    
    expect(cancelAuthenticationChallengeInvoked).will.beTruthy();
}

- (void)testThatAFURLConnectionOperationDoesntInvalidHostNotMatchingWildcardHost {
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://api.sparrow-labs.com/path"]];
    AFURLConnectionOperation *operation = [[AFURLConnectionOperation alloc] initWithRequest:request];
    operation.SSLPinningMode = AFSSLPinningModePublicKey;
    
    __block BOOL cancelAuthenticationChallengeInvoked = NO;
    
    NSURLProtectionSpace *protectionSpace = [[NSURLProtectionSpace alloc] initWithHost:request.URL.host port:request.URL.port.integerValue protocol:request.URL.scheme realm:nil authenticationMethod:NSURLAuthenticationMethodServerTrust];
    
    NSData *caCertificateData = [NSData dataWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"ca" ofType:@"cer"]];
    NSParameterAssert(caCertificateData);
    
    SecCertificateRef caCertificate = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)caCertificateData);
    NSParameterAssert(caCertificate);
    
    NSData *hostCertificateData = [NSData dataWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"*.afnetworking.com" ofType:@"cer"]];
    [AFURLConnectionOperation setPinnedCertificates:@[ hostCertificateData ]];
    NSParameterAssert(hostCertificateData);
    
    SecCertificateRef hostCertificate = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)hostCertificateData);
    NSParameterAssert(hostCertificate);
    
    SecCertificateRef allowedCertificates[] = { hostCertificate, caCertificate };
    CFArrayRef certificates = CFArrayCreate(NULL, (const void **)allowedCertificates, 2, NULL);
    
    SecPolicyRef policy = SecPolicyCreateBasicX509();
    SecTrustRef trust = NULL;
    OSStatus status = SecTrustCreateWithCertificates(certificates, policy, &trust);
    NSAssert(status == errSecSuccess, @"SecTrustCreateWithCertificates error: %ld", (long int)status);
    
    SecTrustResultType result;
    status = SecTrustEvaluate(trust, &result);
    NSAssert(status == errSecSuccess, @"SecTrustEvaluate error: %ld", (long int)status);
    NSAssert(SecTrustGetCertificateCount(trust) == 2, @"trust has wrong certificate count");
    
    id mockedProtectionSpace = [OCMockObject partialMockForObject:protectionSpace];
    
    [[[mockedProtectionSpace stub] andDo:^(NSInvocation *invocation) {
        [invocation setReturnValue:(void *)&trust];
    }] serverTrust];
    
    AFMockURLProtocol *protocol = [[AFMockURLProtocol alloc] initWithRequest:request cachedResponse:nil client:nil];
    id mockedProtocol = [OCMockObject partialMockForObject:protocol];
    
    void(^useCredential)(NSInvocation *invocation) = ^(NSInvocation *invocation) {
        cancelAuthenticationChallengeInvoked = YES;
    };
    
    [[[mockedProtocol stub] andDo:useCredential] cancelAuthenticationChallenge:OCMOCK_ANY];
    
    NSURLCredential *credential = [[NSURLCredential alloc] initWithTrust:trust];
    NSURLAuthenticationChallenge *authenticationChallenge = [[NSURLAuthenticationChallenge alloc] initWithProtectionSpace:protectionSpace proposedCredential:credential previousFailureCount:0 failureResponse:nil error:nil sender:mockedProtocol];
    [protocol.client URLProtocol:mockedProtocol didReceiveAuthenticationChallenge:authenticationChallenge];
    
    [operation connection:nil willSendRequestForAuthenticationChallenge:authenticationChallenge];
    
    CFRelease(trust);
    CFRelease(policy);
    CFRelease(certificates);
    CFRelease(caCertificate);
    CFRelease(hostCertificate);
    
    expect(cancelAuthenticationChallengeInvoked).will.beTruthy();
}

@end
