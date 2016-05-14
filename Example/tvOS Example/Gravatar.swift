// Gravatar.swift
//
// Copyright (c) 2011–2016 Alamofire Software Foundation ( http://alamofire.org/ )
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation
import UIKit

private extension String  {
    var md5_hash: String {
        let trimmedString = lowercaseString.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        let utf8String = trimmedString.cStringUsingEncoding(NSUTF8StringEncoding)!
        let stringLength = CC_LONG(trimmedString.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))
        let digestLength = Int(CC_MD5_DIGEST_LENGTH)
        let result = UnsafeMutablePointer<CUnsignedChar>.alloc(digestLength)

        CC_MD5(utf8String, stringLength, result)

        var hash = ""

        for i in 0..<digestLength {
            hash += String(format: "%02x", result[i])
        }

        result.dealloc(digestLength)

        return String(format: hash)
    }
}

// MARK: - QueryItemConvertible

private protocol QueryItemConvertible {
    var queryItem: NSURLQueryItem {get}
}

// MARK: -

public struct Gravatar {
    public enum DefaultImage: String, QueryItemConvertible {
        case HTTP404 = "404"
        case MysteryMan = "mm"
        case Identicon = "identicon"
        case MonsterID = "monsterid"
        case Wavatar = "wavatar"
        case Retro = "retro"
        case Blank = "blank"

        var queryItem: NSURLQueryItem {
            return NSURLQueryItem(name: "d", value: rawValue)
        }
    }

    public enum Rating: String, QueryItemConvertible {
        case G = "g"
        case PG = "pg"
        case R = "r"
        case X = "x"

        var queryItem: NSURLQueryItem {
            return NSURLQueryItem(name: "r", value: rawValue)
        }
    }

    public let email: String
    public let forceDefault: Bool
    public let defaultImage: DefaultImage
    public let rating: Rating

    private static let baseURL = NSURL(string: "https://secure.gravatar.com/avatar")!

    public init(
        emailAddress: String,
        defaultImage: DefaultImage = .MysteryMan,
        forceDefault: Bool = false,
        rating: Rating = .PG)
    {
        self.email = emailAddress
        self.defaultImage = defaultImage
        self.forceDefault = forceDefault
        self.rating = rating
    }

    public func URL(size size: CGFloat, scale: CGFloat = UIScreen.mainScreen().scale) -> NSURL {
        let URL = Gravatar.baseURL.URLByAppendingPathComponent(email.md5_hash)
        let components = NSURLComponents(URL: URL, resolvingAgainstBaseURL: false)!

        var queryItems = [defaultImage.queryItem, rating.queryItem]
        queryItems.append(NSURLQueryItem(name: "f", value: forceDefault ? "y" : "n"))
        queryItems.append(NSURLQueryItem(name: "s", value: String(format: "%.0f",size * scale)))

        components.queryItems = queryItems

        return components.URL!
    }
}
