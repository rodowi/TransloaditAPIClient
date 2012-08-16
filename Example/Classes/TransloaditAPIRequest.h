//
//  TransloaditAPIRequest.h
//  TransloaditIphoneSdk
//
//  Created by Rodolfo Wilhelmy on 8/16/12.
//  Copyright (c) 2012 CitiVox. All rights reserved.
//

#import "AFHTTPRequestOperation.h"

@interface TransloaditAPIRequest : AFHTTPRequestOperation

/**
 * @name Encoding parameters for Transloadit requests
 *
 * Two parameters must be passed on each request
 * 1. params: a JSON representation of the request parameters using simple URL encoding
 * 2. signature: a HMAC hex signature of JSON-encoded params using your API secret as the SHA1 key
 * @see https://transloadit.com/docs/authentication
 */
+ (NSDictionary *)encodeParameters:(NSDictionary *)params appendingSignatureUsingSecret:(NSString *)secret;

@end
