# AFNetworking
## A delightful iOS networking library with NSOperations and block-based callbacks
### There's a lot to be said for a networking library that you can wrap your head around. API design matters, too. Code at its best is poetry, and should be designed to delight (but never surprise).

AFNetworking is lovingly crafted to make best use of our favorite parts of Apple's `Foundation` framework: `NSOperation` for managing multiple concurrent requests, `NSURLRequest` & `NSHTTPURLResponse` to encapsulate state, `NSCache` & `NSURLCache` for performant and compliant cacheing behavior, and blocks to keep request / response handling code in a single logical unit in code.

At its core is `AFHTTPRequestOperation`, a thin wrapper around `NSURLConnection`, which provides a block callback for when the operation completes. Everything else is built on top of that in a way that's completely modular: take what you need, leave what you don't.

If you're tired of massive libraries that try to do too much...  
If you've taken it upon yourself to roll your own hacky solution...  
If you want a library that _actually makes iOS networking code kinda fun_...  

...try out AFNetworking

## Documentation

Online documentation is available at http://gowalla.github.com/AFNetworking/. 

To install the docset directly into your local Xcode organizer, first [install `appledoc`](https://github.com/tomaz/appledoc), and then clone this project and run `appledoc -p AFNetworking -c "Gowalla" --company-id com.gowalla AFNetworking/*.h`

## Example Usage

### JSON Request

``` objective-c
NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://gowalla.com/users/mattt.json"]];
AFJSONRequestOperation *operation = [AFJSONRequestOperation operationWithRequest:request success:^(id JSON) {
    NSLog(@"Name: %@ %@", [JSON valueForKeyPath:@"first_name"], [JSON valueForKeyPath:@"last_name"]);
}];

NSOperationQueue *queue = [[[NSOperationQueue alloc] init] autorelease];
[queue addOperation:operation];
```

### Image Request

``` objective-c
UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 100.0f, 100.0f)];
    [imageView setImageWithURL:[NSURL URLWithString:@"http://i.imgur.com/r4uwx.jpg"] placeholderImage:[UIImage imageNamed:@"placeholder-avatar"]];
```

### API Client Request

``` objective-c
// AFGowallaAPIClient is a subclass of AFHTTPClient, which defines the base URL and default HTTP headers for NSURLRequests it creates
[[AFGowallaAPIClient sharedClient] getPath:@"/spots/9223" parameters:nil success:^(id response) {
    NSLog(@"Name: %@", [response valueForKeyPath:@"name"]);
    NSLog(@"Address: %@", [response valueForKeyPath:@"address.street_address"]);
} failure:nil];
```

### File Upload with Progress Callback

``` objective-c
NSData *imageData = UIImageJPEGRepresentation([UIImage imageNamed:@"avatar.jpg"], 0.5);
NSMutableURLRequest *request = [[AFHTTPClient sharedClient] multipartFormRequestWithMethod:@"POST" path:@"/upload" parameters:nil constructingBodyWithBlock: ^(id <AFMultipartFormData>formData) {
  [formData appendPartWithFormData:data name:@"avatar"]; 
}];

AFHTTPRequestOperation *operation = [AFHTTPRequestOperation operationWithRequest:request completion:^(NSURLRequest *request, NSHTTPURLResponse *response, NSData *data, NSError *error) {
    NSLog(@"Upload Complete");
}];

[operation setUploadProgressBlock:^(NSUInteger totalBytesWritten, NSUInteger totalBytesExpectedToWrite) {
    NSLog(@"Sent %d of %d bytes", totalBytesWritten, totalBytesExpectedToWrite);
}];

NSOperationQueue *queue = [[[NSOperationQueue alloc] init] autorelease];
[queue addOperation:operation];
```

### Request With HTTP Authorization Header

``` objective-c
NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://gowalla.com/friendships/request?user_id=1699"]];
[request setHTTPMethod:@"POST"];

NSDictionary *headers = [NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"Token token=\"%@\"", kOAuthToken] forKey:@"Authorization"];
[request setAllHTTPHeaderFields:headers];

AFHTTPRequestOperation *operation = [AFHTTPRequestOperation operationWithRequest:request completion:^(NSURLRequest *request, NSHTTPURLResponse *response, NSData *data, NSError *error) {
    BOOL HTTPStatusCodeIsAcceptable = [[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(200, 100)] containsIndex:[response statusCode]];
    if (HTTPStatusCodeIsAcceptable) {
        NSLog(@"Friend Request Sent");
    } else {
        NSLog(@"[Error]: (%@ %@) %@", [request HTTPMethod], [[request URL] relativePath], error);
    }
}];

NSOperationQueue *queue = [[[NSOperationQueue alloc] init] autorelease];
[queue addOperation:operation];
```

### Streaming Request

``` objective-c
NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://localhost:8080/encode"]];
NSInputStream *inputStream = [NSInputStream inputStreamWithFileAtPath:[[NSBundle mainBundle] pathForResource:@"large-image" ofType:@"tiff"]];
NSOutputStream *outputStream = [NSOutputStream outputStreamToMemory];
AFHTTPRequestOperation *operation = [AFHTTPRequestOperation streamingOperationWithRequest:request inputStream:inputStream outputStream:outputStream completion:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
    NSLog(@"Streaming operation complete");
}];
```

## Example Project

In order to demonstrate the power and flexibility of AFNetworking, we've included a small sample project, which asks for your current location and displays [Gowalla](http://gowalla.com/) spots nearby you. It uses `AFJSONRequestOperation` to load and parse the spots JSON, and a category on `UIImageView` to asynchronously load spot stamp images as you scroll.

## Dependencies

* [iOS 4.0+](http://developer.apple.com/library/ios/#releasenotes/General/WhatsNewIniPhoneOS/Articles/iPhoneOS4.html%23//apple_ref/doc/uid/TP40009559-SW1) - AFNetworking uses blocks, which were introduced in iOS 4.
* If you're using iOS 5, AFJSONRequestOperation uses JSON will use the built-in NSJSONSerialization class to parse JSON responses. If this is not available, it falls back on [JSONKit](https://github.com/johnezang/JSONKit).

### ARC Support

If you are including AFNetworking in a project with [Automatic Reference Counting (ARC)](http://clang.llvm.org/docs/AutomaticReferenceCounting.html) enabled, you will need to set the `-fno-objc-arc` compiler flag on all of the AFNetworking source files. To do this in Xcode, go to your active target and select the "Build Phases" tab. In the "Compiler Flags" column, set `-fno-objc-arc` for each of the AFNetworking source files.

This is certainly suboptimal, forking the project into an ARC and non-ARC branch would be extremely difficult to maintain. On the bright side, we're very excited about [CocoaPods](https://github.com/alloy/cocoapods), which is a promising solution to this and many other pain points.

### Mac OS X Support

Full support for OS X is planned for the very near future. In the meantime, you are perfectly safe to use `AFHTTPRequestOperation`, `AFJSONRequestOperation`, `AFHTTPClient`, and `AFNetworkActivityIndicatorManager`.

## Credits

AFNetworking was created by [Scott Raymond](https://github.com/sco/) and [Mattt Thompson](https://github.com/mattt/) in the development of [Gowalla for iPhone](http://itunes.apple.com/us/app/gowalla/id304510106?mt=8).

[TTTLocationFormatter](), used in the example project, is part of [FormatterKit](https://github.com/mattt/FormatterKit), created by [Mattt Thompson](https://github.com/mattt/).

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
