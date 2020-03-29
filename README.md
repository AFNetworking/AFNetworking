<p align="center" >
  <img src="https://raw.github.com/AFNetworking/AFNetworking/assets/afnetworking-logo.png" alt="AFNetworking" title="AFNetworking">
</p>

[![Build Status](https://github.com/AFNetworking/AFNetworking/workflows/AFNetworking%20CI/badge.svg?branch=master)](https://github.com/AFNetworking/AFNetworking/actions)
[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/AFNetworking.svg)](https://img.shields.io/cocoapods/v/AFNetworking.svg)
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Platform](https://img.shields.io/cocoapods/p/AFNetworking.svg?style=flat)](http://cocoadocs.org/docsets/AFNetworking)
[![Twitter](https://img.shields.io/badge/twitter-@AFNetworking-blue.svg?style=flat)](http://twitter.com/AFNetworking)

AFNetworking is a delightful networking library for iOS, macOS, watchOS, and tvOS. It's built on top of the [Foundation URL Loading System](https://developer.apple.com/documentation/foundation/url_loading_system), extending the powerful high-level networking abstractions built into Cocoa. It has a modular architecture with well-designed, feature-rich APIs that are a joy to use.

Perhaps the most important feature of all, however, is the amazing community of developers who use and contribute to AFNetworking every day. AFNetworking powers some of the most popular and critically-acclaimed apps on the iPhone, iPad, and Mac.

## How To Get Started

- [Download AFNetworking](https://github.com/AFNetworking/AFNetworking/archive/master.zip) and try out the included Mac and iPhone example apps
- Read the ["Getting Started" guide](https://github.com/AFNetworking/AFNetworking/wiki/Getting-Started-with-AFNetworking), [FAQ](https://github.com/AFNetworking/AFNetworking/wiki/AFNetworking-FAQ), or [other articles on the Wiki](https://github.com/AFNetworking/AFNetworking/wiki)
- Check out the [documentation](http://cocoadocs.org/docsets/AFNetworking/) for a comprehensive look at all of the APIs available in AFNetworking

## Communication

- If you **need help**, use [Stack Overflow](http://stackoverflow.com/questions/tagged/afnetworking). (Tag 'afnetworking')
- If you'd like to **ask a general question**, use [Stack Overflow](http://stackoverflow.com/questions/tagged/afnetworking).
- If you **found a bug**, _and can provide steps to reliably reproduce it_, open an issue.
- If you **have a feature request**, open an issue.
- If you **want to contribute**, submit a pull request.

## Installation
AFNetworking supports multiple methods for installing the library in a project.

## Installation with CocoaPods

To integrate AFNetworking into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
pod 'AFNetworking', '~> 4.0'
```

### Installation with Swift Package Manager

Once you have your Swift package set up, adding AFNetworking as a dependency is as easy as adding it to the `dependencies` value of your `Package.swift`.

```swift
dependencies: [
    .package(url: "https://github.com/AFNetworking/AFNetworking.git", .upToNextMajor(from: "4.0.0"))
]
```

> Note: AFNetworking's Swift package does not include it's UIKit extensions.

### Installation with Carthage

[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that builds your dependencies and provides you with binary frameworks. To integrate AFNetworking, add the following to your `Cartfile`.

```ogdl
github "AFNetworking/AFNetworking" ~> 4.0
```

## Requirements

| AFNetworking Version | Minimum iOS Target  | Minimum macOS Target  | Minimum watchOS Target  | Minimum tvOS Target  |                                   Notes                                   |
|:--------------------:|:---------------------------:|:----------------------------:|:----------------------------:|:----------------------------:|:-------------------------------------------------------------------------:|
| 4.x | iOS 9 | macOS 10.10 | watchOS 2.0 | tvOS 9.0 | Xcode 11+ is required. |
| 3.x | iOS 7 | OS X 10.9 | watchOS 2.0 | tvOS 9.0 | Xcode 7+ is required. `NSURLConnectionOperation` support has been removed. |
| 2.6 -> 2.6.3 | iOS 7 | OS X 10.9 | watchOS 2.0 | n/a | Xcode 7+ is required. |
| 2.0 -> 2.5.4 | iOS 6 | OS X 10.8 | n/a | n/a | Xcode 5+ is required. `NSURLSession` subspec requires iOS 7 or OS X 10.9. |
| 1.x | iOS 5 | Mac OS X 10.7 | n/a | n/a |
| 0.10.x | iOS 4 | Mac OS X 10.6 | n/a | n/a |

(macOS projects must support [64-bit with modern Cocoa runtime](https://developer.apple.com/library/mac/#documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtVersionsPlatforms.html)).

> Programming in Swift? Try [Alamofire](https://github.com/Alamofire/Alamofire) for a more conventional set of APIs.

## Architecture

### NSURLSession

- `AFURLSessionManager`
- `AFHTTPSessionManager`

### Serialization

* `<AFURLRequestSerialization>`
  - `AFHTTPRequestSerializer`
  - `AFJSONRequestSerializer`
  - `AFPropertyListRequestSerializer`
* `<AFURLResponseSerialization>`
  - `AFHTTPResponseSerializer`
  - `AFJSONResponseSerializer`
  - `AFXMLParserResponseSerializer`
  - `AFXMLDocumentResponseSerializer` _(macOS)_
  - `AFPropertyListResponseSerializer`
  - `AFImageResponseSerializer`
  - `AFCompoundResponseSerializer`

### Additional Functionality

- `AFSecurityPolicy`
- `AFNetworkReachabilityManager`

## Usage

### AFURLSessionManager

`AFURLSessionManager` creates and manages an `NSURLSession` object based on a specified `NSURLSessionConfiguration` object, which conforms to `<NSURLSessionTaskDelegate>`, `<NSURLSessionDataDelegate>`, `<NSURLSessionDownloadDelegate>`, and `<NSURLSessionDelegate>`.

#### Creating a Download Task

```objective-c
NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];

NSURL *URL = [NSURL URLWithString:@"http://example.com/download.zip"];
NSURLRequest *request = [NSURLRequest requestWithURL:URL];

NSURLSessionDownloadTask *downloadTask = [manager downloadTaskWithRequest:request progress:nil destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
    NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
    return [documentsDirectoryURL URLByAppendingPathComponent:[response suggestedFilename]];
} completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
    NSLog(@"File downloaded to: %@", filePath);
}];
[downloadTask resume];
```

#### Creating an Upload Task

```objective-c
NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];

NSURL *URL = [NSURL URLWithString:@"http://example.com/upload"];
NSURLRequest *request = [NSURLRequest requestWithURL:URL];

NSURL *filePath = [NSURL fileURLWithPath:@"file://path/to/image.png"];
NSURLSessionUploadTask *uploadTask = [manager uploadTaskWithRequest:request fromFile:filePath progress:nil completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
    if (error) {
        NSLog(@"Error: %@", error);
    } else {
        NSLog(@"Success: %@ %@", response, responseObject);
    }
}];
[uploadTask resume];
```

#### Creating an Upload Task for a Multi-Part Request, with Progress

```objective-c
NSMutableURLRequest *request = [[AFHTTPRequestSerializer serializer] multipartFormRequestWithMethod:@"POST" URLString:@"http://example.com/upload" parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        [formData appendPartWithFileURL:[NSURL fileURLWithPath:@"file://path/to/image.jpg"] name:@"file" fileName:@"filename.jpg" mimeType:@"image/jpeg" error:nil];
    } error:nil];

AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];

NSURLSessionUploadTask *uploadTask;
uploadTask = [manager
              uploadTaskWithStreamedRequest:request
              progress:^(NSProgress * _Nonnull uploadProgress) {
                  // This is not called back on the main queue.
                  // You are responsible for dispatching to the main queue for UI updates
                  dispatch_async(dispatch_get_main_queue(), ^{
                      //Update the progress view
                      [progressView setProgress:uploadProgress.fractionCompleted];
                  });
              }
              completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
                  if (error) {
                      NSLog(@"Error: %@", error);
                  } else {
                      NSLog(@"%@ %@", response, responseObject);
                  }
              }];

