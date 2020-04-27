# Change Log
All notable changes to this project will be documented in this file.
`AFNetworking` adheres to [Semantic Versioning](https://semver.org/).

--- 

## [4.0.1](https://github.com/AFNetworking/AFNetworking/releases/tag/4.0.1) (04/19/2020)
Release on Sunday, April 19, 2020. All issues associated with this milestone can be found using this [filter](https://github.com/AFNetworking/AFNetworking/milestone/20?closed=1).

#### Updated
* Project templates and integrations.
  * Implemented by Kaspik in [#4531](https://github.com/AFNetworking/AFNetworking/pull/4531).
* Various CocoaPods podspec settings.
  * Implemented by ElfSundae in [#4528](https://github.com/AFNetworking/AFNetworking/pull/4528), [#4532](https://github.com/AFNetworking/AFNetworking/pull/4532), and [#4533](https://github.com/AFNetworking/AFNetworking/pull/4533).

#### Fixed
* Crash during authentication delegate method.
  * Implemented by Kaspik, ElfSundae, and jshier in [#4542](https://github.com/AFNetworking/AFNetworking/pull/4542), [#4552](https://github.com/AFNetworking/AFNetworking/pull/4552), and [#4553](https://github.com/AFNetworking/AFNetworking/pull/4553).
* SPM integration.
  * Implemented by jshier in [#4554](https://github.com/AFNetworking/AFNetworking/pull/4554).
* Improper update instead of replacement of header values.
  * Implemented by ElfSundae in [#4550](https://github.com/AFNetworking/AFNetworking/pull/4550).
* Nullability of some methods.
  * Implemented by ElfSundae in [#4551](https://github.com/AFNetworking/AFNetworking/pull/4551).
* Typos in CHANGELOG.
  * Implemented by ElfSundae in [#4537](https://github.com/AFNetworking/AFNetworking/pull/4537).
* Missing tvOS compatibility for some methods.
  * Implemented by ElfSundae in [#4536](https://github.com/AFNetworking/AFNetworking/pull/4536).
* Missing `FOUNDATION_EXPORT` for `AFJSONObjectByRemovingKeysWithNullValues`.
  * Implemented by ElfSundae in [#4529](https://github.com/AFNetworking/AFNetworking/pull/4529).
  
#### Removed
* Unused UIImage+AFNetworking.h file.
  * Implemented by ElfSundae in [#4535](https://github.com/AFNetworking/AFNetworking/pull/4535).

## [4.0.0](https://github.com/AFNetworking/AFNetworking/releases/tag/4.0.0) (03/29/2020)
Released on Sunday, March 29, 2020. All issues associated with this milestone can be found using this [filter](https://github.com/AFNetworking/AFNetworking/milestone/16?closed=1).

#### Added
* Notificate when a downloaded file has been moved successfully.
  * Implemented by xingheng in [#4393](https://github.com/AFNetworking/AFNetworking/pull/4393).
* Specific error for certificate pinning failure.
  * Implemented by 0xced in [#3425](https://github.com/AFNetworking/AFNetworking/pull/3425).
* `WKWebView` extensions.
  * Implemented by tjanela in [#4439](https://github.com/AFNetworking/AFNetworking/pull/4439).
* Automatic location of certificates in the main bundle for certificate pinning.
  * Implemented by 0xced in [#3752](https://github.com/AFNetworking/AFNetworking/pull/3752).
* User-Agent support for tvOS.
  * Implemented by ghking in [#4014](https://github.com/AFNetworking/AFNetworking/pull/4014).
* Ability for `AFHTTPSessionManager` to recreate its underlying `NSURLSession`.
  * Implemented by Kaspik in [#4256](https://github.com/AFNetworking/AFNetworking/pull/4256).
* Ability to set HTTP headers per request.
  * Implemented by stnslw in [#4113](https://github.com/AFNetworking/AFNetworking/pull/4113).
* Ability to capture `NSURLSessionTaskMetrics`.
  * Implemented by Caelink in [#4237](https://github.com/AFNetworking/AFNetworking/pull/4237).

#### Updated
* `dataTaskWithHTTPMethod` to be public.
  * Implemented by smartinspereira in [#4007](https://github.com/AFNetworking/AFNetworking/pull/4007).
* Reachability notification to include the instance which issued the notification.
  * Implemented by LMsgSendNilSelf in [#4051](https://github.com/AFNetworking/AFNetworking/pull/4051).
* `AFJSONObjectByRemovingKeysWithNullValues` to be public.
  * Implemented by ashfurrow in [#4051](https://github.com/AFNetworking/AFNetworking/pull/4051).
* `AFJSONObjectByRemovingKeysWithNullValues` to remove `NSNull` values from `NSArray`s.
  * Implemented by ashfurrow in [#4052](https://github.com/AFNetworking/AFNetworking/pull/4052).

#### Changed
* Automated CI to GitHub Actions.
  * Implemented by jshier in [#4523](https://github.com/AFNetworking/AFNetworking/pull/4523).

#### Fixed
* Explicit `NSSecureCoding` support.
  * Implemented by jshier in [#4523](https://github.com/AFNetworking/AFNetworking/pull/4523).
* Deprecated API usage on Catalyst.
  * Implemented by jshier in [#4523](https://github.com/AFNetworking/AFNetworking/pull/4523).
* Nullability annotations.
  * Implemented by jshier in [#4523](https://github.com/AFNetworking/AFNetworking/pull/4523).
* `AFImageDownloader` to more accurately cancel downloads.
  * Implemented by kinarobin in [#4407](https://github.com/AFNetworking/AFNetworking/pull/4407).
* Double KVO notifications in `AFNetworkActivityManager`.
  * Implemented by kinarobin in [#4406](https://github.com/AFNetworking/AFNetworking/pull/4406).
* Availability annotations around `NSURLSessionTaskMetrics`.
  * Implemented by ElfSundae in [#4516](https://github.com/AFNetworking/AFNetworking/pull/4516).
* Issues with `associated_object` and subclasses.
  * Implemented by welcommand in [#3872](https://github.com/AFNetworking/AFNetworking/pull/3872).
* Memory leak in example application.
  * Implemented by svoit in [#4196](https://github.com/AFNetworking/AFNetworking/pull/4196).
* Crashes in multithreaded scenarios and `dispatch_barrier`.
  * Implemented by streeter in [#4474](https://github.com/AFNetworking/AFNetworking/pull/4474).
* Issues with `NSSecureCoding`.
  * Implemented by ElfSudae in [#4409](https://github.com/AFNetworking/AFNetworking/pull/4409).
* Code style issues.
  * Implemented by svoit in [#4200](https://github.com/AFNetworking/AFNetworking/pull/4200).
* Race condition in `AFImageDownloader`.
  * Implemented by bbeversdorf in [#4246](https://github.com/AFNetworking/AFNetworking/pull/4246).
* Coding style issues.
  * Implemented by LeeHongHwa in [#4002](https://github.com/AFNetworking/AFNetworking/pull/4002).

#### Removed
* Support for iOS < 9, macOS < 10.10.
  * Implemented by jshier in [#4523](https://github.com/AFNetworking/AFNetworking/pull/4523).
* All previously deprecated APIs.
  * Implemented by jshier in [#4523](https://github.com/AFNetworking/AFNetworking/pull/4523).
* Unnecessary `__block` capture.
  * Implemented by kinarobin in [#4526](https://github.com/AFNetworking/AFNetworking/pull/4526).
* Workaround for `NSURLSessionUploadTask` creation on iOS 7.
  * Implemented by kinarobin in [#4525](https://github.com/AFNetworking/AFNetworking/pull/4525).
* Workaround for safe `NSURLSessionTask` creation on iOS < 8.
  * Implemented by kinarobin in [#4401](https://github.com/AFNetworking/AFNetworking/pull/4401).
* `UIWebView` extensions.
  * Implemented by tjanela in [#4439](https://github.com/AFNetworking/AFNetworking/pull/4439).

---

## [3.2.1](https://github.com/AFNetworking/AFNetworking/releases/tag/3.2.1) (05/04/2018)
Released on Friday, May 04, 2018. All issues associated with this milestone can be found using this [filter](https://github.com/AFNetworking/AFNetworking/issues?q=milestone%3A3.2.1+is%3Aclosed).

#### Updated
* Xcode 9.3 Support
	* Implemented by Jeff Kelley in [#4199](https://github.com/AFNetworking/AFNetworking/pull/4199).
* Update HTTPBin certificates for April 2018.
	* Implemented by Jeff Kelley in [#4198](https://github.com/AFNetworking/AFNetworking/pull/4198).

#### Additional Changes
* Remove conflicting nullable specifier on init
	* Implemented by Nick Brook and Jeff Kelley in [#4182](https://github.com/AFNetworking/AFNetworking/pull/4182).
* Use @available if available to silence a warning.
	* Implemented by Jeff Kelley in [#4138](https://github.com/AFNetworking/AFNetworking/pull/4138).
* UIImageView+AFNetworking: Prevent stuck state for malformed urlRequest
	* Implemented by Adam Duflo and aduflo in [#4131](https://github.com/AFNetworking/AFNetworking/pull/4131).
* add the link for LICENSE
	* Implemented by Liao Malin in [#4125](https://github.com/AFNetworking/AFNetworking/pull/4125).
* Fix analyzer warning for upload task creation
	* Implemented by Jeff Kelley in [#4122](https://github.com/AFNetworking/AFNetworking/pull/4122).
 

## [3.2.0](https://github.com/AFNetworking/AFNetworking/releases/tag/3.2.0) (12/15/2017)
Released on Friday, December 15, 2017. All issues associated with this milestone can be found using this [filter](https://github.com/AFNetworking/AFNetworking/issues?q=milestone%3A3.2.0+is%3Aclosed).

#### Added
* Config `AFImageDownloader` `NSURLCache` and ask `AFImageRequestCache` implementer if an image should be cached
	* Implemented by wjehenddher in [#4010](https://github.com/AFNetworking/AFNetworking/pull/4010).
* Add `XMLParser`/`XMLDocument` serializer tests
	* Implemented by skyline75489 in [#3753](https://github.com/AFNetworking/AFNetworking/pull/3753).
* Enable custom httpbin URL with `HTTPBIN_BASE_URL` environment variable
	* Implemented by 0xced in [#3748](https://github.com/AFNetworking/AFNetworking/pull/3748).
* `AFHTTPSessionManager` now throws exception if SSL pinning mode is set for non https sessions
	* Implemented by 0xced in [#3687](https://github.com/AFNetworking/AFNetworking/pull/3687).

#### Updated
* Update security policy test certificates
	* Implemented by SlaunchaMan in [#4103](https://github.com/AFNetworking/AFNetworking/pull/4103).
* Allow return value of HTTP redirection block to be `NULL`
	* Implemented by TheDom in [#3975](https://github.com/AFNetworking/AFNetworking/pull/3975).
* Clarify documentation for supported encodings in `AFJSONResponseSerializer`
	* Implemented by skyline75489 in [#3750](https://github.com/AFNetworking/AFNetworking/pull/3750).
* Handle Error Pointers according to Cocoa Convention
	* Implemented by tclementdev in [#3653](https://github.com/AFNetworking/AFNetworking/pull/3653).
* Updates `AFHTTPSessionManager` documentation to reflect v3.x change
	* Implemented by ecaselles in [#3476](https://github.com/AFNetworking/AFNetworking/pull/3476).
* Improved code base to generate fewer warnings when using stricter compiler settings
	* Implemented by 0xced in [3431](https://github.com/AFNetworking/AFNetworking/pull/3431).

#### Changed
* Change “Mac OS X” and “OS X” references to “macOS”
	* Implemented by SlaunchaMan in [#4104](https://github.com/AFNetworking/AFNetworking/pull/4104).

#### Fixed
* Fixed crash around customizing `NSURLCache` size for < iOS 8.2
	* Implemented by kcharwood in [#3735](https://github.com/AFNetworking/AFNetworking/pull/3735).
* Fixed issue where `UIWebView` extension did not preserve all of the request information
	* Implemented by skyline75489 in [#3733](https://github.com/AFNetworking/AFNetworking/pull/3733).
* Fixed bug with webview delegate callback
	* Implemented by kcharwood in [#3727](https://github.com/AFNetworking/AFNetworking/pull/3727).
* Fixed crash when passing invalid JSON to request serialization
	* Implemented by 0xced in [#3719](https://github.com/AFNetworking/AFNetworking/pull/3719).
* Fixed potential KVO crasher for URL Session Task delegates
	* Implemented by 0xced in [#3718](https://github.com/AFNetworking/AFNetworking/pull/3718).
* Removed ambiguous array creation in `AFSecurityPolicy`
	* Implemented by sgl0v in [#3679](https://github.com/AFNetworking/AFNetworking/pull/3679).
* Fixed issue where `NS_UNAVAILABLE` is not reported for `AFNetworkReachabilityManager`
	* Implemented by Microbee23 in [#3649](https://github.com/AFNetworking/AFNetworking/pull/3649).
* Require app extension api only on watchOS
	* Implemented by ethansinjin in [#3612](https://github.com/AFNetworking/AFNetworking/pull/3612).
* Remove KVO of progress in favor of using the NSURLSession delegate APIs
	* Implemented by coreyfloyd in [#3607](https://github.com/AFNetworking/AFNetworking/pull/3607).
* Fixed an issue where registering a `UIProgessView` to a task that was causing a crash
	* Implemented by Starscream27 in [#3604](https://github.com/AFNetworking/AFNetworking/pull/3604).
* Moved `[self didChangeValueForKey:@"currentState"]` into correct scope
	* Implemented by chenxin0123 in [#3565](https://github.com/AFNetworking/AFNetworking/pull/3565).
* Fixed issue where response serializers did not inherit super class copying
	* Implemented by kcharwood in [#3559](https://github.com/AFNetworking/AFNetworking/pull/3559).
* Fixed crashes due to race conditions with `NSMutableDictionary` access in `AFHTTPRequestSerializer`
	* Implemented by alexbird in [#3526](https://github.com/AFNetworking/AFNetworking/pull/3526).
* Updated dash character to improve markdown parsing for license
	* Implemented by gemmakbarlow in [#3488](https://github.com/AFNetworking/AFNetworking/pull/3488).

#### Removed
* Deprecate the unused stringEncoding property of `AFHTTPResponseSerializer`
	* Implemented by 0xced in [#3751](https://github.com/AFNetworking/AFNetworking/pull/3751).
* Removed unused `AFTaskStateChangedContext`
	* Implemented by yulingtianxia in [#3432](https://github.com/AFNetworking/AFNetworking/pull/3432).
 

## [3.1.0](https://github.com/AFNetworking/AFNetworking/releases/tag/3.1.0) (03/31/2016)
Released on Thursday, March 31, 2016. All issues associated with this milestone can be found using this [filter](https://github.com/AFNetworking/AFNetworking/issues?q=milestone%3A3.1.0+is%3Aclosed).

#### Added
* Improved `AFImageResponseSerializer` test coverage
 * Implemented by quellish in [#3367](https://github.com/AFNetworking/AFNetworking/pull/3367).
* Exposed `AFQueryStringFromParameters` and `AFPercentEscapedStringFromString` for public use.
 * Implemented by Kevin Harwood in [#3160](https://github.com/AFNetworking/AFNetworking/pull/3160).

#### Updated
* Updated Test Suite to run on Xcode 7.3
 * Implemented by Kevin Harwood in [#3418](https://github.com/AFNetworking/AFNetworking/pull/3418).
* Added white space to URLs in code comment to allow Xcode to properly parse them
 * Implemented by Draveness in [#3384](https://github.com/AFNetworking/AFNetworking/pull/3384).
* Updated documentation to match method names and correct compiler warnings
 * Implemented by Hakon Hanesand in [#3369](https://github.com/AFNetworking/AFNetworking/pull/3369).
* Use `NSKeyValueChangeNewKey` constant in change dictionary rather than hardcoded string.
 * Implemented by Wenbin Zhang in [#3360](https://github.com/AFNetworking/AFNetworking/pull/3360).
* Resolved compiler warnings for documentation errors
 * Implemented by Ricardo Santos in [#3336](https://github.com/AFNetworking/AFNetworking/pull/3336).

#### Changed
* Reverted `NSURLSessionAuthChallengeDisposition` to `NSURLSessionAuthChallengeCancelAuthenticationChallenge` for SSL Pinning
 * Implemented by Kevin Harwood in [#3417](https://github.com/AFNetworking/AFNetworking/pull/3417).

#### Fixed
* Removed trailing question mark in query string if parameters are empty
 * Implemented by Kevin Harwood in [#3386](https://github.com/AFNetworking/AFNetworking/pull/3386).
* Fixed crash if bad URL was passed into the image downloader
 * Implemented by Christian Wen and Kevin Harwood in [#3385](https://github.com/AFNetworking/AFNetworking/pull/3385).
* Fixed image memory calculation
 * Implemented by 周明宇 in [#3344](https://github.com/AFNetworking/AFNetworking/pull/3344).
* Fixed issue where UIButton image downloading called wrong cancel method
 * Implemented by duanhong in [#3332](https://github.com/AFNetworking/AFNetworking/pull/3332).
* Fixed image downloading cancellation race condition
 * Implemented by Kevin Harwood in [#3325](https://github.com/AFNetworking/AFNetworking/pull/3325).
* Fixed static analyzer warnings on AFNetworkReachabilityManager
 * Implemented by Jeff Kelley in [#3315](https://github.com/AFNetworking/AFNetworking/pull/3315).
* Fixed issue where download progress would not be reported in iOS 7
 * Implemented by zwm in [#3294](https://github.com/AFNetworking/AFNetworking/pull/3294).
* Fixed status code 204/205 handling
 * Implemented by Kevin Harwood in [#3292](https://github.com/AFNetworking/AFNetworking/pull/3292).
* Fixed crash when passing nil/null for progress in UIWebView extension
 * Implemented by Kevin Harwood in [#3289](https://github.com/AFNetworking/AFNetworking/pull/3289).

#### Removed
* Removed workaround for NSJSONSerialization bug that was fixed in iOS 7
 * Implemented by Cédric Luthi in [#3253](https://github.com/AFNetworking/AFNetworking/pull/3253).
 

## [3.0.4](https://github.com/AFNetworking/AFNetworking/releases/tag/3.0.4) (12/18/2015)
Released on Friday, December 18, 2015. All issues associated with this milestone can be found using this [filter](https://github.com/AFNetworking/AFNetworking/issues?q=milestone%3A3.0.4+is%3Aclosed).

#### Fixed
* Fixed issue where `AFNSURLSessionTaskDidResumeNotification` was removed twice
 * Implemented by Kevin Harwood in [#3236](https://github.com/AFNetworking/AFNetworking/pull/3236).
 

## [3.0.3](https://github.com/AFNetworking/AFNetworking/releases/tag/3.0.3) (12/16/2015)
Released on Wednesday, December 16, 2015. All issues associated with this milestone can be found using this [filter](https://github.com/AFNetworking/AFNetworking/issues?q=milestone%3A3.0.3+is%3Aclosed).

#### Added
* Added tests for response serializers to increase test coverage
 * Implemented by Kevin Harwood in [#3233](https://github.com/AFNetworking/AFNetworking/pull/3233).

#### Fixed
* Fixed `AFImageResponseSerializer` serialization macros on watchOS and tvOS
 * Implemented by Charles Joseph in [#3229](https://github.com/AFNetworking/AFNetworking/pull/3229).
 

## [3.0.2](https://github.com/AFNetworking/AFNetworking/releases/tag/3.0.2) (12/14/2015)
Released on Monday, December 14, 2015. All issues associated with this milestone can be found using this [filter](https://github.com/AFNetworking/AFNetworking/issues?q=milestone%3A3.0.2+is%3Aclosed).

#### Fixed
* Fixed a crash in `AFURLSessionManager` when resuming download tasks
 * Implemented by Chongyu Zhu in [#3222](https://github.com/AFNetworking/AFNetworking/pull/3222).
* Fixed issue where background button image would not be updated
 * Implemented by eofs in [#3220](https://github.com/AFNetworking/AFNetworking/pull/3220).
 

## [3.0.1](https://github.com/AFNetworking/AFNetworking/releases/tag/3.0.1) (12/11/2015)
Released on Friday, December 11, 2015. All issues associated with this milestone can be found using this [filter](https://github.com/AFNetworking/AFNetworking/issues?q=milestone%3A3.0.1+is%3Aclosed).

#### Added
* Added Xcode 7.2 support to Travis
 * Implemented by Kevin Harwood in [#3216](https://github.com/AFNetworking/AFNetworking/pull/3216).

#### Fixed
* Fixed race condition with ImageView/Button image downloading when starting/cancelling/starting the same request
 * Implemented by Kevin Harwood in [#3215](https://github.com/AFNetworking/AFNetworking/pull/3215).
 

## [3.0.0](https://github.com/AFNetworking/AFNetworking/releases/tag/3.0.0) (12/10/2015)
Released on Thursday, December 10, 2015. All issues associated with this milestone can be found using this [filter](https://github.com/AFNetworking/AFNetworking/issues?q=milestone%3A3.0.0+is%3Aclosed).

For detailed information about migrating to AFNetworking 3.0.0, please reference the [migration guide](https://github.com/AFNetworking/AFNetworking/wiki/AFNetworking-3.0-Migration-Guide). All 3.0.0 beta changes will be tracked with this [filter](https://github.com/AFNetworking/AFNetworking/issues?q=milestone%3A3.0.0+is%3Aclosed).

#### Added
* Added support for older versions of Xcode to Travis
 * Implemented by Kevin Harwood in [#3209](https://github.com/AFNetworking/AFNetworking/pull/3209).
* Added support for [Codecov.io](https://codecov.io/github/AFNetworking/AFNetworking/AFNetworking?branch=master#sort=coverage&dir=desc)
 * Implemented by Cédric Luthi and Kevin Harwood in [#3196](https://github.com/AFNetworking/AFNetworking/pull/3196).
 *  * **Please help us increase overall coverage by submitting a pull request!**
* Added support for IPv6 to Reachability
 * Implemented by SAMUKEI and Kevin Harwood in [#3174](https://github.com/AFNetworking/AFNetworking/pull/3174).
* Added support for Objective-C light weight generics
 * Implemented by Kevin Harwood in [#3166](https://github.com/AFNetworking/AFNetworking/pull/3166).
* Added nullability attributes to response object in success block
 * Implemented by Nathan Racklyeft in [#3154](https://github.com/AFNetworking/AFNetworking/pull/3154).
* Migrated to Fastlane for CI and Deployment
 * Implemented by Kevin Harwood in [#3148](https://github.com/AFNetworking/AFNetworking/pull/3148).
* Added support for tvOS
 * Implemented by Kevin Harwood in [#3128](https://github.com/AFNetworking/AFNetworking/issues/3128).
* New image downloading architecture
 * Implemented by Kevin Harwood in [#3122](https://github.com/AFNetworking/AFNetworking/issues/3122).
* Added Carthage Support
 * Implemented by Kevin Harwood in [#3121](https://github.com/AFNetworking/AFNetworking/issues/3121).
* Added a method to create a unique reachability manager
 * Implemented by Mo Bitar in [#3111](https://github.com/AFNetworking/AFNetworking/pull/3111).
* Added a initial delay to the network indicator per the Apple HIG
 * Implemented by Kevin Harwood in [#3094](https://github.com/AFNetworking/AFNetworking/pull/3094).

#### Updated
* Improved testing reliability for continuous integration
 * Implemented by Kevin Harwood in [#3124](https://github.com/AFNetworking/AFNetworking/pull/3124).
* Example project now consumes AFNetworking as a library.
 * Implemented by Kevin Harwood in [#3068](https://github.com/AFNetworking/AFNetworking/pull/3068).
* Migrated to using `instancetype` where applicable
 * Implemented by Kyle Fuller in [#3064](https://github.com/AFNetworking/AFNetworking/pull/3064).
* Tweaks to project to support Framework Project
 * Implemented by Christian Noon in [#3062](https://github.com/AFNetworking/AFNetworking/pull/3062).

#### Changed
* Split the iOS and OS X AppDelegate classes in the Example Project
 * Implemented by Cédric Luthi in [#3193](https://github.com/AFNetworking/AFNetworking/pull/3193).
* Changed SSL Pinning Error to be `NSURLErrorServerCertificateUntrusted`
 * Implemented by Cédric Luthi and Kevin Harwood in [#3191](https://github.com/AFNetworking/AFNetworking/pull/3191).
* New Progress Reporting API using `NSProgress`
 * Implemented by Kevin Harwood in [#3187](https://github.com/AFNetworking/AFNetworking/pull/3187).
* Changed `pinnedCertificates` type in `AFSecurityPolicy` from `NSArray` to `NSSet`
 * Implemented by Cédric Luthi in [#3164](https://github.com/AFNetworking/AFNetworking/pull/3164).

#### Fixed
* Improved task creation performance for iOS 8+
 * Implemented by nikitahils, Nikita G and Kevin Harwood in [#3208](https://github.com/AFNetworking/AFNetworking/pull/3208).
* Fixed certificate validation for servers providing incomplete chains
 * Implemented by André Pacheco Neves in [#3159](https://github.com/AFNetworking/AFNetworking/pull/3159).
* Fixed bug in `AFMultipartBodyStream` that may cause the input stream to read more bytes than required.
 * Implemented by bang in [#3153](https://github.com/AFNetworking/AFNetworking/pull/3153).
* Fixed race condition crash from Resume/Suspend task notifications
 * Implemented by Kevin Harwood in [#3152](https://github.com/AFNetworking/AFNetworking/pull/3152).
* Fixed `AFImageDownloader` stalling after numerous failures
 * Implemented by Rick Silva in [#3150](https://github.com/AFNetworking/AFNetworking/pull/3150).
* Fixed warnings generated in UIWebView category
 * Implemented by Kevin Harwood in [#3126](https://github.com/AFNetworking/AFNetworking/pull/3126).

#### Removed
* Removed AFBase64EncodedStringFromString static function
 * Implemented by Cédric Luthi in [#3188](https://github.com/AFNetworking/AFNetworking/pull/3188).
* Removed code supporting conditional compilation for unsupported development configurations.
 * Implemented by Cédric Luthi in [#3177](https://github.com/AFNetworking/AFNetworking/pull/3177).
* Removed deprecated methods, properties, and notifications from AFN 2.x
 * Implemented by Kevin Harwood in [#3168](https://github.com/AFNetworking/AFNetworking/pull/3168).
* Removed support for `NSURLConnection`
 * Implemented by Kevin Harwood in [#3120](https://github.com/AFNetworking/AFNetworking/issues/3120).
* Removed `UIAlertView` category support since it is now deprecated
 * Implemented by Kevin Harwood in [#3034](https://github.com/AFNetworking/AFNetworking/pull/3034).


## [2.6.3](https://github.com/AFNetworking/AFNetworking/releases/tag/2.6.3) (11/11/2015)
Released on Wednesday, November 11, 2015. All issues associated with this milestone can be found using this [filter](https://github.com/AFNetworking/AFNetworking/issues?q=milestone%3A2.6.3+is%3Aclosed).

#### Fixed
* Fixed clang analyzer warning suppression that prevented building under some project configurations
 * Fixed by [Kevin Harwood](https://github.com/Kevin Harwood) in [#3142](https://github.com/AFNetworking/AFNetworking/pull/3142).
* Restored Xcode 6 compatibility 
 * Fixed by [jcayzac](https://github.com/jcayzac) in [#3139](https://github.com/AFNetworking/AFNetworking/pull/3139).
 

## [2.6.2](https://github.com/AFNetworking/AFNetworking/releases/tag/2.6.2) (11/06/2015)
Released on Friday, November 06, 2015. All issues associated with this milestone can be found using this [filter](https://github.com/AFNetworking/AFNetworking/issues?q=milestone%3A2.6.2+is%3Aclosed).

### Important Upgrade Note for Swift
* [#3130](https://github.com/AFNetworking/AFNetworking/pull/3130) fixes a swift interop error that does have a breaking API change if you are using Swift. This was [identified](https://github.com/AFNetworking/AFNetworking/issues/3137) after 2.6.2 was released. It changes the method from `throws` to an error pointer, since that method does return an object and also handles an error pointer, which does not play nicely with the Swift/Objective-C error conversion. See [#2810](https://github.com/AFNetworking/AFNetworking/issues/2810) for additional notes. This affects `AFURLRequestionSerializer` and `AFURLResponseSerializer`.

#### Added
* `AFHTTPSessionManager` now copies its `securityPolicy`
 * Fixed by [mohamede1945](https://github.com/mohamede1945) in [#2887](https://github.com/AFNetworking/AFNetworking/pull/2887).

#### Updated
* Updated travis to run on 7.1
 * Fixed by [Kevin Harwood](https://github.com/Kevin Harwood) in [#3132](https://github.com/AFNetworking/AFNetworking/pull/3132).
* Simplifications of if and return statements in `AFSecurityPolicy`
 * Fixed by [TorreyBetts](https://github.com/TorreyBetts) in [#3063](https://github.com/AFNetworking/AFNetworking/pull/3063).

#### Fixed
* Fixed swift interop issue that prevented returning a nil NSURL for a download task
 * Fixed by [Kevin Harwood](https://github.com/Kevin Harwood) in [#3133](https://github.com/AFNetworking/AFNetworking/pull/3133).
* Suppressed false positive memory leak warning in Reachability Manager
 * Fixed by [Kevin Harwood](https://github.com/Kevin Harwood) in [#3131](https://github.com/AFNetworking/AFNetworking/pull/3131).
* Fixed swift interop issue with throws and Request/Response serialization. 
 * Fixed by [Kevin Harwood](https://github.com/Kevin Harwood) in [#3130](https://github.com/AFNetworking/AFNetworking/pull/3130).
* Fixed race condition in reachability callback delivery
 * Fixed by [MichaelHackett](https://github.com/MichaelHackett) in [#3117](https://github.com/AFNetworking/AFNetworking/pull/3117).
* Fixed URLs that were redirecting in the README
 * Fixed by [frankenbot](https://github.com/frankenbot) in [#3109](https://github.com/AFNetworking/AFNetworking/pull/3109).
* Fixed Project Warnings
 * Fixed by [Kevin Harwood](https://github.com/Kevin Harwood) in [#3102](https://github.com/AFNetworking/AFNetworking/pull/3102).
* Fixed README link to WWDC session
 * Fixed by [wrtsprt](https://github.com/wrtsprt) in [#3099](https://github.com/AFNetworking/AFNetworking/pull/3099).
* Switched from `OS_OBJECT_HAVE_OBJC_SUPPORT` to `OS_OBJECT_USE_OBJC` for watchOS 2 support.
 * Fixed by [kylef](https://github.com/kylef) in [#3065](https://github.com/AFNetworking/AFNetworking/pull/3065).
* Added missing __nullable attributes to failure blocks in `AFHTTPRequestOperationManager` and `AFHTTPSessionManager`
 * Fixed by [hoppenichu](https://github.com/hoppenichu) in [#3057](https://github.com/AFNetworking/AFNetworking/pull/3057).
* Fixed memory leak in NSURLSession handling
 * Fixed by [olegnaumenko](https://github.com/olegnaumenko) in [#2794](https://github.com/AFNetworking/AFNetworking/pull/2794).


## [2.6.1](https://github.com/AFNetworking/AFNetworking/releases/tag/2.6.1) (10-13-2015)
Released on Tuesday, October 13th, 2015. All issues associated with this milestone can be found using this [filter](https://github.com/AFNetworking/AFNetworking/issues?q=milestone%3A2.6.1+is%3Aclosed).

### Future Compatibility Note
Note that AFNetworking 3.0 will soon be released, and will drop support for all `NSURLConnection` based API's (`AFHTTPRequestOperationManager`, `AFHTTPRequestOperation`, and `AFURLConnectionOperation`. If you have not already migrated to `NSURLSession` based API's, please do so soon. For more information, please see the [3.0 migration guide](https://github.com/AFNetworking/AFNetworking/wiki/AFNetworking-3.0-Migration-Guide).

#### Fixed
* Fixed a bug that prevented empty x-www-form-urlencoded bodies.
	* Fixed by [Julien Cayzac](https://github.com/jcayzac) in [#2868](https://github.com/AFNetworking/AFNetworking/pull/2868).
* Fixed bug that prevented AFNetworking from being installed for watchOS via Cocoapods.
	* Fixed by [Kevin Harwood](https://github.com/Kevin Harwood) in [#2909](https://github.com/AFNetworking/AFNetworking/issues/2909).
* Added missing nullable attributes to `AFURLRequestSerialization` and `AFURLSessionManager`.
	* Fixed by [andrewtoth](https://github.com/andrewtoth) in [#2911](https://github.com/AFNetworking/AFNetworking/pull/2911).
* Migrated to `OS_OBJECT_USE_OBJC`.
	* Fixed by [canius](https://github.com/canius) in [#2930](https://github.com/AFNetworking/AFNetworking/pull/2930).
* Added missing nullable tags to UIKit extensions.
	* Fixed by [Kevin Harwood](https://github.com/Kevin Harwood) in [#3000](https://github.com/AFNetworking/AFNetworking/pull/3000).
* Fixed potential infinite recursion loop if multiple versions of AFNetworking are loaded in a target.
	* Fixed by [Kevin Harwood](https://github.com/Kevin Harwood) in [#2743](https://github.com/AFNetworking/AFNetworking/issues/2743). 
* Updated Travis CI test script
	* Fixed by [Kevin Harwood](https://github.com/Kevin Harwood) in [#3032](https://github.com/AFNetworking/AFNetworking/issues/3032). 
* Migrated to `FOUNDATION_EXPORT` from `extern`.
	* Fixed by [Andrey Mikhaylov](https://github.com/pronebird) in [#3041](https://github.com/AFNetworking/AFNetworking/pull/3041).
* Fixed issue where `AFURLConnectionOperation` could get stuck in an infinite loop.
	* Fixed by [Mattt Thompson](https://github.com/mattt) in [#2496](https://github.com/AFNetworking/AFNetworking/pull/2496).
* Fixed regression where URL request serialization would crash on iOS 8 for long URLs.
	* Fixed by [softenhard](https://github.com/softenhard) in [#3028](https://github.com/AFNetworking/AFNetworking/pull/3028).

## [2.6.0](https://github.com/AFNetworking/AFNetworking/releases/tag/2.6.0) (08-19-2015)
Released on Wednesday, August 19th, 2015. All issues associated with this milestone can be found using this [filter](https://github.com/AFNetworking/AFNetworking/issues?q=milestone%3A2.6.0+is%3Aclosed).

### Important Upgrade Notes
Please note the following API/project changes have been made:

* iOS 6 and OS X 10.8 support has been dropped from the project to facilitate support for watchOS 2. The final release supporting iOS 6 and OS X 10.8 is 2.5.4.
* **Full Certificate Chain Validation has been removed** from `AFSecurityPolicy`. As discussed in [#2744](https://github.com/AFNetworking/AFNetworking/issues/2744), there was no documented security advantage to pinning against an entire certificate chain. If you were using full certificate chain, please determine and select the most ideal certificate in your chain to pin against.
	* Implemented by [Kevin Harwood](https://github.com/Kevin Harwood) in [#2856](https://github.com/AFNetworking/AFNetworking/pull/2856).
* **The request url will now be returned by the `UIImageView` category if the image is returned from cache.** In previous releases, both the request and the response were nil. Going forward, only the response will be nil.
	* Implemented by [Chris Gibbs](https://github.com/chrisgibbs) in [#2771](https://github.com/AFNetworking/AFNetworking/pull/2771).
* **Support for App Extension Targets is now baked in using `NS_EXTENSION_UNAVAILABLE_IOS`.** You no longer need to define `AF_APP_EXTENSIONS` in order to include code in a extension target.
	* Implemented by [bnickel](https://github.com/bnickel) in [#2737](https://github.com/AFNetworking/AFNetworking/pull/2737).
* This release now supports watchOS 2.0, which relys on target conditionals that are only present in Xcode 7 and iOS 9/watchOS 2.0/OS X 10.10. If you install the library using CocoaPods, AFNetworking will define these target conditionals for on older platforms, allowing your code to compile. If you do not use Cocoapods, you will need to add the following code your to PCH file.

```
#ifndef TARGET_OS_IOS
  #define TARGET_OS_IOS TARGET_OS_IPHONE
#endif
#ifndef TARGET_OS_WATCH
  #define TARGET_OS_WATCH 0
#endif
```
* This release migrates query parameter serialization to model AlamoFire and adhere to RFC standards. Note that `/` and `?` are no longer encoded by default.
	* Implemented by [Kevin Harwood](https://github.com/Kevin Harwood) in [#2908](https://github.com/AFNetworking/AFNetworking/pull/2908).



**Note** that support for `NSURLConnection` based API's will be removed in a future update. If you have not already done so, it is recommended that you transition to the `NSURLSession` APIs in the very near future.

#### Added
* Added watchOS 2.0 support. `AFNetworking` can now be added to watchOS targets using CocoaPods.
	* Added by [Kevin Harwood](https://github.com/Kevin Harwood) in [#2837](https://github.com/AFNetworking/AFNetworking/issues/2837).
* Added nullability annotations to all of the header files to improve Swift interoperability.
	* Added by [Frank LSF](https://github.com/franklsf95) and [Kevin Harwood](https://github.com/Kevin Harwood) in [#2814](https://github.com/AFNetworking/AFNetworking/pull/2814).
* Converted source to Modern Objective-C Syntax.
	* Implemented by [Matt Shedlick](https://github.com/mattshedlick) and [Kevin Harwood](https://github.com/Kevin Harwood) in [#2688](https://github.com/AFNetworking/AFNetworking/pull/2688).
* Improved memory performance when download large objects.
	* Fixed by [Gabe Zabrino](https://github.com/gfzabarino) and [Kevin Harwood](https://github.com/Kevin Harwood) in [#2672](https://github.com/AFNetworking/AFNetworking/pull/2672).

#### Fixed
* Fixed a crash related for objects that observe notifications but don't properly unregister.
	* Fixed by [Kevin Harwood](https://github.com/Kevin Harwood) and [bnickle](https://github.com/bnickel) in [#2741](https://github.com/AFNetworking/AFNetworking/pull/2741).
* Fixed a race condition crash that occured with `AFImageResponseSerialization`.
	* Fixed by [Paulo Ferreria](https://github.com/paulosotu) and [Kevin Harwood](https://github.com/Kevin Harwood) in [#2815](https://github.com/AFNetworking/AFNetworking/pull/2815).
* Fixed an issue where tests failed to run on CI due to unavailable simulators.
	* Fixed by [Kevin Harwood](https://github.com/Kevin Harwood) in [#2834](https://github.com/AFNetworking/AFNetworking/pull/2834).
* Fixed "method override not found" warnings in Xcode 7 Betas
	* Fixed by [Ben Guo](https://github.com/benzguo) in [#2822](https://github.com/AFNetworking/AFNetworking/pull/2822)
* Removed Duplicate Import and UIKit Header file.
	* Fixed by [diehardest](https://github.com/diehardest) in [#2813](https://github.com/AFNetworking/AFNetworking/pull/2813)
* Removed the ability to include duplicate certificates in the pinned certificate chain.
	* Fixed by [Kevin Harwood](https://github.com/Kevin Harwood) in [#2756](https://github.com/AFNetworking/AFNetworking/pull/2756).
* Fixed potential memory leak in `AFNetworkReachabilityManager`.
	* Fixed by [Julien Cayzac](https://github.com/jcayzac) in [#2867](https://github.com/AFNetworking/AFNetworking/pull/2867).

#### Documentation Improvements
* Clarified best practices for Reachability per Apple recommendations.
	* Fixed by [Steven Fisher](https://github.com/tewha) in [#2704](https://github.com/AFNetworking/AFNetworking/pull/2704).
* Added `startMonitoring` call to the Reachability section of the README
	* Added by [Jawwad Ahmad](https://github.com/jawwad) in [#2831](https://github.com/AFNetworking/AFNetworking/pull/2831).
* Fixed documentation error around how `baseURL` is used for reachability monitoring.
	* Fixed by [Kevin Harwood](https://github.com/Kevin Harwood) in [#2761](https://github.com/AFNetworking/AFNetworking/pull/2761).
* Numerous spelling corrections in the documentation.
	* Fixed by [Antoine Cœur](https://github.com/Coeur) in [#2732](https://github.com/AFNetworking/AFNetworking/pull/2732) and [#2898](https://github.com/AFNetworking/AFNetworking/pull/2898).

## [2.5.4](https://github.com/AFNetworking/AFNetworking/releases/tag/2.5.4) (2015-05-14)
Released on 2015-05-14. All issues associated with this milestone can be found using this [filter](https://github.com/AFNetworking/AFNetworking/issues?q=milestone%3A2.5.4+is%3Aclosed).

#### Updated
* Updated the CI test script to run iOS tests on all versions of iOS that are installed on the build machine.
	* Updated by [Kevin Harwood](https://github.com/Kevin Harwood) in [#2716](https://github.com/AFNetworking/AFNetworking/pull/2716).
	
#### Fixed

* Fixed an issue where `AFNSURLSessionTaskDidResumeNotification` and `AFNSURLSessionTaskDidSuspendNotification` were not being properly called due to implementation differences in `NSURLSessionTask` in iOS 7 and iOS 8, which also affects the `AFNetworkActivityIndicatorManager`. 
	* Fixed by [Kevin Harwood](https://github.com/Kevin Harwood) in [#2702](https://github.com/AFNetworking/AFNetworking/pull/2702).
* Fixed an issue where the OS X test linker would throw a warning during tests.
	* Fixed by [Christian Noon](https://github.com/cnoon) in [#2719](https://github.com/AFNetworking/AFNetworking/pull/2719).
* Fixed an issue where tests would randomly fail due to mocked objects not being cleaned up.
	* Fixed by [Kevin Harwood](https://github.com/Kevin Harwood) in [#2717](https://github.com/AFNetworking/AFNetworking/pull/2717).


## [2.5.3](https://github.com/AFNetworking/AFNetworking/releases/tag/2.5.3) (2015-04-20)

* Add security policy tests for default policy

* Add network reachability tests

* Change `validatesDomainName` property to default to `YES` under all * security policies

* Fix `NSURLSession` subspec compatibility with iOS 6 / OS X 10.8

* Fix leak of data task used in `NSURLSession` swizzling

* Fix leak for observers from `addObserver:...:withBlock:`

* Fix issue with network reachability observation on domain name

## [2.5.2](https://github.com/AFNetworking/AFNetworking/releases/tag/2.5.2) (2015-03-26)
**NOTE** This release contains a security vulnerabilty. **All users should upgrade to a 2.5.3 or greater**. Please reference this [statement](https://gist.github.com/AlamofireSoftwareFoundation/f784f18f949b95ab733a) if you have any further questions about this release.

* Add guards for unsupported features in iOS 8 App Extensions

* Add missing delegate callbacks to 	`UIWebView` category
 
* Add test and implementation of strict default certificate validation

* Add #define for `NS_DESIGNATED_INITIALIZER` for unsupported versions of Xcode

* Fix `AFNetworkActivityIndicatorManager` for iOS 7

* Fix `AFURLRequestSerialization` property observation

* Fix `testUploadTasksProgressBecomesPartOfCurrentProgress`

* Fix warnings from Xcode 6.3 Beta

* Fix `AFImageWithDataAtScale` handling of animated images

* Remove `AFNetworkReachabilityAssociation` enumeration

* Update to conditional use assign semantics for GCD properties based on `OS_OBJECT_HAVE_OBJC_SUPPORT` for better Swift support

## [2.5.1](https://github.com/AFNetworking/AFNetworking/releases/tag/2.5.1) (2015-02-09)
**NOTE** This release contains a security vulnerabilty. **All users should upgrade to a 2.5.3 or greater**. Please reference this [statement](https://gist.github.com/AlamofireSoftwareFoundation/f784f18f949b95ab733a) if you have any further questions about this release.

 * Add `NS_DESIGNATED_INITIALIZER` macros. (Samir Guerdah)

 * Fix and clarify documentation for `stringEncoding` property. (Mattt
Thompson)

 * Fix for NSProgress bug where two child NSProgress instances are added to a
parent NSProgress. (Edward Povazan)

 * Fix incorrect file names in headers. (Steven Fisher)

 * Fix KVO issue when running testing target caused by lack of
`automaticallyNotifiesObserversForKey:` implementation. (Mattt Thompson)

 * Fix use of variable arguments for UIAlertView category.  (Kenta Tokumoto)

 * Fix `genstrings` warning for `NSLocalizedString` usage in
`UIAlertView+AFNetworking`. (Adar Porat)

 * Fix `NSURLSessionManager` task observation for network activity indicator
manager. (Phil Tang)

 * Fix `UIButton` category method caching of background image (Fernanda G.
Geraissate)

 * Fix `UIButton` category method failure handling. (Maxim Zabelin)

 * Update multipart upload method requirements to ensure `request.HTTPBody`
is non-nil. (Mattt Thompson)

 * Update to use builtin `__Require` macros from AssertMacros.h. (Cédric
Luthi)

 * Update `parameters` parameter to accept `id` for custom serialization
block. (@mooosu)

## [2.5.0](https://github.com/AFNetworking/AFNetworking/releases/tag/2.5.0) (2014-11-17)

 * Add documentation for expected background session manager usage (Aaron
Brager)

 * Add missing documentation for `AFJSONRequestSerializer` and
`AFPropertyListSerializer` (Mattt Thompson)

 * Add tests for requesting HTTPS endpoints (Mattt Thompson)

 * Add `init` method declarations of `AFURLResponseSerialization` classes for
Swift compatibility (Allen Rohner)

 * Change default User-Agent to use the version number instead of the build
number (Tim Watson)

 * Change `validatesDomainName` to readonly property (Mattt Thompson, Brian
King)

 * Fix checks when observing `AFHTTPRequestSerializerObservedKeyPaths` (Jacek
Suliga)

 * Fix crash caused by attempting to set nil `NSURLResponse -URL` as key for
`userInfo` dictionary (Elvis Nuñez)

 * Fix crash for multipart streaming requests in XPC services (Mattt Thompson)

 * Fix minor aspects of response serializer documentation (Mattt Thompson)

 * Fix potential race condition for `AFURLConnectionOperation -description`

 * Fix widespread crash related to key-value observing of `NSURLSessionTask
-state` (Phil Tang)

 * Fix `UIButton` category associated object keys (Kristian Bauer, Mattt
Thompson)

 * Remove `charset` parameter from Content-Type HTTP header field values for
`AFJSONRequestSerializer` and `AFPropertyListSerializer` (Mattt Thompson)

 * Update CocoaDocs color scheme (@Orta)

 * Update Podfile to explicitly define sources (Kyle Fuller)

 * Update to relay `downloadFileURL` to the delegate if the manager picks a
`fileURL` (Brian King)

 * Update `AFSSLPinningModeNone` to not validate domain name (Brian King)

 * Update `UIButton` category to cache images in `sharedImageCache` (John
Bushnell)

 * Update `UIRefreshControl` category to set control state to current state
of request (Elvis Nuñez)

## [2.4.1](https://github.com/AFNetworking/AFNetworking/releases/tag/2.4.1) (2014-09-04)

 * Fix compiler warning generated on 32-bit architectures (John C. Daub)

 * Fix potential crash caused by failed validation with nil responseData
 (Mattt Thompson)

 * Fix to suppress compiler warnings for out-of-range enumerated type
 value assignment (Mattt Thompson)

## [2.4.0](https://github.com/AFNetworking/AFNetworking/releases/tag/2.4.0) (2014-09-03)

 * Add CocoaDocs color scheme (Orta)

 * Add image cache to `UIButton` category (Kristian Bauer, Mattt Thompson)

 * Add test for success block on 204 response (Mattt Thompson)

 * Add tests for encodable and re-encodable query string parameters (Mattt
Thompson)

 * Add `AFHTTPRequestSerializer -valueForHTTPHeaderField:` (Kyle Fuller)

 * Add `AFNetworkingOperationFailingURLResponseDataErrorKey` key to user info
of serialization error (Yannick Heinrich)

 * Add `imageResponseSerializer` property to `UIButton` category (Kristian
Bauer, Mattt Thompson)

 * Add `removesKeysWithNullValues` setting to serialization and copying (Jon
Shier)

 * Change request and response serialization tests to be factored out into
separate files (Mattt Thompson)

 * Change signature of success parameters in `UIButton` category methods to
match those in `UIImageView` (Mattt Thompson)

 * Change to remove charset parameter from
`application/x-www-form-urlencoded` content type (Mattt Thompson)

 * Change `AFImageCache` to conform to `NSObject` protocol ( Marcelo Fabri)

 * Change `AFMaximumNumberOfToRecreateBackgroundSessionUploadTask` to
`AFMaximumNumberOfAttemptsToRecreateBackgroundSessionUploadTask` (Mattt
Thompson)

 * Fix documentation error for NSSecureCoding (Robert Ryan)

 * Fix documentation for `URLSessionDidFinishEventsForBackgroundURLSession`
delegate method (Mattt Thompson)

 * Fix expired ADN certificate in example project (Carson McDonald)

 * Fix for interoperability within Swift project (Stephan Krusche)

 * Fix for potential deadlock due to KVO subscriptions within a lock
(Alexander Skvortsov)

 * Fix iOS 7 bug where session tasks can have duplicate identifiers if
created from different threads (Mattt Thompson)

 * Fix iOS 8 bug by adding explicit synthesis for `delegate` of
`AFMultipartBodyStream` (Mattt Thompson)

 * Fix issue caused by passing `nil` as body of multipart form part (Mattt
Thompson)

 * Fix issue caused by passing `nil` as destination in download task method
(Mattt Thompson)

 * Fix issue with `AFHTTPRequestSerializer` returning a request and silently
handling an error from a `queryStringSerialization` block (Kyle Fuller, Mattt
Thompson)

 * Fix potential issues by ensuring `invalidateSessionCancelingTasks` only
executes on main thread (Mattt Thompson)

 * Fix potential memory leak caused by deferred opening of output stream
(James Tomson)

 * Fix properties on session managers such that default values will not trump
values set in the session configuration (Mattt Thompson)

 * Fix README to include explicit call to start reachability manager (Mattt
Thompson)

 * Fix request serialization error handling in `AFHTTPSessionManager`
convenience methods (Kyle Fuller, Lars Anderson, Mattt Thompson)

 * Fix stray localization macro (Devin McKaskle)

 * Fix to ensure connection operation `-copyWithZone:` calls super
implementation (Chris Streeter)

 * Fix `UIButton` category to only cancel request for specified state
(@xuzhe, Mattt Thompson)

## [2.3.1](https://github.com/AFNetworking/AFNetworking/releases/tag/2.3.1) (2014-06-13)

 * Fix issue with unsynthesized `streamStatus` & `streamError` properties
on `AFMultipartBodyStream` (Mattt Thompson)

## [2.3.0](https://github.com/AFNetworking/AFNetworking/releases/tag/2.3.0) (2014-06-11)

 * Add check for `AF_APP_EXTENSIONS` macro to conditionally compile
background  method that makes API call unavailable to App Extensions in iOS 8
/ OS X 10.10

 * Add further explanation for network reachability in documentation (Steven
Fisher)

 * Add notification for initial change from
`AFNetworkReachabilityStatusUnknown` to any other state (Jason Pepas,
Sebastian S.A., Mattt Thompson)

 * Add tests for AFNetworkActivityIndicatorManager (Dave Weston, Mattt
Thompson)

 * Add tests for AFURLSessionManager task progress (Ullrich Schäfer)

 * Add `attemptsToRecreateUploadTasksForBackgroundSessions` property, which
attempts Apple's recommendation of retrying a failed upload task if initial
creation did not succeed (Mattt Thompson)

 * Add `completionQueue` and `completionGroup` properties to
`AFHTTPRequestOperationManager` (Robert Ryan)

 * Change deprecating `AFErrorDomain` in favor of
`AFRequestSerializerErrorDomain` & `AFResponseSerializerErrorDomain` (Mattt
Thompson)

 * Change serialization tests to be split over two different files (Mattt
Thompson)

 * Change to make NSURLSession subspec not depend on NSURLConnection subspec
(Mattt Thompson)

 * Change to make Serialization subspec not depend on NSURLConnection subspec
(Nolan Waite, Mattt Thompson)

 * Change `completionHandler` of
`application:handleEventsForBackgroundURLSession:completion:` to be run on
main thread (Padraig Kennedy)

 * Change `UIImageView` category to accept any object conforming to
`AFURLResponseSerialization`, rather than just `AFImageResponseSerializer`
(Romans Karpelcevs)

 * Fix calculation and behavior of `NSProgress` (Padraig Kennedy, Ullrich
Schäfer)

 * Fix deprecation warning for `backgroundSessionConfiguration:` in iOS 8 /
OS X 10.10 (Mattt Thompson)

 * Fix implementation of `copyWithZone:` in serializer subclasses (Chris
Streeter)

 * Fix issue in Xcode 6 caused by implicit synthesis of overridden `NSStream`
properties (Clay Bridges, Johan Attali)

 * Fix KVO handling for `NSURLSessionTask` on iOS 8 / OS X 10.10 (Mattt
Thompson)

 * Fix KVO leak for `NSURLSessionTask` (@Zyphrax)

 * Fix potential crash caused by attempting to use non-existent error of
failing requests due to URLs exceeding a certain length (Boris Bügling)

 * Fix to check existence of `uploadProgress` block inside a referencing
`dispatch_async` to avoid potential race condition (Kyungkoo Kang)

 * Fix `UIImageView` category race conditions (Sunny)

 * Remove unnecessary default operation response serializer setters (Mattt
Thompson)

## [2.2.4](https://github.com/AFNetworking/AFNetworking/releases/tag/2.2.4) (2014-05-13)

 * Add NSSecureCoding support to all AFNetworking classes (Kyle Fuller, Mattt
Thompson)

 * Change behavior of request operation `NSOutputStream` property to only nil
out if `responseData` is non-nil, meaning that no custom object was set
(Mattt Thompson)

 * Fix data tasks to not attempt to track progress, and rare related crash
(Padraig Kennedy)

 * Fix issue with `-downloadTaskDidFinishDownloading:` not being called
(Andrej Mihajlov)

 * Fix KVO leak on invalidated session tasks (Mattt Thompson)

 * Fix missing import of `UIRefreshControl+AFNetworking" (@BB9z)

 * Fix potential compilation errors on Mac OS X, caused by import order of
`<AssertionMacros.h>`, which signaled an incorrect deprecation warning (Mattt
Thompson)

 * Fix race condition in UIImageView+AFNetworking when making several image
requests in quick succession (Alexander Crettenand)

 * Update documentation for `-downloadTaskWithRequest:` to warn about blocks
being disassociated on app termination and backgrounding (Robert Ryan)

## [2.2.3](https://github.com/AFNetworking/AFNetworking/releases/tag/2.2.3) (2014-04-18)

  * Fix `AFErrorOrUnderlyingErrorHasCodeInDomain` function declaration for
AFXMLDocumentResponseSerializer (Mattt Thompson)

  * Fix error domain check in `AFErrorOrUnderlyingErrorHasCodeInDomain`
(Mattt Thompson)

  * Fix `UIImageView` category to only `nil` out request operation properties
belonging to completed request (Mattt Thompson)

  * Fix `removesKeysWithNullValues` to respect
`NSJSONReadingMutableContainers` option (Mattt Thompson)

  * Change `removesKeysWithNullValues` property to recursively remove null
values from dictionaries nested in arrays (@jldagon)

  * Change to not override `Content-Type` header field values set by
`HTTPRequestHeaders` property (Aaron Brager, Mattt Thompson)

## [2.2.2](https://github.com/AFNetworking/AFNetworking/releases/tag/2.2.2) (2014-04-15)

  * Add `removesKeysWithNullValues` property to `AFJSONResponsSerializer` to
automatically remove `NSNull` values in dictionaries serialized from JSON
(Mattt Thompson)

  * Add unit test for checking content type (Diego Torres)

  * Add `boundary` property to `AFHTTPBodyPart -copyWithZone:`

  * Change to accept `id` parameter type in HTTP manager convenience methods
(Mattt Thompson)

  * Change to deprecate `setAuthorizationHeaderFieldWithToken:`, in favor of
users specifying an `Authorization` header field value themselves (Mattt
Thompson)

  * Change to use `long long` type to prevent a difference in stream size
caps on 32-bit and 64-bit architectures (Yung-Luen Lan, Cédric Luthi)

  * Fix calculation of Content-Length in `taskDidSendBodyData` (Christos
Vasilakis)

  * Fix for comparison of image view request operations (Mattt Thompson)

  * Fix for SSL certificate validation to check status codes at runtime (Dave
Anderson)

  * Fix to add missing call to delegate in
`URLSession:downloadTask:didResumeAtOffset:expectedTotalBytes:`

  * Fix to call `taskDidComplete` if delegate is missing (Jeff Ward)

  * Fix to implement `respondsToSelector:` for `NSURLSession` delegate
methods to conditionally respond to conditionally respond to optional
selectors if and only if a custom block has been set (Mattt Thompson)

  * Fix to prevent illegal state values from being assigned for
`AFURLConnectionOperation` (Kyle Fuller)

  * Fix to re-establish `AFNetworkingURLSessionTaskDelegate` objects after
restoring from a background configuration (Jeff Ward)

  * Fix to reduce memory footprint by `nil`-ing out request operation
`outputStream` after closing, as well as image view request operation after
setting image (Teun van Run, Mattt Thompson)

  * Remove unnecessary call in class constructor (Bernhard Loibl)

  * Remove unnecessary check for `respondsToSelector:` for `UIScreen scale`
in User-Agent string (Samuel Goodwin)

  * Update App.net certificate and API base URL (Cédric Luthi)

  * Update examples in README (@petard, @orta, Mattt Thompson)

  * Update Travis CI icon to use SVG format (Maximilian Tagher)

## [2.2.1](https://github.com/AFNetworking/AFNetworking/releases/tag/2.2.1) (2014-03-14)

  * Fix `-Wsign-conversion` warning in AFURLConnectionOperation (Jesse Collis)

  * Fix `-Wshorten-64-to-32` warning (Jesse Collis)

  * Remove unnecessary #imports in `UIImageView` & `UIWebView` categories
(Jesse Collis)

  * Fix call to `CFStringTransform()` by checking return value before setting
as `User-Agent` (Kevin Cassidy Jr)

  * Update `AFJSONResponseSerializer` adding `@autorelease` to relieve memory
pressure (Mattt Thompson, Michal Pietras)

  * Update `AFJSONRequestSerializer` to accept `id` (Daren Desjardins)

  * Fix small documentation bug (@jkoepcke)

  * Fix behavior of SSL pinning. In case of `validatesDomainName == YES`, it
now explicitly uses `SecPolicyCreateSSL`, which also validates the domain
name. Otherwise, `SecPolicyCreateBasicX509` is used.
`AFSSLPinningModeCertificate` now uses `SecTrustSetAnchorCertificates`, which
allows explicit specification of all trusted certificates. For
`AFSSLPinningModePublicKey`, the number of trusted public keys determines if
the server should be trusted. (Oliver Letterer, Eric Allam)

## [2.2.0](https://github.com/AFNetworking/AFNetworking/releases/tag/2.2.0) (2014-02-25)

  * Add default initializer to make `AFHTTPRequestOperationManager`
consistent with `AFHTTPSessionManager` (Marcelo Fabri)

  * Add documentation about `UIWebView` category and implementing
`UIWebViewDelegate` (Mattt Thompson)

  * Add missing `NSCoding` and `NSCopying` implementations for
`AFJSONRequestSerializer` (Mattt Thompson)

  * Add note about use of `-startMonitoring` in
`AFNetworkReachabilityManager` (Mattt Thompson)

  * Add setter for needsNewBodyStream block (Carmen Cerino)

  * Add support for specifying a response serializer on a per-instance of
`AFURLSessionManagerTaskDelegate` (Blake Watters)

  * Add `AFHTTPRequestSerializer
-requestWithMultipartFormRequest:writingStreamContentsToFile:completionHandler
:` as a workaround for a bug in NSURLSession that removes the Content-Length
header from streamed requests (Mattt Thompson)

  * Add `NSURLRequest` factory properties on `AFHTTPRequestSerializer` (Mattt
Thompson)

  * Add `UIRefreshControl+AFNetworking` (Mattt Thompson)

  * Change example project to enable certificate pinning (JP Simard)

  * Change to allow self-signed certificates (Frederic Jacobs)

  * Change to make `reachabilityManager` property readwrite (Mattt Thompson)

  * Change to sort `NSSet` members during query string parameter
serialization (Mattt Thompson)

  * Change to use case sensitive compare when sorting keys in query string
serialization (Mattt Thompson)

  * Change to use xcpretty instead of xctool for automated testing (Kyle
Fuller, Marin Usalj, Carson McDonald)

  * Change to use `@selector` values as keys for associated objects (Mattt
Thompson)

  * Change `setImageWithURL:placeholder:`, et al. to only set placeholder
image if not `nil` (Alejandro Martinez)

  * Fix auto property synthesis warnings (Oliver Letterer)

  * Fix domain name validation for SSL certificates (Oliver Letterer)

  * Fix issue with session task delegate KVO observation (Kyle Fuller)

  * Fix placement of `baseURL` method declaration (Oliver Letterer)

  * Fix podspec linting error (Ari Braginsky)

  * Fix potential concurrency issues by adding lock around setting
`isFinished` state in `AFURLConnectionOperation` (Mattt Thompson)

  * Fix potential vulnerability caused by hard-coded multipart form data
boundary (Mathias Bynens, Tom Van Goethem, Mattt Thompson)

  * Fix protocol name in #pragma mark declaration (@sevntine)

  * Fix regression causing inflated images to have incorrect orientation
(Mattt Thompson)

  * Fix to `AFURLSessionManager` `NSCoding` implementation, to accommodate
`NSURLSessionConfiguration` no longer conforming to `NSCoding`.

  * Fix Travis CI integration (Kyle Fuller, Marin Usalj, Carson McDonald)

  * Fix various static analyzer warnings (Philippe Casgrain, Jim Young,
Steven Fisher, Mattt Thompson)

  * Fix with download progress calculation of completion units (Kyle Fuller)

  * Fix Xcode 5.1 compiler warnings (Nick Banks)

  * Fix `AFHTTPRequestOperationManager` to default
`shouldUseCredentialStorage` to `YES`, as documented (Mattt Thompson)

  * Remove Unused format property in `AFJSONRequestSerializer` (Mattt
Thompson)

  * Remove unused `acceptablePathExtensions` class method in
`AFJSONRequestSerializer` (Mattt Thompson)

  * Update #ifdef declarations in UIKit categories to be simpler (Mattt
Thompson)

  * Update podspec to includ social_media_url (Kyle Fuller)

  * Update types for 64 bit architecture (Bruno Tortato Furtado, Mattt
Thompson)

## [2.1.0](https://github.com/AFNetworking/AFNetworking/releases/tag/2.1.0) (2014-01-16)

  * Add CONTRIBUTING (Kyle Fuller)

  * Add domain name verification for SSL certificates (Oliver Letterer)

  * Add leaf certificate checking (Alex Leverington, Carson McDonald, Mattt
Thompson)

  * Add test case for stream failure handling (Kyle Fuller)

  * Add underlying error properties to response serializers to forward errors
to subsequent validation steps (Mattt Thompson)

  * Add `AFImageCache` protocol, to allow for custom image caches to be
specified for `UIImageView` (Mattt Thompson)

  * Add `error` out parameter for request serializer, deprecating existing
request constructor methods (Adam Becevello)

  * Change request serializer protocol to take id type for parameters (Mattt
Thompson)

  * Change to add validation of download task responses (Mattt Thompson)

  * Change to force upload progress, by using original request Content-Length
(Mateusz Malczak)

  * Change to use `NSDictionary` object literals for `NSError` `userInfo`
construction (Mattt Thompson)

  * Fix #pragma declaration to be NSURLConnectionDataDelegate, rather than
NSURLConnectionDelegate (David Paschich)

  * Fix a bug when appending a file part to multipart request from a URL
(Kyle Fuller)

  * Fix analyzer warning about weak receiver being set to nil, capture strong
reference (Stewart Gleadow)

  * Fix appending file part to multipart request to use suggested file name,
rather than temporary one (Kyle Fuller)

  * Fix availability macros for network activity indicator (Mattt Thompson)

  * Fix crash in iOS 6.1 caused by KVO on `isCancelled` property of
`AFURLConnectionOperation` (Sam Page)

  * Fix dead store issues in `AFSecurityPolicy` (Andrew Hershberger)

  * Fix incorrect documentation for `-HTTPRequestOperationWithRequest:...`
(Kyle Fuller)

  * Fix issue in reachability callbacks, where reachability managers created
for a particular domain would initially report no reachability (Mattt
Thompson)

  * Fix logic for handling data task turning into download task (Kyle Fuller)

  * Fix property list response serializer to handle 204 response (Kyle Fuller)

  * Fix README multipart example (Johan Forssell)

  * Fix to add check for non-nil delegate in
`URLSession:didCompleteWithError:` (Kaom Te)

  * Fix to dramatically improve creation of images in
`AFInflatedImageFromResponseWithDataAtScale`, including handling of CMYK, 16
/ 32 bpc images, and colorspace alpha settings (Robert Ryan)

  * Fix Travis CI integration and unit testing (Kyle Fuller, Carson McDonald)

  * Fix typo in comments (@palringo)

  * Fix UIWebView category to use supplied success callback (Mattt Thompson)

  * Fix various static analyzer warnings (Kyle Fuller, Jesse Collis, Mattt
Thompson)

  * Fix `+batchOfRequestOperations:...` completion block to execute in
`dispatch_async` (Mattt Thompson)

  * Remove synchronous `SCNetworkReachabilityGetFlags` call when initializing
managers, which had the potential to block in certain network conditions
(Yury Korolev, Mattt Thompson)

  * Remove unnecessary check for completionHandler in HTTP manager (Mattt
Thompson)

  * Remove unused conditional clauses (Luka Bratos)

  * Update documentation for `AFCompoundResponseSerializer` (Mattt Thompson)

  * Update httpbin certificates (Carson McDonald)

  * Update notification constant names to be consistent with `NSURLSession`
terminology (Mattt Thompson)

## [2.0.3](https://github.com/AFNetworking/AFNetworking/releases/tag/2.0.3) (2013-11-18)

  * Fix a bug where `AFURLConnectionOperation -pause` did not correctly reset
the state of `AFURLConnectionOperation`, causing the Network Thread to enter
an infinite loop (Erik Chen)

  * Fix a bug where `AFURLConnectionOperation -cancel` does not set the
appropriate error on the `NSOperation` (Erik Chen)

  * Fix to post `AFNetworkingTaskDidFinishNotification` only on main queue
(Jakub Hladik)

  * Fix issue where the query string serialization block was not used (Kevin
Harwood)

  * Fix project file and repository directory items (Andrew Newdigate)

  * Fix `NSURLSession` subspec (Mattt Thompson)

  * Fix to session task delegate KVO by moving observer removal to
`-didCompleteWithError:` (Mattt Thompson)

  * Add AFNetworking 1.x behavior for image construction in inflation to
ensure correct orientation (Mattt Thompson)

  * Add `NSParameterAssert` for internal task constructors in order to catch
invalid constructions early (Mattt Thompson)

  * Update replacing `NSParameterAssert` with early `nil` return if session
was unable to create a task (Mattt Thompson)

  * Update `AFHTTPRequestOperationManager` and `AFHTTPSessionManager` to use
relative `self class` to create class constructor instances (Bogdan
Poplauschi)

  * Update to break out of loop if output stream does not have space to write
bytes (Mattt Thompson)

  * Update documentation and README with various fixes (Max Goedjen, Mattt
Thompson)

  * Remove unnecessary willChangeValueForKey and didChangeValueForKey method
calls (Mindaugas Vaičiūnas)

  * Remove deletion of all task delegates in
`URLSessionDidFinishEventsForBackgroundURLSession:` (Jeremy Mailen)

  * Remove empty, unused `else` branch (Luka Bratos)

## [2.0.2](https://github.com/AFNetworking/AFNetworking/releases/tag/2.0.2) (2013-10-29)

  * Add `UIWebView
 -loadRequest:MIMEType:textEncodingName:progress:success:failure:` (Mattt
 Thompson)

  * Fix iOS 6 compatibility in `AFHTTPSessionManager` &
 `UIProgressView+AFNetworking` (Olivier Halligon, Mattt Thompson)

  * Fix issue writing partial data to output stream (Kyle Fuller)

  * Fix behavior for `nil` response in request operations (Marcelo Fabri)

  * Fix implementation of
 batchOfRequestOperations:progressBlock:completionBlock: for nil when passed
 empty operations parameter (Mattt Thompson)

  * Update `AFHTTPSessionManager` to allow `-init` and `initWithConfig:` to
 work (Ben Scheirman)

  * Update `AFRequestOperation` to default to `AFHTTPResponseSerializer` (Jiri
 Techet)

  * Update `AFHTTPResponseSerializer` to remove check for nonzero responseData
 length (Mattt Thompson)

  * Update `NSCoding` methods to use NSStringFromSelector(@selector()) pattern
 instead of `NSString` literals (Mattt Thompson)

  * Update multipart form stream to set Content-Length after setting request
 stream (Mattt Thompson)

  * Update documentation with outdated references to `AFHTTPSerializer` (Bruno
 Koga)

  * Update documentation and README with various fixes (Jon Chambers, Mattt
 Thompson)

  * Update files to remove executable privilege (Kyle Fuller)

## [2.0.1](https://github.com/AFNetworking/AFNetworking/releases/tag/2.0.1) (2013-10-10)

 * Fix iOS 6 compatibility (Matt Baker, Mattt Thompson)

 * Fix example applications (Sam Soffes, Kyle Fuller)

 * Fix usage of `NSSearchPathForDirectoriesInDomains` in README (Leo Lou)

 * Fix names of exposed private methods `downloadProgress` and
`uploadProgress` (Hermes Pique)

 * Fix initial upload/download task progress updates (Vlas Voloshin)

 * Fix podspec to include `AFNetworking.h` `#import` (@haikusw)

 * Fix request serializers to not override existing header field values with
defaults (Mattt Thompson)

 * Fix unused format string placeholder (Thorsten Lockert)

 * Fix `AFHTTPRequestOperation -initWithCoder:` to call `super` (Josh Avant)

 * Fix `UIProgressView` selector name (Allen Tu)

 * Fix `UIButton` response serializer (Sam Grossberg)

 * Fix `setPinnedCertificates:` and pinned public keys (Kyle Fuller)

 * Fix timing of batched operation completion block (Denys Telezhkin)

 * Fix `GCC_WARN_ABOUT_MISSING_NEWLINE` compiler warning (Chuck Shnider)

 * Fix a format string missing argument issue in tests (Kyle Fuller)

 * Fix location of certificate chain bundle location (Kyle Fuller)

 * Fix memory leaks in AFSecurityPolicyTests (Kyle Fuller)

 * Fix potential concurrency issues in `AFURLSessionManager` by adding locks
around access to mutiple delegates dictionary (Mattt Thompson)

 * Fix unused variable compiler warnings by wrapping `OSStatus` and
`NSCAssert` with NS_BLOCK_ASSERTIONS macro (Mattt Thompson)

 * Fix compound serializer error handling (Mattt Thompson)

 * Fix string encoding for responseString (Juan Enrique)

 * Fix `UIImageView -setBackgroundImageWithRequest:` (Taichiro Yoshida)

 * Fix regressions nested multipart parameters (Mattt Thompson)

 * Add `responseObject` property to `AFHTTPRequestOperation` (Mattt Thompson)

 * Add support for automatic network reachability monitoring for request
operation and session managers (Mattt Thompson)

 * Update documentation and README with various corrections and fixes
(@haikusw, Chris Hellmuth, Dave Caunt, Mattt Thompson)

 * Update default User-Agent such that only ASCII character set is used
(Maximillian Dornseif)

 * Update SSL pinning mode to have default pinned certificates by default
(Kevin Harwood)

 * Update `AFSecurityPolicy` to use default authentication handling unless a
credential exists for the server trust (Mattt Thompson)

 * Update Prefix.pch (Steven Fisher)

 * Update minimum iOS test target to iOS 6

 * Remove unused protection space block type (Kyle Fuller)

 * Remove unnecessary Podfile.lock (Kyle Fuller)

## [2.0.0](https://github.com/AFNetworking/AFNetworking/releases/tag/2.0.0) (2013-09-27)

* Initial 2.0.0 Release

====================
#AFNetworking 1.0 Change Log
--

## [1.3.4](https://github.com/AFNetworking/AFNetworking/releases/tag/1.3.4) (2014-04-15)

 * Fix `AFHTTPMultipartBodyStream` to randomly generate form boundary, to
prevent attack based on a known value (Mathias Bynens, Tom Van Goethem, Mattt
Thompson)

 * Fix potential non-terminating loop in `connection:didReceiveData:` (Mattt
Thompson)

 * Fix SSL certificate validation to provide a human readable Warning when
SSL Pinning fails (Maximillian Dornseif)

 * Fix SSL certificate validation  to assert that no impossible pinning
configuration exists (Maximillian Dornseif)

 * Fix to check `CFStringTransform()` call for success before using result
(Kevin Cassidy Jr)

 * Fix to prevent unused assertion results with macros (Indragie Karunaratne)

 * Fix to call call `SecTrustEvaluate` before calling
`SecTrustGetCertificateCount` in SSL certificate validation (Josh Chung)

 * Fix to add explicit cast to `NSUInteger` in format string (Alexander
Kempgen)

 * Remove unused variable `kAFStreamToStreamBufferSize` (Alexander Kempgen)

## [1.3.3](https://github.com/AFNetworking/AFNetworking/releases/tag/1.3.3) (2013-09-25)

 * Add stream error handling to `AFMultipartBodyStream` (Nicolas Bachschmidt,
Mattt Thompson)

 * Add stream error handling to `AFURLConnectionOperation
-connection:didReceiveData:` (Ian Duggan, Mattt Thompson)

 * Fix parameter query string encoding of square brackets according to RFC
3986 (Kra Larivain)

 * Fix AFHTTPBodyPart determination of end of input stream data (Brian Croom)

 * Fix unit test timeouts (Carson McDonald)

 * Fix truncated `User-Agent` header field when app contained non-ASCII
characters (Diego Torres)

 * Fix outdated link in documentation (Jonas Schmid)

 * Fix `AFHTTPRequestOperation` `HTTPError` property to be thread-safe
(Oliver Letterer, Mattt Thompson)

 * Fix API compatibility with iOS 5 (Blake Watters, Mattt Thompson)

 * Fix potential race condition in `AFURLConnectionOperation
-cancelConnection` (@mm-jkolb, Mattt Thompson)

 * Remove implementation of `connection:needNewBodyStream:` delegate method
in `AFURLConnectionOperation`, which fixes stream errors on authentication
challenges (Mattt Thompson)

 * Fix calculation of network reachability from flags (Tracy Pesin, Mattt
Thompson)

 * Update AFHTTPClient documentation to clarify scope of `parameterEncoding`
property (Thomas Catterall)

 * Update `UIImageView` category to allow for nested calls to
`setImageWithURLRequest:` (Philippe Converset)

  * Change `UIImageView` category to accept invalid SSL certificates when
`_AFNETWORKING_ALLOW_INVALID_SSL_CERTIFICATES_` is defined (Flávio Caetano)

 * Change to replace #pragma clang with cast (Cédric Luthi)

## [1.3.2](https://github.com/AFNetworking/AFNetworking/releases/tag/1.3.2) (2013-08-08)

 * Add return status checks when building list of pinned public keys (Sylvain
Guillope)

 * Add return status checks when handling connection authentication challenges
(Sylvain Guillope)

 * Add tests around `AFHTTPClient initWithBaseURL:` (Kyle Fuller)

 * Change to remove all `_AFNETWORKING_PIN_SSL_CERTIFICATES_` conditional
compilation (Dustin Barker)

 * Change to allow fallback to generic image loading when PNG/JPEG data
provider methods fail (Darryl H. Thomas)

 * Change to only set placeholder image if not `nil` (Mattt Thompson)

 * Change to use `response.MIMEType` rather than (potentially nonexistent)
Content-Type headers to determine image data provider (Mattt Thompson)

 * Fix image request test endpoint (Carson McDonald)

 * Fix compiler warning caused by `size_t` value defaulted to `NULL` (Darryl H.
Thomas)

 * Fix mutable headers property in `AFHTTPClient -copyWithZone:` (Oliver
Letterer)

 * Fix documentation and asset references in README (Romain Pouclet, Peter
Goldsmith)

 * Fix bug in examples always using `AFSSLPinningModeNone` (Dustin Barker)

 * Fix execution of tests under Travis (Blake Watters)

 * Fix static analyzer warnings about CFRelease calls to NULL pointer (Mattt
Thompson)

 * Change to return early in `AFGetMediaTypeAndSubtypeWithString` if string is
`nil` (Mattt Thompson)

 * Change to opimize network thread creation (Mattt Thompson)

## [1.3.1](https://github.com/AFNetworking/AFNetworking/releases/tag/1.3.1) (2013-06-18)

 * Add `automaticallyInflatesResponseImage` property to
`AFImageRequestOperation`, which when enabled, offers significant performance
improvements for drawing images loaded through `UIImageView+AFNetworking` by
inflating compressed image data in the background (Mattt Thompson, Peter
Steinberger)

 * Add `NSParameterAssert` check for `nil` `urlRequest` parameter in
`AFURLConnectionOperation` initializer (Kyle Fuller)

 * Fix reachability to detect the case where a connection is required but can
be automatically established (Joshua Vickery)

 * Fix to Test target Podfile (Kyle Fuller)

## [1.3.0](https://github.com/AFNetworking/AFNetworking/releases/tag/1.3.0)  (2013-06-01)

 * Change in `AFURLConnectionOperation` `NSURLConnection` authentication
delegate methods and associated block setters. If
`_AFNETWORKING_PIN_SSL_CERTIFICATES_` is defined,
`-setWillSendRequestForAuthenticationChallengeBlock:` will be available, and
`-connection:willSendRequestForAuthenticationChallenge:` will be implemented.
Otherwise, `-setAuthenticationAgainstProtectionSpaceBlock:` &
`-setAuthenticationChallengeBlock:` will be available, and
`-connection:canAuthenticateAgainstProtectionSpace:` &
`-connection:didReceiveAuthenticationChallenge:` will be implemented instead
(Oliver Letterer)

 * Change in AFNetworking podspec to include Security framework (Kevin Harwood,
Oliver Letterer, Sam Soffes)

 * Change in AFHTTPClient to @throw exception when non-designated intializer is
used (Kyle Fuller)

 * Change in behavior of connection:didReceiveAuthenticationChallenge: to not
use URL-encoded credentials, which should already have been applied (@xjdrew)

 * Change to set AFJSONRequestOperation error when unable to decode response
string (Chris Pickslay, Geoff Nix)

 * Change AFURLConnectionOperation to lazily initialize outputStream property
(@fumoboy007)

 * Change instances of (CFStringRef)NSRunLoopCommonModes to
kCFRunLoopCommonModes

 * Change #warning to #pragma message for dynamic framework linking warnings
(@michael_r_may)

 * Add unit testing and continuous integration system (Blake Watters, Oliver
Letterer, Kevin Harwood, Cédric Luthi, Adam Fraser, Carson McDonald, Mattt
Thompson)

 * Fix multipart input stream implementation (Blake Watters, OliverLetterer,
Aleksey Kononov, @mattyohe, @mythodeia, @JD-)

 * Fix implementation of authentication delegate methods (Oliver Letterer,
Kevin Harwood)

 * Fix implementation of AFSSLPinningModePublicKey on Mac OS X (Oliver Letterer)

 * Fix error caused by loading file:// requests with AFHTTPRequestOperation
subclasses (Dave Anderson, Oliver Letterer)

 * Fix threading-related crash in AFNetworkActivityIndicatorManager (Dave Keck)

 * Fix to suppress GNU expression and enum assignment warnings from Clang
(Henrik Hartz)

 * Fix leak caused by CFStringConvertEncodingToIANACharSetName in AFHTTPClient
-requestWithMethod:path:parameters: (Daniel Demiss)

 * Fix missing __bridge casts in AFHTTPClient (@apouche, Mattt Thompson)

 * Fix Objective-C++ compatibility (Audun Holm Ellertsen)

 * Fix to not escape tildes (@joein3d)

 * Fix warnings caused by unsynthesized properties (Jeff Hunter)

 * Fix to network reachability calls to provide correct  status on
initialization (@djmadcat, Mattt Thompson)

 * Fix to suppress warnings about implicit signedness conversion (Matt Rubin)

 * Fix AFJSONRequestOperation -responseJSON failing cases (Andrew Vyazovoy,
Mattt Thompson)

 * Fix use of object subscripting to avoid incompatibility with iOS < 6 and OS
X < 10.8 (Paul Melnikow)

 * Various fixes to reverted multipart stream provider implementation (Yaron
Inger, Alex Burgel)

## [1.2.1](https://github.com/AFNetworking/AFNetworking/releases/tag/1.2.1) (2013-04-18)

 * Add `allowsInvalidSSLCertificate` property to `AFURLConnectionOperation` and
`AFHTTPClient`, replacing `_AFNETWORKING_ALLOW_INVALID_SSL_CERTIFICATES_` macro
(Kevin Harwood)

 * Add SSL pinning mode to example project (Kevin Harwood)

 * Add name to AFNetworking network thread (Peter Steinberger)

 * Change pinned certificates to trust all derived certificates (Oliver
Letterer)

 * Fix documentation about SSL pinning (Kevin Harwood, Mattt Thompson)

 * Fix certain enumerated loops to use fast enumeration, resulting in better
performance (Oliver Letterer)

 * Fix macro to work correctly under Mac OS X 10.7 and iOS 4 SDK (Paul Melnikow)

 * Fix documentation, removing unsupported `@discussion` tags (Michele Titolo)

 * Fix `SecTrustCreateWithCertificates` expecting an array as first argument
(Oliver Letterer)

 * Fix to use `errSecSuccess` instead of `noErr` for Security frameworks
OSStatus (Oliver Letterer)

 * Fix `AFImageRequestOperation` to use `[self alloc]` instead of explicit
class, which allows for subclassing (James Clarke)

 * Fix for `numberOfFinishedOperations` calculations (Rune Madsen)

 * Fix calculation of data length in `-connection:didReceiveData:`
(Jean-Francois Morin)

 * Fix to encode JSON only with UTF-8, following recommendation of
`NSJSONSerialiation` (Sebastian Utz)

## [1.2.0](https://github.com/AFNetworking/AFNetworking/releases/tag/1.2.0) (2013-03-24)

 * Add `SSLPinningMode` property to `AFHTTPClient` (Oliver Letterer, Kevin
Harwood, Adam Becevello, Dustin Barker, Mattt Thompson)

 * Add single quote ("'"), comma (","), and asterix ("*") to escaped URL
encoding characters (Eric Florenzano, Marc Nijdam, Garrett Murray)

 * Add `credential` property to `AFURLConnectionOperation` (Mattt Thompson)

 * Add `-setDefaultCredential:` to `AFHTTPClient`

 * Add `shouldUseCredentialStorage` property to `AFURLConnectionOperation`
(Mattt Thompson)

 * Add support for repeated key value pairs in `AFHTTPClient` URL query string
(Nick Dawson)

 * Add `AFMultipartFormData -
appendPartWithFileURL:name:fileName:mimeType:error` (Daniel Rodríguez Troitiño)

 * Add `AFMultipartFormData -
appendPartWithInputStream:name:fileName:mimeType:` (@joein3d)

 * Change SSL pinning to be runtime property on `AFURLConnectionOperation`
rather than defined by macro (Oliver Letterer)

 * Change `AFMultipartBodyStream` to `AFMultipartBodyStreamProvider`, vending
one side of a bound CFStream pair rather than subclassing `NSInputStream` (Mike
Ash)

 * Change default `Accept-Language` header in `AFHTTPClient` (@therigu, Mattt
Thompson)

 * Change `AFHTTPClient` operation cancellation to be based on request URL path
rather than absolute URL string (Mattt Thompson)

 * Change request operation subclass processing queues to use
`DISPATCH_QUEUE_CONCURRENT` (Mattt Thompson)

 * Change `UIImageView+AFNetworking` to resolve asymmetry in cached image case
between success block provided and not provided (@Eveets, Mattt Thompson)

 * Change `UIImageView+AFNetworking` to compare `NSURLRequest` instead of
`NSURL` to determine if previous request was equivalent (Cédric Luthi)

 * Change `UIImageView+AFNetworking` to only set image if non-`nil` (Sean
Kovacs)

 * Change indentation settings to four spaces at the project level (Cédric
Luthi)

 * Change `AFNetworkActivityIndicatorManager` to only update if requests have a
non-`nil` URL (Cédric Luthi)

 * Change `UIImageView+AFNetworking` to not do `setHTTPShouldHandleCookies`
(Konstantinos Vaggelakos)

 * Fix request stream exhaustion error on authentication challenges (Alex
Burgel)

 * Fix implementation to use `NSURL` methods instead of `CFURL` functions where
applicable (Cédric Luthi)

 * Fix race condition in `UIImageView+AFNetworking` (Peyman)

 * Fix `responseJSON`, `responseString`, and `responseStringEncoding` to be
threadsafe (Jon Parise, Mattt Thompson)

 * Fix `AFContentTypeForPathExtension` to ensure non-`NULL` content return
value (Zach Waugh)

 * Fix documentation for `appendPartWithFileURL:name:error:`
 (Daniel Rodríguez Troitiño)

 * Fix request operation subclass processing queues to initialize with
`dispatch_once` (Sasmito Adibowo)

 * Fix posting of `AFNetworkingOperationDidStartNotification` and
`AFNetworkingOperationDidFinishNotification` to avoid crashes when logging in
response to notifications (Blake Watters)

 * Fix ordering of registered operation consultation in `AFHTTPClient` (Joel
Parsons)

 * Fix warning: multiple methods named 'postNotificationName:object:' found
[-Wstrict-selector-match] (Oliver Jones)

 * Fix warning: multiple methods named 'objectForKey:' found
[-Wstrict-selector-match] (Oliver Jones)

 * Fix warning: weak receiver may be unpredictably set to nil
[-Wreceiver-is-weak] (Oliver Jones)

 * Fix missing #pragma clang diagnostic pop (Steven Fisher)

## [1.1.0](https://github.com/AFNetworking/AFNetworking/releases/tag/1.1.0) (2012-12-27)

 * Add optional SSL certificate pinning with `#define
_AFNETWORKING_PIN_SSL_CERTIFICATES_` (Dustin Barker)

 * Add `responseStringEncoding` property to `AFURLConnectionOperation` (Mattt
Thompson)

 * Add `userInfo` property to `AFURLConnectionOperation` (Mattt Thompson,
Steven Fisher)

 * Change behavior to cause a failure when an operation is cancelled (Daniel
Tull)

 * Change return type of class constructors to `instancetype` (@guykogus)

 * Change notifications to always being posted on an asynchronously-dispatched
block run on the main queue (Evadne Wu, Mattt Thompson)

 * Change from NSLocalizedString to NSLocalizedStringFromTable with
AFNetworking.strings table for localized strings (Cédric Luthi)

 * Change `-appendPartWithHeaders:body:` to add assertion handler for existence
of body data parameter (Jonathan Beilin)

 * Change `AFHTTPRequestOperation -responseString` to follow guidelines from
RFC 2616 regarding the use of string encoding when none is specified in the
response (Jorge Bernal)

 * Change AFHTTPClient parameter serialization dictionary keys with
`caseInsensitiveCompare:` to ensure
 deterministic ordering of query string parameters, which may otherwise
 cause ambiguous representations of nested parameters (James Coleman,
 Mattt Thompson)

 * Fix -Wstrict-selector-match warnings raised by Xcode 4.6DP3 (Jesse Collis,
Cédric Luthi)

 * Fix NSJSONSerialization crash with Unicode character escapes in JSON
response (Mathijs Kadijk)

 * Fix issue with early return in -startMonitoringNetworkReachability if
network reachability object could not be created (i.e. invalid hostnames)
(Basil Shkara)

 * Fix retain cycles in AFImageRequestOperation.m and AFHTTPClient.m caused by
strong references within blocks (Nick Forge)

 * Fix issue caused by Rails behavior of returning a single space in head :ok
responses, which is interpreted as invalid (Sebastian Ludwig)

 * Fix issue in streaming multipart upload, where final encapsulation boundary
would not be appended if it was larger than the available buffer, causing a
potential timeout (Tomohisa Takaoka, David Kasper)

 * Fix memory leak of network reachability callback block (Mattt Thompson)

 * Fix `-initWithCoder:` for `AFURLConnectionOperation` and `AFHTTPClient` to
cast scalar types (Mattt Thompson)

 * Fix bug in `-enqueueBatchOfHTTPRequestOperations:...` to by using
`addOperations:waitUntilFinished:` instead of adding each operation
individually. (Mattt Thompson)

 * Change `#warning` messages of checks for `CoreServices` and
`MobileCoreServices` to message according to the build target platform (Mattt
Thompson)

 * Change `AFQueryStringFromParametersWithEncoding` to create keys string
representations using the description method as specified in documentation
(Cédric Luthi)

 * Fix __unused keywords for better Xcode indexing (Christian Rasmussen)

 * Fix warning: unused parameter 'x' [-Werror,-Wunused-parameter] (Oliver Jones)

 * Fix warning: property is assumed atomic by default
[-Werror,-Wimplicit-atomic-properties] (Oliver Jones)

 * Fix warning: weak receiver may be unpredictably null in ARC mode
[-Werror,-Wreceiver-is-weak] (Oliver Jones)

 * Fix warning: multiple methods named 'selector' found
[-Werror,-Wstrict-selector-match] (Oliver Jones)

 * Fix warning: 'macro' is not defined, evaluates to 0 (Oliver Jones)

 * Fix warning: atomic by default property 'X' has a user (Oliver Jones)defined
getter (property should be marked 'atomic' if this is intended) [-Werror,
-Wcustom-atomic-properties] (Oliver Jones)

 * Fix warning: 'response' was marked unused but was used
[-Werror,-Wused-but-marked-unused] (Oliver Jones)

 * Fix warning: enumeration value 'AFFinalBoundaryPhase' not explicitly handled
in switch [-Werror,-Wswitch-enum] (Oliver Jones)

## [1.0.1](https://github.com/AFNetworking/AFNetworking/releases/tag/1.0.1) / 2012-11-01

 * Fix error in multipart upload streaming, where byte range at boundaries
was not correctly calculated (Stan Chang Khin Boon)

 * If a success block is specified to `UIImageView -setImageWithURLRequest:
placeholderImage:success:failure`:, it is now the responsibility of the
block to set the image of the image view (Mattt Thompson)

 * Add `JSONReadingOptions` property to `AFJSONRequestOperation` (Jeremy
 Foo, Mattt Thompson)

 * Using __weak self / __strong self pattern to break retain cycles in
 background task and network reachability blocks (Jerry Beers, Dan Weeks)

 * Fix parameter encoding to leave period (`.`) unescaped (Diego Torres)

 * Fixing last file component in multipart form part creation (Sylver
 Bruneau)

 * Remove executable permission on AFHTTPClient source files (Andrew
 Sardone)

 * Fix warning (error with -Werror) on implicit 64 to 32 conversion (Dan
 Weeks)

 * Add GitHub's .gitignore file (Nate Stedman)

 * Updates to README (@ckmcc)

## [1.0](https://github.com/AFNetworking/AFNetworking/releases/tag/1.0) / 2012-10-15

 * AFNetworking now requires iOS 5 / Mac OSX 10.7 or higher (Mattt Thompson)

 * AFNetworking now uses Automatic Reference Counting (ARC) (Mattt Thompson)

 * AFNetworking raises compiler warnings for missing features when
SystemConfiguration or  CoreServices / MobileCoreServices frameworks are not
included in the project and imported in the precompiled headers (Mattt
Thompson)

 * AFNetworking now raises compiler error when not compiled with ARC (Steven
Fisher)

 * Add `NSCoding` and `NSCopying` protocol conformance to
`AFURLConnectionOperation` and `AFHTTPClient` (Mattt Thompson)

 * Add substantial improvements HTTP multipart streaming support, having
files streamed directly from disk and read sequentially from a custom input
stream (Max Lansing, Stan Chang Khin Boon, Mattt Thompson)

 * Add `AFMultipartFormData -throttleBandwidthWithPacketSize:delay:` as
workaround to issues when uploading over 3G (Mattt Thompson)

 * Add request and response to `userInfo` of errors returned from failing
`AFHTTPRequestOperation` (Mattt Thompson)

 * Add `userInfo` dictionary with current status in reachability changes
(Mattt Thompson)

 * Add `Accept` header for image requests in `UIImageView` category (Bratley
Lower)

 * Add explicit declaration of `NSURLConnection` delegate methods so that
they can be overridden in subclasses (Mattt Thompson, Evan Grim)

 * Add parameter validation to match conditions specified in documentation
(Jason Brennan, Mattt Thompson)

 * Add import to `UIKit` to avoid build errors from `UIDevice` references in
`User-Agent` default header (Blake Watters)

 * Remove `AFJSONUtilities` in favor of `NSJSONSerialization` (Mattt Thompson)

 * Remove `extern` declaration of `AFURLEncodedStringFromStringWithEncoding`
function (`CFURLCreateStringByAddingPercentEscapes` should be used instead)
(Mattt Thompson)

 * Remove `setHTTPShouldHandleCookies:NO` from `AFHTTPClient` (@phamsonha,
Mattt Thompson)

 * Remove `dispatch_retain` / `dispatch_release` with ARC in iOS 6 (Benoit
Bourdon)

 * Fix threading issue with `AFNetworkActivityIndicatorManager` (Eric Patey)

 * Fix issue where `AFNetworkActivityIndicatorManager` count could become
negative (@ap4y)

 * Fix properties to explicitly set options to suppress warnings (Wen-Hao
Lue, Mattt Thompson)

 * Fix compiler warning caused by mismatched types in upload / download
progress blocks (Gareth du Plooy, tomas.a)

 * Fix weak / strong variable relationships in `completionBlock` (Peter
Steinberger)

 * Fix string formatting syntax warnings caused by type mismatch (David
Keegan, Steven Fisher, George Cox)

 * Fix minor potential security vulnerability by explicitly using string
format in NSError localizedDescription value in userInfo (Steven Fisher)

 * Fix `AFURLConnectionOperation -pause` by adding state checks to prevent
likely memory issues when resuming (Mattt Thompson)

 * Fix warning caused by miscast of type when
`CLANG_WARN_IMPLICIT_SIGN_CONVERSION` is set (Steven Fisher)

 * Fix incomplete implementation warning in example code (Steven Fisher)

 * Fix warning caused by using `==` comparator on floats (Steven Fisher)

 * Fix iOS 4 bug where file URLs return `NSURLResponse` rather than
`NSHTTPURLResponse` objects (Leo Lobato)

 * Fix calculation of finished operations in batch operation progress
callback (Mattt Thompson)

 * Fix documentation typos (Steven Fisher, Matthias Wessendorf,
jorge@miv.uk.com)

 * Fix `hasAcceptableStatusCode` to return true after a network failure (Tony
Million)

 * Fix warning about missing prototype for private static method (Stephan
Diederich)

 * Fix issue where `nil` content type resulted in unacceptable content type
(Mattt Thompson)

 * Fix bug related to setup and scheduling of output stream (Stephen Tramer)

 * Fix AFContentTypesFromHTTPHeader to correctly handle comma-delimited
content types (Peyman, Mattt Thompson, @jsm174)

 * Fix crash caused by `_networkReachability` not being set to `NULL` after
releasing (Blake Watters)

 * Fix Podspec to correctly import required headers and use ARC (Eloy Durán,
Blake Watters)

 * Fix query string parameter escaping to leave square brackets unescaped
(Mattt Thompson)

 * Fix query string parameter encoding of `NSNull` values (Daniel Rinser)

 * Fix error caused by referencing `__IPHONE_OS_VERSION_MIN_REQUIRED` without
importing `Availability.h` (Blake Watters)

 * Update example to use App.net API, as Twitter shut off its unauthorized
access to the public timeline (Mattt Thompson)

 * Update `AFURLConnectionOperation` to replace `NSAutoReleasePool` with
`@autoreleasepool` (Mattt Thompson)

 * Update `AFHTTPClient` operation queue to specify
`NSOperationQueueDefaultMaxConcurrentOperationCount` rather than
previously-defined constant (Mattt Thompson)

 * Update `AFHTTPClient -initWithBaseURL` to automatically append trailing
slash, so as to fix common issue where default path is not respected without
trailing slash (Steven Fisher)

 * Update default `AFHTTPClient` `User-Agent` header strings (Mattt Thompson,
Steven Fisher)

 * Update icons for iOS example application (Mattt Thompson)

 * Update `numberOfCompletedOperations` variable in progress block to be
renamed to `numberOfFinishedOperations` (Mattt Thompson)


## [0.10.0](https://github.com/AFNetworking/AFNetworking/releases/tag/0.10.0) / 2012-06-26

 * Add Twitter Mac Example application (Mattt Thompson)

 * Add note in README about how to set `-fno-objc-arc` flag for multiple files
 at once (Pål Brattberg)

 * Add note in README about 64-bit architecture requirement (@rmuginov, Mattt
 Thompson)

 * Add note in `AFNetworkActivityIndicatorManager` about not having to manually
 manage animation state (Mattt Thompson)

 * Add missing block parameter name for `imageProcessingBlock` (Francois
 Lambert)

 * Add NextiveJson to list of supported JSON libraries (Mattt Thompson)

 * Restore iOS 4.0 compatibility with `addAcceptableStatusCodes:` and
 `addAcceptableContentTypes:` (Zachary Waldowski)

 * Update `AFHTTPClient` to use HTTP pipelining for `GET` and `HEAD` requests by
 default (Mattt Thompson)

 * Remove @private ivar declaration in headers (Peter Steinberger, Mattt
 Thompson)

 * Fix potential premature deallocation of _skippedCharacterSet (Tom Wanielista,
 Mattt Thompson)

 * Fix potential issue in `setOutputStream` by closing any existing
 `outputStream` (Mattt Thompson)

 * Fix filename in AFHTTPClient header (Steven Fisher)

 * Fix documentation for UIImageView+AFNetworking (Mattt Thompson)

 * Fix HTTP multipart form format, which caused issues with Tornado web server
 (Matt Chen)

 * Fix `AFHTTPClient` to not append empty data into multipart form data (Jon
 Parise)

 * Fix URL encoding normalization to not conditionally escape percent-encoded
 strings (João Prado Maia, Kendall Helmstetter Gelner, @cysp, Mattt Thompson)

 * Fix `AFHTTPClient` documentation reference of
 `HTTPRequestOperationWithRequest:success:failure` (Shane Vitarana)

 * Add `AFURLRequestOperation -setRedirectResponseBlock:` (Kevin Harwood)

 * Fix `AFURLConnectionOperation` compilation error by conditionally importing
 UIKit framework (Steven Fisher)

 * Fix issue where image processing block is not called correctly with success
 block in `AFImageRequestOperation` (Sergey Gavrilyuk)

 * Fix leaked dispatch group in batch operations (@andyegorov, Mattt Thompson)

 * Fix support for non-LLVM compilers in `AFNetworkActivityIndicatorManager`
 (Abraham Vegh, Bill Williams, Mattt Thompson)

 * Fix AFHTTPClient to not add unnecessary data when constructing multipart form
 request with nil parameters (Taeho Kim)

## [1.0RC1](https://github.com/AFNetworking/AFNetworking/releases/tag/1.0RC1) / 2012-04-25

 * Add `AFHTTPRequestOperation +addAcceptableStatusCodes /
+addAcceptableContentTypes` to dynamically add acceptable status codes and
content types on the class level (Mattt Thompson)

 * Add support for compound and complex `Accept` headers that include multiple
content types and / or specify a particular character encoding (Mattt Thompson)

 * Add `AFURLConnectionOperation
-setShouldExecuteAsBackgroundTaskWithExpirationHandler:` to have operations
finish once an app becomes inactive (Mattt Thompson)

 * Add support for pausing / resuming request operations (Peter Steinberger,
Mattt Thompson)

 * Improve network reachability functionality in `AFHTTPClient`, including a
distinction between WWan and WiFi reachability (Kevin Harwood, Mattt Thompson)


## [0.9.2](https://github.com/AFNetworking/AFNetworking/releases/tag/0.9.2) / 2012-04-25

 * Add thread safety to `AFNetworkActivityIndicator` (Peter Steinberger, Mattt
Thompson)

 * Document requirement of available JSON libraries for decoding responses in
`AFJSONRequestOperation` and parameter encoding in `AFHTTPClient` (Mattt
Thompson)

 * Fix `AFHTTPClient` parameter encoding (Mattt Thompson)

 * Fix `AFJSONEncode` and `AFJSONDecode` to use `SBJsonWriter` and
`SBJsonParser` instead of `NSObject+SBJson` (Oliver Eikemeier)

 * Fix bug where `AFJSONDecode` does not return errors (Alex Michaud)

 * Fix compiler warning for undeclared
`AFQueryStringComponentFromKeyAndValueWithEncoding` function (Mattt Thompson)

 * Fix cache policy for URL requests (Peter Steinberger)

 * Fix race condition bug in `UIImageView+AFNetworking` caused by incorrectly
nil-ing request operations (John Wu)

 * Fix reload button in Twitter example (Peter Steinberger)

 * Improve batched operation by deferring execution of batch completion block
until all component request completion blocks have finished (Patrick Hernandez,
Kevin Harwood, Mattt Thompson)

 * Improve performance of image request decoding by dispatching to background
 queue (Mattt Thompson)

 * Revert `AFImageCache` to cache image objects rather than `NSPurgeableData`
(Tony Million, Peter Steinberger, Mattt Thompson)

 * Remove unnecessary KVO `willChangeValueForKey:` / `didChangeValueForKey:`
calls (Peter Steinberger)

 * Remove unnecessary @private ivar declarations in headers (Peter Steinberger,
Mattt Thompson)

 * Remove @try-@catch block wrapping network thread entry point (Charles T. Ahn)


## [0.9.1](https://github.com/AFNetworking/AFNetworking/releases/tag/0.9.1) / 2012-03-19

 * Create Twitter example application (Mattt Thompson)

 * Add support for nested array and dictionary parameters for query string and
form-encoded requests (Mathieu Hausherr, Josh Chung, Mattt Thompson)

 * Add `AFURLConnectionOperation -setCacheResponseBlock:`, which allows the
behavior of the `NSURLConnectionDelegate` method
`-connection:willCacheResponse:` to be overridden without subclassing (Mattt
Thompson)

 * Add `_AFNETWORKING_ALLOW_INVALID_SSL_CERTIFICATES_` macros for
NSURLConnection authentication delegate methods (Mattt Thompson)

 * Add properties for custom success / failure callback queues (Peter
Steinberger)

 * Add notifications for network reachability changes to `AFHTTPClient` (Mattt
Thompson)

 * Add `AFHTTPClient -patchPath:` convenience method (Mattt Thompson)

 * Add support for NextiveJson (Adrian Kosmaczewski)

 * Improve network reachability checks (C. Bess)

 * Improve NSIndexSet formatting in error strings (Jon Parise)

 * Document crashing behavior in iOS 4 loading a file:// URL (Mattt Thompson)

 * Fix crash caused by `AFHTTPClient -cancelAllHTTPOperationsWithMethod:` not
checking operation to be instance of `AFHTTPRequestOperation` (Mattt Thompson)

 * Fix crash caused by passing `nil` URL in requests (Sam Soffes)

 * Fix errors caused by connection property not being nil'd out after an
operation finishes (Kevin Harwood, @zdzisiekpu)

 * Fix crash caused by passing `NULL` error pointer when setting `NSInvocation`
in `AFJSONEncode` and `AFJSONDecode` (Tyler Stromberg)

 * Fix batch operation completion block returning on background thread (Patrick
Hernandez)

 * Fix documentation for UIImageView+AFNetworking (Dominic Dagradi)

 * Fix race condition caused by `AFURLConnectionOperation` being cancelled on
main thread, rather than network thread (Erik Olsson)

 * Fix `AFURLEncodedStringFromStringWithEncoding` to correctly handle cases
where % is used as a literal rather than as part of a percent escape code
(Mattt Thompson)

 * Fix missing comma in `+defaultAcceptableContentTypes` for
`AFImageRequestOperation` (Michael Schneider)


## [0.9.0](https://github.com/AFNetworking/AFNetworking/releases/tag/0.9.0) / 2012-01-23

 * Add thread-safe behavior to `AFURLConnectionOperation` (Mattt Thompson)

 * Add batching of operations for `AFHTTPClient` (Mattt Thompson)

 * Add authentication challenge callback block to override default
 implementation of `connection:didReceiveAuthenticationChallenge:` in
 `AFURLConnectionOperation` (Mattt Thompson)

 * Add `_AFNETWORKING_PREFER_NSJSONSERIALIZATION_`, which, when defined,
 short-circuits the standard preference ordering used in `AFJSONEncode` and
 `AFJSONDecode` to use `NSJSONSerialization` when available, falling back on
 third-party-libraries. (Mattt Thompson, Shane Vitarana)

 * Add custom `description` for `AFURLConnectionOperation` and `AFHTTPClient`
 (Mattt Thompson)

 * Add `text/javascript` to default acceptable content types for
 `AFJSONRequestOperation` (Jake Boxer)

 * Add `imageScale` property to change resolution of images constructed from
 cached data (Štěpán Petrů)

 * Add note about third party JSON libraries in README (David Keegan)

 * `AFQueryStringFromParametersWithEncoding` formats `NSArray` values in the
 form `key[]=value1&key[]=value2` instead of `key=(value1,value2)` (Dan Thorpe)

 * `AFImageRequestOperation -responseImage` on OS X uses `NSBitmapImageRep` to
 determine the correct pixel dimensions of the image (David Keegan)

 * `AFURLConnectionOperation` `connection` has memory management policy `assign`
 to avoid retain cycles caused by `NSURLConnection` retaining its delegate
 (Mattt Thompson)

 * `AFURLConnectionOperation` calls super implementation for `-isReady`,
 following the guidelines for `NSOperation` subclasses (Mattt Thompson)

 * `UIImageView -setImageWithURL:` and related methods call success callback
 after setting image (Cameron Boehmer)

 * Cancel request if an authentication challenge has no suitable credentials in
 `AFURLConnectionOperation -connection:didReceiveAuthenticationChallenge:`
 (Jorge Bernal)

 * Remove exception from
 `multipartFormRequestWithMethod:path:parameters:constructing BodyWithBlock:`
 raised when certain HTTP methods are used. (Mattt Thompson)

 * Remove `AFImageCache` from public API, moving it into private implementation
 of `UIImageView+AFNetworking` (Mattt Thompson)

 * Mac example application makes better use of AppKit technologies and
 conventions (Mattt Thompson)

 * Fix issue with multipart form boundaries in `AFHTTPClient
 -multipartFormRequestWithMethod:path:parameters:constructing BodyWithBlock:`
 (Ray Morgan, Mattt Thompson, Sam Soffes)

 * Fix "File Upload with Progress Callback" code snippet in README (Larry
Legend)

 * Fix to SBJSON invocations in `AFJSONEncode` and `AFJSONDecode` (Matthias
 Tretter, James Frye)

 * Fix documentation for `AFHTTPClient requestWithMethod:path:parameters:`
 (Michael Parker)

 * Fix `Content-Disposition` headers used for multipart form construction
 (Michael Parker)

 * Add network reachability status change callback property to `AFHTTPClient`.
 (Mattt Thompson, Kevin Harwood)

 * Fix exception handling in `AFJSONEncode` and `AFJSONDecode` (David Keegan)

 * Fix `NSData` initialization with string in `AFBase64EncodedStringFromString`
 (Adam Ernst, Mattt Thompson)

 * Fix error check in `appendPartWithFileURL:name:error:` (Warren Moore,
 Baldoph, Mattt Thompson)

 * Fix compiler warnings for certain configurations (Charlie Williams)

 * Fix bug caused by passing zero-length `responseData` to response object
 initializers (Mattt Thompson, Serge Paquet)
