![AFNetworking](http://engineering.gowalla.com/AFNetworking/afnetworking-logo.png "AFNetworking")

## A delightful iOS and OS X networking framework
### There's a lot to be said for a networking library that you can wrap your head around. API design matters, too. Code at its best is poetry, and should be designed to delight (but never surprise).

AFNetworking is a delightful networking library for iOS and Mac OS X. It's built on top of familiar Foundation network classes, using `NSOperation` for scheduling and concurrency, and blocks for convenience and flexibility. It's designed to make common tasks easy, and to make complex tasks simple.

## Documentation

API documentation is available at [http://afnetworking.org/Documentation](http://afnetworking.org/Documentation).

To install the API docset directly into your local Xcode organizer, first [install `appledoc`](https://github.com/tomaz/appledoc), and then clone this project and run `appledoc -p AFNetworking -c "Alamofire" --company-id com.alamofire AFNetworking/*.h`

If you're looking for something more human-friendly, or more conceptual in nature, be sure to [check out the Wiki](https://github.com/AFNetworking/AFNetworking/wiki). 

## Example Projects

Be sure to download and run the example projects for iOS and Mac. Both example projects serve as models of how one might integrate AFNetworking into their own project.

## Example Usage

### JSON Request

``` objective-c
NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://gowalla.com/users/mattt.json"]];
AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
    NSLog(@"Name: %@ %@", [JSON valueForKeyPath:@"first_name"], [JSON valueForKeyPath:@"last_name"]);
} failure:nil];

NSOperationQueue *queue = [[[NSOperationQueue alloc] init] autorelease];
[queue addOperation:operation];
```

### XML Request

``` objective-c
NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://api.flickr.com/services/rest/?method=flickr.groups.browse&api_key=b6300e17ad3c506e706cb0072175d047&cat_id=34427469792%40N01&format=rest"]];
AFXMLRequestOperation *operation = [AFXMLRequestOperation XMLParserRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, NSXMLParser *XMLParser) {
  XMLParser.delegate = self;
  [XMLParser parse];
} failure:nil];

NSOperationQueue *queue = [[[NSOperationQueue alloc] init] autorelease];
[queue addOperation:operation];
```

### Image Request

``` objective-c
UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 100.0f, 100.0f)];
[imageView setImageWithURL:[NSURL URLWithString:@"http://i.imgur.com/r4uwx.jpg"] placeholderImage:[UIImage imageNamed:@"placeholder-avatar"]];
```

``` objective-c
NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://gowalla.com/images/web/logo.png"]];
AFImageRequestOperation *operation = [AFImageRequestOperation imageRequestOperationWithRequest:request success:^(NSImage *image){
    NSLog(@"Image loaded: %@", image);
}];
NSOperationQueue *queue = [[[NSOperationQueue alloc] init] autorelease];
[queue addOperation:operation];
```

### API Client Request

``` objective-c
// AFGowallaAPIClient is a subclass of AFHTTPClient, which defines the base URL and default HTTP headers for NSURLRequests it creates
[[AFGowallaAPIClient sharedClient] getPath:@"/spots/9223" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
    NSLog(@"Name: %@", [responseObject valueForKeyPath:@"name"]);
    NSLog(@"Address: %@", [responseObject valueForKeyPath:@"address.street_address"]);
} failure:nil];
```

### File Upload with Progress Callback

``` objective-c
NSURL *url = [NSURL URLWithString:@"http://api-base-url.com"];
AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:url];
NSData *imageData = UIImageJPEGRepresentation([UIImage imageNamed:@"avatar.jpg"], 0.5);
NSMutableURLRequest *request = [httpClient multipartFormRequestWithMethod:@"POST" path:@"/upload" parameters:nil constructingBodyWithBlock: ^(id <AFMultipartFormData>formData) {
    [formData appendPartWithFileData:imageData name:@"avatar" fileName:@"avatar.jpg" mimeType:@"image/jpeg"];
}];

AFHTTPRequestOperation *operation = [[[AFHTTPRequestOperation alloc] initWithRequest:request] autorelease];
[operation setUploadProgressBlock:^(NSInteger bytesWritten, NSInteger totalBytesWritten, NSInteger totalBytesExpectedToWrite) {
    NSLog(@"Sent %d of %d bytes", totalBytesWritten, totalBytesExpectedToWrite);
}];

NSOperationQueue *queue = [[[NSOperationQueue alloc] init] autorelease];
[queue addOperation:operation];
```

### Request With HTTP Authorization Header

``` objective-c
NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://gowalla.com/friendships/request?user_id=1699"]];
[request setHTTPMethod:@"POST"];
[request setValue:@"#{Base64-Encoded Credentials}" forHTTPHeaderField:@"Authorization"];

AFHTTPRequestOperation *operation = [[[AFHTTPRequestOperation alloc] initWithRequest:request] autorelease];
operation.completionBlock = ^ {
    if ([operation hasAcceptableStatusCode]) {
        NSLog(@"Friend Request Sent");
    } else {
        NSLog(@"[Error]: (%@ %@) %@", [operation.request HTTPMethod], [[operation.request URL] relativePath], operation.error);
    }
};

NSOperationQueue *queue = [[[NSOperationQueue alloc] init] autorelease];
[queue addOperation:operation];
```

### Streaming Request

``` objective-c
NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://localhost:8080/encode"]];

AFHTTPRequestOperation *operation = [[[AFHTTPRequestOperation alloc] initWithRequest:request] autorelease];
operation.inputStream = [NSInputStream inputStreamWithFileAtPath:[[NSBundle mainBundle] pathForResource:@"large-image" ofType:@"tiff"]];
operation.outputStream = [NSOutputStream outputStreamToMemory];

NSOperationQueue *queue = [[[NSOperationQueue alloc] init] autorelease];
[queue addOperation:operation];
```

## Requirements

AFNetworking requires either [iOS 4.0](http://developer.apple.com/library/ios/#releasenotes/General/WhatsNewIniPhoneOS/Articles/iPhoneOS4.html%23//apple_ref/doc/uid/TP40009559-SW1) and above, or [Mac OS 10.6](http://developer.apple.com/library/mac/#releasenotes/MacOSX/WhatsNewInOSX/Articles/MacOSX10_6.html#//apple_ref/doc/uid/TP40008898-SW7) and above.

AFNetworking uses [`NSJSONSerialization`](http://developer.apple.com/library/mac/#documentation/Foundation/Reference/NSJSONSerialization_Class/Reference/Reference.html) if it is available. If your app targets a platform where this class is not available you can include one of the following JSON libraries to your project for AFNetworking to automatically detect and use.

* [JSONKit](https://github.com/johnezang/JSONKit)
* [SBJson](http://stig.github.com/json-framework/)
* [YAJL](http://lloyd.github.com/yajl/)

### ARC Support

If you are including AFNetworking in a project that uses [Automatic Reference Counting (ARC)](http://clang.llvm.org/docs/AutomaticReferenceCounting.html) enabled, you will need to set the `-fno-objc-arc` compiler flag on all of the AFNetworking source files. To do this in Xcode, go to your active target and select the "Build Phases" tab. In the "Compiler Flags" column, set `-fno-objc-arc` for each of the AFNetworking source files.

Although this is suboptimal, forking the project into an ARC and non-ARC branch would be extremely difficult to maintain. On the bright side, we're very excited about [CocoaPods](https://github.com/alloy/cocoapods) as a potential solution.

## Credits

AFNetworking was created by [Scott Raymond](https://github.com/sco/) and [Mattt Thompson](https://github.com/mattt/) in the development of [Gowalla for iPhone](http://itunes.apple.com/us/app/gowalla/id304510106?mt=8).

[TTTLocationFormatter](), used in the example project, is part of [FormatterKit](https://github.com/mattt/FormatterKit), created by [Mattt Thompson](https://github.com/mattt/).

AFNetworking's logo was designed by the amazingly-talented [Alan Defibaugh](http://www.alandefibaugh.com/).

## Contact

Mattt Thompson

- http://github.com/mattt
- http://twitter.com/mattt
- m@mattt.me

Scott Raymond

- http://github.com/sco
- http://twitter.com/sco
- sco@gowalla.com

## License

AFNetworking is available under the MIT license. See the LICENSE file for more info.