[uploadTask resume];
```

#### Creating a Data Task

```objective-c
NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];

NSURL *URL = [NSURL URLWithString:@"http://httpbin.org/get"];
NSURLRequest *request = [NSURLRequest requestWithURL:URL];

NSURLSessionDataTask *dataTask = [manager dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
    if (error) {
        NSLog(@"Error: %@", error);
    } else {
        NSLog(@"%@ %@", response, responseObject);
    }
}];
[dataTask resume];
```

---

### Request Serialization

Request serializers create requests from URL strings, encoding parameters as either a query string or HTTP body.

```objective-c
NSString *URLString = @"http://example.com";
NSDictionary *parameters = @{@"foo": @"bar", @"baz": @[@1, @2, @3]};
```

#### Query String Parameter Encoding

```objective-c
[[AFHTTPRequestSerializer serializer] requestWithMethod:@"GET" URLString:URLString parameters:parameters error:nil];
```

    GET http://example.com?foo=bar&baz[]=1&baz[]=2&baz[]=3

#### URL Form Parameter Encoding

```objective-c
[[AFHTTPRequestSerializer serializer] requestWithMethod:@"POST" URLString:URLString parameters:parameters error:nil];
```

    POST http://example.com/
    Content-Type: application/x-www-form-urlencoded

    foo=bar&baz[]=1&baz[]=2&baz[]=3

#### JSON Parameter Encoding

```objective-c
[[AFJSONRequestSerializer serializer] requestWithMethod:@"POST" URLString:URLString parameters:parameters error:nil];
```

    POST http://example.com/
    Content-Type: application/json

    {"foo": "bar", "baz": [1,2,3]}

---

### Network Reachability Manager

`AFNetworkReachabilityManager` monitors the reachability of domains, and addresses for both WWAN and WiFi network interfaces.

* Do not use Reachability to determine if the original request should be sent.
	* You should try to send it.
* You can use Reachability to determine when a request should be automatically retried.
	* Although it may still fail, a Reachability notification that the connectivity is available is a good time to retry something.
* Network reachability is a useful tool for determining why a request might have failed.
	* After a network request has failed, telling the user they're offline is better than giving them a more technical but accurate error, such as "request timed out."

See also [WWDC 2012 session 706, "Networking Best Practices."](https://developer.apple.com/videos/play/wwdc2012-706/).

#### Shared Network Reachability

```objective-c
[[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
    NSLog(@"Reachability: %@", AFStringFromNetworkReachabilityStatus(status));
}];

