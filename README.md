# AFNetworking
## A delightful iOS networking library with NSOperations and block-based callbacks
### There's a lot to be said for a networking library that you can wrap your head around. API design matters, too. Code at its best is poetry, and should be designed to delight (but never surprise).

AFNetworking was lovingly crafted to make best use of our favorite parts of Apple's `Foundation` framework: `NSOperation` for managing multiple concurrent requests, `NSURLRequest` & `NSHTTPURLResponse` to encapsulate state, `NSCache` & `NSURLCache` for performant and compliant cacheing behavior, and blocks to keep request / response handling code in a single logical unit in code.

If you're tired of massive libraries that try to do too much...  
If you've taken it upon yourself to roll your own hacky solution...  
If you want a library that _actually makes iOS networking code kinda fun_...  

...try out AFNetworking

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

### REST API Client Request

``` objective-c
// AFGowallaAPIClient is a subclass of AFRestClient, which defines the base URL and default HTTP headers for NSURLRequests it creates
[[AFGowallaAPIClient sharedClient] getPath:@"/spots/9223" parameters:nil success:^(id response) {
    NSLog(@"Name: %@", [response valueForKeyPath:@"name"]);
    NSLog(@"Address: %@", [response valueForKeyPath:@"address.street_address"]);
}];
```

### File Upload with Progress Callback

``` objective-c
NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://localhost:8080/upload"]];
NSData *imageData = UIImageJPEGRepresentation([UIImage imageNamed:@"avatar.jpg"], 0.5);
NSDictionary *parameters = [NSDictionary dictionaryWithObject:@"300x300" forKey:@"dimensions"];
[request setHTTPBodyWithData:imageData mimeType:@"image/jpeg" forParameterNamed:@"avatar" parameters:parameters useGzipCompression:YES];

AFHTTPRequestOperation *operation = [AFHTTPRequestOperation operationWithRequest:request completion:^(NSURLRequest *request, NSHTTPURLResponse *response, NSData *data, NSError *error) {
    NSLog(@"Upload Complete");
}];
[operation setProgressBlock:^(NSUInteger totalBytesWritten, NSUInteger totalBytesExpectedToWrite) {
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
AFHTTPRequestOperation *operation = [AFHTTPRequestOperation operationWithRequest:request inputStream:inputStream outputStream:outputStream completion:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
    NSLog(@"Streaming operation complete");
}];
```

## Example Project

In order to demonstrate the power and flexibility of AFNetworking, we've included a small sample project, which asks for your current location and displays [Gowalla](http://gowalla.com/) spots nearby you. It uses `AFJSONRequestOperation` to load and parse the spots JSON, and a category on `UIImageView` to asynchronously load spot stamp images as you scroll.

## Dependencies

* [iOS 4.0+](http://developer.apple.com/library/ios/#releasenotes/General/WhatsNewIniPhoneOS/Articles/iPhoneOS4.html%23//apple_ref/doc/uid/TP40009559-SW1) - AFNetworking uses blocks, which were introduced in iOS 4.
* If you're using iOS 5, AFJSONRequestOperation uses JSON will use the built-in NSJSONSerialization class to parse JSON responses. If this is not available, it falls back on [JSONKit](https://github.com/johnezang/JSONKit).
* If you include `NSData+AFNetworking.h` in your project, you will need to link against `libz.dylib`. To do this in Xcode 4, go to your project file, select your active target, and go to the "Build Phases" tab. Under "Link Binary With Libraries", click the "+" icon on the bottom left, and select "libz.dylib" from the list of available libraries.

## Credits

AFNetworking was created by [Scott Raymond](https://github.com/sco/) and [Mattt Thompson](https://github.com/mattt/) in the development of [Gowalla for iPhone](http://itunes.apple.com/us/app/gowalla/id304510106?mt=8).

[TTTLocationFormatter](), used in the example project, is part of [FormatterKit](https://github.com/mattt/FormatterKit), created by [Mattt Thompson](https://github.com/mattt/).

## License

AFNetworking is licensed under the MIT License:

  Copyright (c) 2011 Gowalla (http://gowalla.com/)

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in
  all copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
  THE SOFTWARE.