<p align="center" >
  <img src="https://raw.github.com/AFNetworking/AFNetworking/assets/afnetworking-logo.png" alt="AFNetworking" title="AFNetworking">
</p>

[![Build Status](https://travis-ci.org/AFNetworking/AFNetworking.svg)](https://travis-ci.org/AFNetworking/AFNetworking)
[![codecov.io](https://codecov.io/github/AFNetworking/AFNetworking/coverage.svg?branch=master)](https://codecov.io/github/AFNetworking/AFNetworking?branch=master)
[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/AFNetworking.svg)](https://img.shields.io/cocoapods/v/AFNetworking.svg)
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Platform](https://img.shields.io/cocoapods/p/AFNetworking.svg?style=flat)](http://cocoadocs.org/docsets/AFNetworking)
[![Twitter](https://img.shields.io/badge/twitter-@AFNetworking-blue.svg?style=flat)](http://twitter.com/AFNetworking)

AFNetworking 为iOS, macOS, watchOS, 与 tvOS的不错网络库。 它内建在 [Foundation URL Loading System](http://developer.apple.com/library/mac/#documentation/Cocoa/Conceptual/URLLoadingSystem/URLLoadingSystem.html)基础之上, 在Cocoa基础上提供强大的高级网络抽象。拥有模块化构架与良好的设计，功能丰富易用的APIs。

也许最重要的特性是每天都有人使用和贡献AFNetworking的开发者群体。AFNetworking在iPhone、iPad和Mac上提供了一些最受欢迎和最受欢迎的应用程序。

你会很开心在后面项目选择AFNetworking，或者迁移到你存在的项目!

## 多国语言翻译

[英文README](README.md)

## 如何开始

- [下载 AFNetworking](https://github.com/AFNetworking/AFNetworking/archive/master.zip) 尝试应用到 Mac 与 iPhone 示例应用程序
- 拜读 ["入门" 指南](https://github.com/AFNetworking/AFNetworking/wiki/Getting-Started-with-AFNetworking), [FAQ](https://github.com/AFNetworking/AFNetworking/wiki/AFNetworking-FAQ), 或 [other articles on the Wiki](https://github.com/AFNetworking/AFNetworking/wiki)
- 全面查阅文档以查看在AFNetworking可用的所有APIs。
- 阅读 [AFNetworking 3.0 迁移指南](https://github.com/AFNetworking/AFNetworking/wiki/AFNetworking-3.0-Migration-Guide) ，了解从2.0开始体系结构的变化概述。

## 交流

- 如果你 **需要帮助**, 使用 [Stack Overflow](http://stackoverflow.com/questions/tagged/afnetworking). (标签 'afnetworking')
- 如果你想 **问通用问题**, 使用 [Stack Overflow](http://stackoverflow.com/questions/tagged/afnetworking).
- 如果你**发现bug**，且可提供可靠的复现步骤, 新建一个 issue.
- 如果你 **有新的特性request**, 新建一个 issue.
- 如果你 **想做贡献**, 提交 pull request.

## 安装

AFNetworking在项目中支持多种安装方式 。

## CocoaPods安装

[CocoaPods](http://cocoapods.org) 为 Objective-C 依赖管理器，自动简化项目中第三方库的使用，好比AFNetworking。查阅["入门" 指南获取更多信息，](https://github.com/AFNetworking/AFNetworking/wiki/Getting-Started-with-AFNetworking)可使用如下命令安装:

```bash
$ gem install cocoapods
```

> 编译AFNetworking 3.0.0+ 需要CocoaPods 0.39.0+ 以上版本。

#### Podfile

使用CocoaPods集成AFNetworking到你的 Xcode项目中，在相应 `Podfile`指定它:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '8.0'

target 'TargetName' do
pod 'AFNetworking', '~> 3.0'
end
```

然后, 执行如下命令:

```bash
$ pod install
```

### Carthage安装

[Carthage](https://github.com/Carthage/Carthage) 是一个分散式依赖管理器，它构建你的依赖关系并为你提供二进制框架。

使用 [Homebrew](http://brew.sh/)，可以用如下命令安装Carthage:

```bash
$ brew update
$ brew install carthage
```

使用Carthage集成AFNetworking到你的 Xcode项目中，在相应 `Cartfile`指定它:

```ogdl
github "AFNetworking/AFNetworking" ~> 3.0
```

运行 `carthage` 编译框架 ， 拖入 `AFNetworking.framework` 到你的 Xcode项目中。

## 要求

| AFNetworking 版本 | 最小 iOS Target | 最小 macOS Target | 最小 watchOS Target | 最小 tvOS Target |                           提示                           |
| :---------------: | :-------------: | :---------------: | :-----------------: | :--------------: | :------------------------------------------------------: |
|        3.x        |      iOS 7      |     OS X 10.9     |     watchOS 2.0     |     tvOS 9.0     | 要求Xcode 7+以上. `NSURLConnectionOperation` 支持已移掉. |
|   2.6 -> 2.6.3    |      iOS 7      |     OS X 10.9     |     watchOS 2.0     |       n/a        |                    要求Xcode 7+以上.                     |

(macOS 项目需支持 [64-bit with modern Cocoa runtime](https://developer.apple.com/library/mac/#documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtVersionsPlatforms.html)).

> 如果采用Swift编程? 尝试 [Alamofire](https://github.com/Alamofire/Alamofire) 更多 APIs集.

## 架构

 ![架构](https://github.com/ccworld1000/CCComposition/raw/master/CCAFNetworking.png)

### 附加功能

- `AFSecurityPolicy`
- `AFNetworkReachabilityManager`

## 用法

### AFURLSessionManager

`AFURLSessionManager` creates and manages an `NSURLSession` object based on a specified `NSURLSessionConfiguration` object, which conforms to `<NSURLSessionTaskDelegate>`, `<NSURLSessionDataDelegate>`, `<NSURLSessionDownloadDelegate>`, and `<NSURLSessionDelegate>`.

#### 创建 Download Task

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

#### 创建 Upload Task

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

#### 创建 Upload Task for a Multi-Part Request, with Progress

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

#### 创建 Data Task

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

------

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

```
GET http://example.com?foo=bar&baz[]=1&baz[]=2&baz[]=3
```

#### URL Form Parameter Encoding

```objective-c
[[AFHTTPRequestSerializer serializer] requestWithMethod:@"POST" URLString:URLString parameters:parameters error:nil];
```

```
POST http://example.com/
Content-Type: application/x-www-form-urlencoded

foo=bar&baz[]=1&baz[]=2&baz[]=3
```

#### JSON Parameter Encoding

```objective-c
[[AFJSONRequestSerializer serializer] requestWithMethod:@"POST" URLString:URLString parameters:parameters error:nil];
```

```
POST http://example.com/
Content-Type: application/json

{"foo": "bar", "baz": [1,2,3]}
```

------

### 网络可达性管理器

`AFNetworkReachabilityManager` monitors the reachability of domains, and addresses for both WWAN and WiFi network interfaces.

- Do not use Reachability to determine if the original request should be sent.
  - You should try to send it.
- You can use Reachability to determine when a request should be automatically retried.
  - Although it may still fail, a Reachability notification that the connectivity is available is a good time to retry something.
- Network reachability is a useful tool for determining why a request might have failed.
  - After a network request has failed, telling the user they're offline is better than giving them a more technical but accurate error, such as "request timed out."

也可查看 [WWDC 2012 session 706, "Networking Best Practices."](https://developer.apple.com/videos/play/wwdc2012-706/).

#### Shared Network Reachability

```objective-c
[[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
    NSLog(@"Reachability: %@", AFStringFromNetworkReachabilityStatus(status));
}];

[[AFNetworkReachabilityManager sharedManager] startMonitoring];
```

------

### 安全策略

`AFSecurityPolicy` evaluates server trust against pinned X.509 certificates and public keys over secure connections.

Adding pinned SSL certificates to your app helps prevent man-in-the-middle attacks and other vulnerabilities. Applications dealing with sensitive customer data or financial information are strongly encouraged to route all communication over an HTTPS connection with SSL pinning configured and enabled.

#### 允许SSL Certificates失效

```objective-c
AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
manager.securityPolicy.allowInvalidCertificates = YES; // not recommended for production
```

------

## 单元测试

AFNetworking中Tests子目录含有一套单元测试 。这些测试可以简单地在您想要测试的平台框架上执行测试操作。

## 致谢

 [Alamofire软件基金会](http://alamofire.org)拥有并维护AFNetworking。

AFNetworking 最初由 [Scott Raymond](https://github.com/sco/) 和 [Mattt Thompson](https://github.com/mattt/) 在开发 [Gowalla for iPhone](http://en.wikipedia.org/wiki/Gowalla)创建.

AFNetworking's logo由 [Alan Defibaugh](http://www.alandefibaugh.com/)设计。

最重要的是, 感谢AFNetworking's [日益增长的贡献者](https://github.com/AFNetworking/AFNetworking/contributors)。

### 安全披露

如果你确定AFNetworking有安全漏洞，你应该尽快发送邮件到 security@alamofire.org报告它。 请不要张贴到public issue 跟着它.

## 许可证

AFNetworking 采用 MIT license. 查阅 [LICENSE](https://github.com/AFNetworking/AFNetworking/blob/master/LICENSE) 细节.