[[AFNetworkReachabilityManager sharedManager] startMonitoring];
```

---

### Security Policy

`AFSecurityPolicy` evaluates server trust against pinned X.509 certificates and public keys over secure connections.

Adding pinned SSL certificates to your app helps prevent man-in-the-middle attacks and other vulnerabilities. Applications dealing with sensitive customer data or financial information are strongly encouraged to route all communication over an HTTPS connection with SSL pinning configured and enabled.

#### Allowing Invalid SSL Certificates

```objective-c
AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
manager.securityPolicy.allowInvalidCertificates = YES; // not recommended for production
```

---

## Unit Tests

AFNetworking includes a suite of unit tests within the Tests subdirectory. These tests can be run simply be executed the test action on the platform framework you would like to test.

## Credits

AFNetworking is owned and maintained by the [Alamofire Software Foundation](http://alamofire.org).

AFNetworking was originally created by [Scott Raymond](https://github.com/sco/) and [Mattt Thompson](https://github.com/mattt/) in the development of [Gowalla for iPhone](http://en.wikipedia.org/wiki/Gowalla).

AFNetworking's logo was designed by [Alan Defibaugh](http://www.alandefibaugh.com/).

And most of all, thanks to AFNetworking's [growing list of contributors](https://github.com/AFNetworking/AFNetworking/contributors).

### Security Disclosure

If you believe you have identified a security vulnerability with AFNetworking, you should report it as soon as possible via email to security@alamofire.org. Please do not post it to a public issue tracker.

## License

AFNetworking is released under the MIT license. See [LICENSE](https://github.com/AFNetworking/AFNetworking/blob/master/LICENSE) for details.
