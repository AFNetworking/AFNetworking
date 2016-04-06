//: Playground - noun: a place where people can play

import UIKit
import AFNetworking

/*: Usage */

/*: AFURLSessionManager
 ### AFURLSessionManager

 `AFURLSessionManager` creates and manages an `NSURLSession` object based on a specified `NSURLSessionConfiguration` object, which conforms to `<NSURLSessionTaskDelegate>`, `<NSURLSessionDataDelegate>`, `<NSURLSessionDownloadDelegate>`, and `<NSURLSessionDelegate>`.
*/

//: #### Creating a Download Task

var configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
var manager = AFURLSessionManager(sessionConfiguration: configuration)

var url = NSURL(string: "http://example.com/download.zip")
var request = NSURLRequest(URL: url!)

var downloadTask = manager.downloadTaskWithRequest(request, progress: nil, destination: { (url: NSURL, response: NSURLResponse) -> NSURL in
    do {
        let documentsDirectoryURL = try NSFileManager.defaultManager()
            .URLForDirectory(NSSearchPathDirectory.DocumentDirectory, inDomain: NSSearchPathDomainMask.UserDomainMask, appropriateForURL:nil,
                create:false)
        return documentsDirectoryURL.URLByAppendingPathComponent(response.suggestedFilename!)
    } catch _ {
        print("error")
        abort()
    }
    }, completionHandler:  { (response: NSURLResponse, filePath: NSURL?, error: NSError?) in
        print("File downloaded to: \(filePath)");
})
downloadTask.resume()



//: #### Creating an Upload Task

configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
manager = AFURLSessionManager(sessionConfiguration: configuration)

url = NSURL(string: "http://example.com/upload")
request = NSURLRequest(URL: url!)

var filePath = NSURL(fileURLWithPath: "file://path/to/image.png")

var uploadTask = manager.uploadTaskWithRequest(request, fromFile: filePath, progress: nil, completionHandler:  { (response: NSURLResponse, responseObject: AnyObject?, error: NSError?) in
    if let error = error {
        print(error)
    } else {
        print("\(response) \(responseObject)");
    }
})
uploadTask.resume()



//: Creating an Upload Task for a Multi-Part Request, with Progress

request = AFHTTPRequestSerializer().multipartFormRequestWithMethod("POST", URLString: "http://example.com/upload", parameters: nil, constructingBodyWithBlock: { (formData: AFMultipartFormData) in
    do {
    try formData.appendPartWithFileURL(NSURL.fileURLWithPath("file://path/to/image.jpg"), name: "file", fileName: "filename.jpg", mimeType: "image/jpeg")
    } catch {}
    }, error: nil)

configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
manager = AFURLSessionManager(sessionConfiguration: configuration)

uploadTask = manager.uploadTaskWithStreamedRequest(request, progress: { (uploadProgress: NSProgress) in
    dispatch_async(dispatch_get_main_queue(), {
        // progressView.setProgress(uploadProgress.fractionCompleted)
    });
    }, completionHandler: { (response: NSURLResponse, responseObject: AnyObject?, error: NSError?) in
        if let error = error {
            print(error)
        } else {
            print("\(response) \(responseObject)");
        }
})
uploadTask.resume()



//: #### Creating a Data Task

configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
manager = AFURLSessionManager(sessionConfiguration: configuration)

url = NSURL(string: "http://httpbin.org/get")
request = NSURLRequest(URL: url!)


var dataTask = manager.dataTaskWithRequest(request, completionHandler:  { (response: NSURLResponse, responseObject: AnyObject?, error: NSError?) in
    if let error = error {
        print(error)
    } else {
        print("\(response) \(responseObject)");
    }
})
dataTask.resume()



//: --- 



//: ### Request Serialization

//: Request serializers create requests from URL strings, encoding parameters as either a query string or HTTP body.

var URLString = "http://example.com"
var parameters = ["foo": "bar", "baz": [1, 2, 3]]



//: #### Query String Parameter Encoding

AFHTTPRequestSerializer().requestWithMethod("GET", URLString: URLString, parameters: parameters, error: nil)

//: GET http://example.com?foo=bar&baz[]=1&baz[]=2&baz[]=3



//: #### URL Form Parameter Encoding

AFHTTPRequestSerializer().requestWithMethod("POST", URLString: URLString, parameters: parameters, error: nil)

/*:
 POST http://example.com/
 Content-Type: application/x-www-form-urlencoded

 foo=bar&baz[]=1&baz[]=2&baz[]=3
 */




//: #### JSON Parameter Encoding
AFJSONRequestSerializer().requestWithMethod("POST", URLString: URLString, parameters: parameters, error: nil)
/*:
 POST http://example.com/
 Content-Type: application/json

 {"foo": "bar", "baz": [1,2,3]}
 */



//: ---



//: ### Network Reachability Manager
/*:
 `AFNetworkReachabilityManager` monitors the reachability of domains, and addresses for both WWAN and WiFi network interfaces.

 * Do not use Reachability to determine if the original request should be sent.
	* You should try to send it.
 * You can use Reachability to determine when a request should be automatically retried.
	* Although it may still fail, a Reachability notification that the connectivity is available is a good time to retry something.
 * Network reachability is a useful tool for determining why a request might have failed.
	* After a network request has failed, telling the user they're offline is better than giving them a more technical but accurate error, such as "request timed out."

 See also [WWDC 2012 session 706, "Networking Best Practices."](https://developer.apple.com/videos/play/wwdc2012-706/).
 */



//: #### Shared Network Reachability

/*: 
 `AFSecurityPolicy` evaluates server trust against pinned X.509 certificates and public keys over secure connections.

 Adding pinned SSL certificates to your app helps prevent man-in-the-middle attacks and other vulnerabilities. Applications dealing with sensitive customer data or financial information are strongly encouraged to route all communication over an HTTPS connection with SSL pinning configured and enabled.
 */



//: #### Allowing Invalid SSL Certificates

manager = AFHTTPSessionManager()
manager.securityPolicy.allowInvalidCertificates = true; // not recommended for production


