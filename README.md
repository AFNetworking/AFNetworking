<p align="center" >
  <img src="https://github.com/AFNetworking/AFNetworking/raw/gh-pages/afnetworking-logo.png" alt="AFNetworking" title="AFNetworking">
</p>

AFNetworking is a delightful networking library for iOS and Mac OS X. It's built on top of [Foundation URL Loading System](http://developer.apple.com/library/mac/#documentation/Cocoa/Conceptual/URLLoadingSystem/URLLoadingSystem.html), extending the powerful high-level networking abstractions built into Cocoa. It has a modular architecture with well-designed, feature-rich APIs that are a joy to use.

Perhaps the most important feature of all, however, is the amazing community of developers who use and contribute to AFNetworking every day. AFNetworking powers some of the most popular and critically-acclaimed apps on the iPhone, iPad, and Mac.

Choose AFNetworking for your next project, or migrate over your existing projects—you'll be happy you did!

## How To Get Started

- [Download AFNetworking](https://github.com/AFNetworking/AFNetworking/zipball/master) and try out the included Mac and iPhone example apps
- Read the ["Getting Started" guide](https://github.com/AFNetworking/AFNetworking/wiki/Getting-Started-with-AFNetworking), [FAQ](https://github.com/AFNetworking/AFNetworking/wiki/AFNetworking-FAQ), or [other articles in the wiki](https://github.com/AFNetworking/AFNetworking/wiki)
- Check out the [complete documentation](http://afnetworking.github.com/AFNetworking/) for a comprehensive look at the APIs available in AFNetworking
- Watch the [NSScreencast episode about AFNetworking](http://nsscreencast.com/episodes/6-afnetworking) for a quick introduction to how to use it in your application
- Questions? [Stack Overflow](http://stackoverflow.com/questions/tagged/afnetworking) is the best place to find answers

### Installation with CocoaPods

```ruby
platform :ios, '7.0'
pod "AFNetworking", "2.0.0-RC2"
```

## 2.0

AFNetworking 2.0 is a major update to the framework. Building on 2 years of development, this new version introduces powerful new features, while providing an easy upgrade path for existing users.

**Read the [AFNetworking 2.0 Migration Guide](https://github.com/AFNetworking/AFNetworking/wiki/AFNetworking-2.0-Migration-Guide) for an overview of the architectural and API changes.**

### What's New

- Support for NSURLSession
- Serialization Modules
- Expanded UIKit Extensions
- Real-time functionality with [Rocket](http://rocket.github.io)

### Coming Soon

- Unit Tests Ported to 2.0
- AFSecurity Extension
- Core Image Serializer Extension
- MsgPack Serializer Extension

## Requirements

AFNetworking 2.0 and higher requires either iOS 7.0 and above, or Mac OS 10.9 Mavericks ([64-bit with modern Cocoa runtime](https://developer.apple.com/library/mac/#documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtVersionsPlatforms.html)) and above.

For compatibility with iOS 5 & 6, use the latest 1.x release.

For compatibility with iOS 4.3, use the latest 0.10.x release.

## Unit Tests

AFNetworking includes a suite of unit tests within the Tests subdirectory. In order to run the unit tests, you must install the testing dependencies via CocoaPods. To do so:

    $ gem install cocoapods # If necessary
    $ cd Tests
    $ pod install

Once CocoaPods has finished the installation, you can execute the test suite via the 'iOS Tests' and 'OS X Tests' schemes within Xcode.

### Test Logging

By default, the unit tests do not emit any output during execution. For debugging purposes, it can be useful to enable logging of the requests and responses. Logging support is provided by the [AFHTTPRequestOperationLogger](https://github.com/AFNetworking/AFHTTPRequestOperationLogger) extension, which is installed via CocoaPods into the test targets. To enable logging, edit the test Scheme and add an environment variable named `AFTestsLoggingEnabled` with a value of `YES`.

### Using xctool

If you wish to execute the tests from the command line or within a continuous integration environment, you will need to install [xctool](https://github.com/facebook/xctool). The recommended installation method is [Homebrew](http://mxcl.github.io/homebrew/).

To install the commandline testing support via Homebrew:

    $ brew update
    $ brew install xctool --HEAD

Once xctool is installed, you can execute the suite via `rake test`.

## Credits

AFNetworking was created by [Scott Raymond](https://github.com/sco/) and [Mattt Thompson](https://github.com/mattt/) in the development of [Gowalla for iPhone](http://en.wikipedia.org/wiki/Gowalla).

AFNetworking's logo was designed by [Alan Defibaugh](http://www.alandefibaugh.com/).

And most of all, thanks to AFNetworking's [growing list of contributors](https://github.com/AFNetworking/AFNetworking/contributors).

## Contact

Follow AFNetworking on Twitter ([@AFNetworking](https://twitter.com/AFNetworking))

### Creators

[Mattt Thompson](http://github.com/mattt)
[@mattt](https://twitter.com/mattt)

[Scott Raymond](http://github.com/sco)
[@sco](https://twitter.com/sco)

## License

AFNetworking is available under the MIT license. See the LICENSE file for more info.
