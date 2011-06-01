# AFNetworking
## A delightful iOS networking library with NSOperations and block-based callbacks

**There's a lot to be said for a networking library that you can wrap your head around. API design matters, too--code at its best is poetry, and should be designed to delight (but never surprise).**

AFNetworking was lovingly crafted to make best use of our favorite parts of Apple's `Foundation` framework: `NSOperation` for managing multiple concurrent requests, `NSURLRequest` & `NSHTTPURLResponse` to encapsulate state, `NSURLCache` for performant and compliant cacheing behavior, and blocks to keep HTTP request / response handling code in a single logical unit in code.

If you're tired of massive libraries that try to do too much, if you've taken it upon yourself to roll your own hacky solution, if you want a library that _actually makes iOS networking code kinda fun_, try out AFNetworking.

## Example Usage

### GET Request

    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://gowalla.com/users/mattt.json"]];
    AFCallback *callback = [AFHTTPOperationCallback callbackWithSuccess:^(NSURLRequest *request, NSHTTPURLResponse *response, NSDictionary *data) {
        NSLog(@"Name: %@ %@", [data valueForKeyPath:@"first_name"], [data valueForKeyPath:@"last_name"]);
    }];
    [[AFHTTPOperation operationWithRequest:request callback:callback] start];

### POST Request With HTTP Authorization Header Using `NSOperationQueue`

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://gowalla.com/friendships/request?user_id=1699"]];
    [request setHTTPMethod:@"POST"];

    NSDictionary *headers = [NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"Token token=\"%@\"", kOAuthToken] forKey:@"Authorization"];
    [request setAllHTTPHeaderFields:headers];
    
    AFCallback *callback = [AFHTTPOperationCallback callbackWithSuccess:^(NSURLRequest *request, NSHTTPURLResponse *response, NSDictionary *data) {
        NSLog(@"Friend Request Sent");;
    } error:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
        NSLog(@"[Error] (%@ %@) %@", [request HTTPMethod], [[request URL] relativePath], error);
    }];
    
    AFHTTPOperation *operation = [AFHTTPOperation operationWithRequest:request callback:callback];
    [[NSOperationQueue mainQueue] addOperation:operation];

### Image Request

    NSURL *imageURL = [NSURL URLWithString:@"http://s3.amazonaws.com/static.gowalla.com/users/1699-standard.jpg"];
    NSURLRequest *request = [NSURLRequest requestWithURL:imageURL];
    
    AFCallback *callback = [AFImageRequestOperationCallback callbackWithSuccess:^(UIImage *image) {
        self.imageView.image = image;
    } imageSize:CGSizeMake(50.0f, 50.0f) options:AFImageRequestResize | AFImageRequestRoundCorners];
    [[AFImageRequestOperation operationWithRequest:request callback:callback] start];
    
### REST Client Request

    // AFGowallaAPI is a subclass of AFRestClient, which defines the base URL and default HTTP  headers of NSURLRequests it creates
    [[AFGowallaAPI sharedClient] getPath:@"/spots/9223" parameters:nil callback:[AFHTTPOperationCallback callbackWithSuccess:^(NSURLRequest *request, NSHTTPURLResponse *response, NSDictionary *data) {
      NSLog(@"%@: %@", [data valueForKeyPath:@"name"], [data valueForKeyPath:@"address.street_address"]);
    }]];

## Example Project

In order to demonstrate the power and flexibility of AFNetworking, we've included a small sample project. `AFNetworkingExample` asks for your current location and displays [Gowalla](http://gowalla.com/) spots nearby you. It uses `AFHTTPOperation` to load and parse the spots JSON, and `AFImageRequestOperation` to asynchronously load spot stamp images as you scroll.

Take a close look at `AFGowallaAPI` and `AFImageRequest`. These two classes provide convenience methods on top of the core AFNetworking classes. They provide higher-level methods for creating requests, and enqueueing them into an `NSOperationQueue`.

## Dependencies

* [iOS 4](http://developer.apple.com/library/ios/#releasenotes/General/WhatsNewIniPhoneOS/Articles/iPhoneOS4.html%23//apple_ref/doc/uid/TP40009559-SW1) - `AFNetworking` uses blocks, which were introduced in iOS 4.
*  [QHTTPOperation](http://developer.apple.com/library/ios/#samplecode/MVCNetworking/Listings/Networking_QHTTPOperation_m.html) - Underneath `AFHTTPOperation` and `AFImageRequestOperation` is `QHTTPOperation`, an `NSOperation` subclass that manages `NSURLConnection` delegate methods. It's fairly robust, performant, and complete, so rather than roll our own, we built `AFNetworking` on top of this. We may build our own replacement if the need arises.
* [JSONKit](https://github.com/johnezang/JSONKit) - One of the conveniences built into `AFHTTPOperation` is automatic JSON parsing for HTTP requests that return content-type `application/json`. JSONKit is our preferred JSON parsing library, and is included in the example project.

## Credits

AFNetworking was created by [Scott Raymond](https://github.com/sco/) and [Mattt Thompson](https://github.com/mattt/) in the development of [Gowalla for iPhone](http://itunes.apple.com/us/app/gowalla/id304510106?mt=8).

QRunLoopOperation and QHTTPOperation were created by Apple DTS Engineers as a part of the sample code project [MVC Networking](http://developer.apple.com/library/ios/#samplecode/MVCNetworking/Introduction/Intro.html). See corresponding files for copyright and usage information.

[TTTLocationFormatter], used in the example project, was created by [Mattt Thompson](https://github.com/mattt/).

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