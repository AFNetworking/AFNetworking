<p align="center" >
  <img src="https://raw.github.com/AFNetworking/AFNetworking/assets/afnetworking-logo.png" alt="AFNetworking" title="AFNetworking">
</p>

[![Build Status](https://github.com/AFNetworking/AFNetworking/workflows/AFNetworking%20CI/badge.svg?branch=master)](https://github.com/AFNetworking/AFNetworking/actions)
[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/AFNetworking.svg)](https://img.shields.io/cocoapods/v/AFNetworking.svg)
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Platform](https://img.shields.io/cocoapods/p/AFNetworking.svg?style=flat)](http://cocoadocs.org/docsets/AFNetworking)
[![Twitter](https://img.shields.io/badge/twitter-@AFNetworking-blue.svg?style=flat)](http://twitter.com/AFNetworking)

AFNetworking是一个在 iOS、macOS、 watchOS、 和tvOS平台中非常有趣的网络库。它建立在 [Foundation URL Loading System](https://developer.apple.com/documentation/foundation/url_loading_system),                                                                                                            的基础上，并扩展了Cocoa中内置的强大的高级网络抽象化。它具有模块化的体系结构，具有精心设计的功能丰富的API，使用起来即方便又有意思。

然而最重要的是那些每天使用并为AFNetworking做出卓越贡献的开发人员。那些在iPhone，iPad和Mac上最受欢迎和广受好评的应用程序都使用AFNetworking作为他们的网络库。

## 接入指南参考

- [下载 AFNetworking](https://github.com/AFNetworking/AFNetworking/archive/master.zip)并且内有Mac和iPhone的示例应用。
- 阅读["Getting Started"guide](https://github.com/AFNetworking/AFNetworking/wiki/Getting-Started-with-AFNetworking), [FAQ](https://github.com/AFNetworking/AFNetworking/wiki/AFNetworking-FAQ), 或 [other articles on the Wiki](https://github.com/AFNetworking/AFNetworking/wiki)

## 如何沟通

- 如果你 **需要帮助**, 使用 [Stack Overflow](http://stackoverflow.com/questions/tagged/afnetworking). (Tag'afnetworking')
- 如果你想要 **问一般的问题**, 使用 [Stack Overflow](http://stackoverflow.com/questions/tagged/afnetworking).
- 如果你 **发现一个bug**, _并且可以提供复现步骤_, 在github中开启一个问题。
- 如果你 **有新功能的要求**, 在github中开启一个问题。
- 如果你 **想要有所贡献**, 提交并推一个请求。

## 安装
AFNetworking支持多种在项目中安装库的方法。

## 使用CocoaPods安装

要使用CocoaPods将AFNetworking集成到Xcode项目中，请在`Podfile`中指定它：

```ruby
pod 'AFNetworking', '~> 4.0'
```

### 使用Swift Package Manager安装

设置Swift包后，将AFNetworking添加为依赖关系就像将它添加到Package.swift的依赖关系值一样简单。

```swift
dependencies: [
    .package(url: "https://github.com/AFNetworking/AFNetworking.git", .upToNextMajor(from: "4.0.0"))
]
```

> 注意：AFNetworking的Swift软件包不包括它的UIKit扩展。

### 使用Carthage安装

[Carthage](https://github.com/Carthage/Carthage) 是一个分散的依赖性管理器，可构建您的依赖性并为您提供二进制框架。要集成AFNetworking，要集成AFNetworking，请将以下内容添加到`Cartfile`中。

```ogdl
github "AFNetworking/AFNetworking" ~> 4.0
```

## 要求

| AFNetworking Version | Minimum iOS Target  | Minimum macOS Target  | Minimum watchOS Target  | Minimum tvOS Target  |                                   Notes                                   |
|:--------------------:|:---------------------------:|:----------------------------:|:----------------------------:|:----------------------------:|:-------------------------------------------------------------------------:|
| 4.x | iOS 9 | macOS 10.10 | watchOS 2.0 | tvOS 9.0 | Xcode 11+ is required. |
| 3.x | iOS 7 | OS X 10.9 | watchOS 2.0 | tvOS 9.0 | Xcode 7+ is required. `NSURLConnectionOperation` support has been removed. |
| 2.6 -> 2.6.3 | iOS 7 | OS X 10.9 | watchOS 2.0 | n/a | Xcode 7+ is required. |
| 2.0 -> 2.5.4 | iOS 6 | OS X 10.8 | n/a | n/a | Xcode 5+ is required. `NSURLSession` subspec requires iOS 7 or OS X 10.9. |
| 1.x | iOS 5 | Mac OS X 10.7 | n/a | n/a |
| 0.10.x | iOS 4 | Mac OS X 10.6 | n/a | n/a |

(macOS项目必须支持 [64-bit with modern Cocoa runtime](https://developer.apple.com/library/mac/#documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtVersionsPlatforms.html)).

> 想在Swift程序中使用? 尝试 [Alamofire](https://github.com/Alamofire/Alamofire) 以获得更常规的API集。

## 架构

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

### 附加功能

- `AFSecurityPolicy`
- `AFNetworkReachabilityManager`

## 用法

### AFURLSessionManager

`AFURLSessionManager`基于指定的`NSURLSessionConfiguration`创建和管理`NSURLSession`对象，并且实现了`<NSURLSessionTaskDelegate>`, `<NSURLSessionDataDelegate>`, `<NSURLSessionDownloadDelegate>`, and `<NSURLSessionDelegate>`代理。

#### 创建下载任务

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

#### 创建上传任务

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

#### 为有进度的多部分请求创建上传任务

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

#### 创建数据任务

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

### 请求序列化

Request serializers create requests from URL strings, encoding parameters as either a query string or HTTP body.

```objective-c
NSString *URLString = @"http://example.com";
NSDictionary *parameters = @{@"foo": @"bar", @"baz": @[@1, @2, @3]};
```

#### 查询字符串参数编码

```objective-c
[[AFHTTPRequestSerializer serializer] requestWithMethod:@"GET" URLString:URLString parameters:parameters error:nil];
```

    GET http://example.com?foo=bar&baz[]=1&baz[]=2&baz[]=3

#### URL表单参数编码

```objective-c
[[AFHTTPRequestSerializer serializer] requestWithMethod:@"POST" URLString:URLString parameters:parameters error:nil];
```

    POST http://example.com/
    Content-Type: application/x-www-form-urlencoded

    foo=bar&baz[]=1&baz[]=2&baz[]=3

#### JSON参数编码

```objective-c
[[AFJSONRequestSerializer serializer] requestWithMethod:@"POST" URLString:URLString parameters:parameters error:nil];
```

    POST http://example.com/
    Content-Type: application/json

    {"foo": "bar", "baz": [1,2,3]}

---

### 网络可达性管理

`AFNetworkReachabilityManager` 监视域的可达性以及WWAN和WiFi网络接口的地址。

* 不要使用“可达性”来确定是否应发送原始请求。
    * 您应该尝试发送它。
* 您可以使用“可达性”来确定何时应自动重试请求。
    * 尽管它仍然可能失败，但是连接可用的可达性通知是重试某些内容的好时机。
* 网络可达性是确定请求失败原因的有用工具。
    * 在网络请求失败之后，告诉用户他们处于脱机状态比给他们一个技术性更高但更准确的错误（例如“请求超时”）更好。

另请参阅 [WWDC 2012会话706，“网络最佳实践”](https://developer.apple.com/videos/play/wwdc2012-706/).

#### 共享网络可达性

```objective-c
[[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
    NSLog(@"Reachability: %@", AFStringFromNetworkReachabilityStatus(status));
}];

[[AFNetworkReachabilityManager sharedManager] startMonitoring];
```

---

### 安全政策

`AFSecurityPolicy`通过固定的连接评估X.509证书和公钥对服务器的信任度。

向您的应用程序添加固定的SSL证书有助于防止中间人攻击和其他漏洞。强烈建议处理敏感客户数据或财务信息的应用程序通过配置并启用SSL固定的HTTPS连接路由所有通信。

#### 允许无效的SSL证书

```objective-c
AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
manager.securityPolicy.allowInvalidCertificates = YES; // not recommended for production
```

---

## 单元测试

AFNetworking在“测试”子目录中包含一组单元测试。只需在您要测试的平台框架上执行测试操作即可运行这些测试。

## 可性赖

AFNetworking由 [Alamofire软件基金会](http://alamofire.org)拥有和维护。

AFNetworking最初是由 [Scott Raymond](https://github.com/sco/) 和 [Mattt Thompson](https://github.com/mattt/) [Gowalla for iPhone](http://en.wikipedia.org/wiki/Gowalla)开发中创建的。

AFNetworking的徽标由 [Alan Defibaugh](http://www.alandefibaugh.com/) 设计。

最重要的是，感谢 AFNetworking's [贡献者列表](https://github.com/AFNetworking/AFNetworking/contributors).

### 安全漏洞告知

如果您认为已通过AFNetworking找到了安全漏洞，则应尽快通过电子邮件将其报告至security@alamofire.org。请不要将其发布到公共问题跟踪器中。

## 声明许可

AFNetworking是根据MIT许可发布的。有关详细信息，请参见 [许可](https://github.com/AFNetworking/AFNetworking/blob/master/LICENSE) 。
