//
//  TransloaditAPIRequest.h
//
//  Created by Rodolfo Wilhelmy on 8/16/12.
//  Copyright (c) 2012 CitiVox. All rights reserved.
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

#import "AFHTTPRequestOperation.h"

// TODO: handle public API requests

@interface TransloaditAPIRequest : NSObject

@property (nonatomic, retain) NSString *authKey;
@property (nonatomic, retain) NSString *templateId;
@property (nonatomic, retain) NSString *redirectUrl;
@property (nonatomic, retain) NSString *notifyUrl;
@property (nonatomic, retain) NSDictionary *fields;

/**
 * @name Look for authorization key
 * A private API call must contain auth.key
 *
 * @see https://transloadit.com/docs/api-basics
 */
- (BOOL)hasAuthorizationKey;

/**
 * @name Encoding parameters for Transloadit requests
 * Two parameters must be passed on each request:
 * 1. params: a JSON representation of the request parameters using simple URL encoding.
 * 2. signature: a HMAC hex signature of JSON-encoded params using the API secret as SHA1 key.
 * 
 * @param secret: Your API auth secret generated for your account.
 * @see https://transloadit.com/docs/authentication
 * @see https://transloadit.com/accounts/credentials
 */
- (NSDictionary *)encodedParamsAppendingSignatureUsingSecret:(NSString *)secret;

@end
