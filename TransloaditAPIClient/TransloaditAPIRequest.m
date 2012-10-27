/*
 Copyright (C) 2010 Felix Geisendörfer. All rights reserved.
 Copyright (C) 2012 CitiVox.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 * Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.
 
 * Neither the name of the author nor the names of its contributors may be used
 to endorse or promote products derived from this software without specific
 prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "TransloaditAPIRequest.h"
#import <CommonCrypto/CommonHMAC.h>

@implementation TransloaditAPIRequest

+ (NSDictionary *)encodeParameters:(NSDictionary *)params appendingSignatureUsingSecret:(NSString *)secret
{
    // A timestamp in the (near) future, after which the signature will no longer be accepted
    addExpirationParameterToDictionary([params objectForKey:@"auth"]);

    // Parameters should be JSON encoded
    NSError *JSONEncodingError = nil;
    NSData *JSONData = [NSJSONSerialization dataWithJSONObject:params options:NSJSONWritingPrettyPrinted error:&JSONEncodingError];
    if (JSONEncodingError) {
        NSLog(@"Awww snap! JSON encoding error");
        // TODO: pass a well crafted NSError
    }

    // Stringify JSON parameters
    NSString *paramsField = [[[NSString alloc] initWithData:JSONData encoding:NSUTF8StringEncoding] autorelease];

    // Calculate signature for the request
    NSString *signatureField = stringWithHexBytes(hmacSha1withKey(secret, paramsField));

    // Extra wrapper to join both JSON encoded parameters and the signature
    return [NSDictionary dictionaryWithObjectsAndKeys:paramsField, @"params", signatureField, @"signature", nil];
}

void addExpirationParameterToDictionary(NSMutableDictionary *dictionary)
{
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"yyyy-MM-dd HH:mm-ss 'GMT'"];
    
    NSDate *localExpires = [[NSDate alloc] initWithTimeIntervalSinceNow:60*60];
    NSTimeInterval timeZoneOffset = [[NSTimeZone defaultTimeZone] secondsFromGMT];
    NSTimeInterval gmtTimeInterval = [localExpires timeIntervalSinceReferenceDate] - timeZoneOffset;
    NSDate *gmtExpires = [NSDate dateWithTimeIntervalSinceReferenceDate:gmtTimeInterval];
    
    [dictionary setObject:[format stringFromDate:gmtExpires] forKey:@"expires"];
    
    [localExpires release];
    [format release];
}

NSString * stringWithHexBytes(NSData *data)
{
    static const char hexdigits[] = "0123456789abcdef";
    const size_t numBytes = [data length];
    const unsigned char* bytes = [data bytes];
    char *strbuf = (char *)malloc(numBytes * 2 + 1);
    char *hex = strbuf;
    NSString *hexBytes = nil;

    for (int i = 0; i<numBytes; ++i) {
        const unsigned char c = *bytes++;
        *hex++ = hexdigits[(c >> 4) & 0xF];
        *hex++ = hexdigits[(c ) & 0xF];
    }

    *hex = 0;
    hexBytes = [NSString stringWithUTF8String:strbuf];
    free(strbuf);

    return hexBytes;
}

NSData * hmacSha1withKey(NSString *key, NSString *string)
{
    NSData *clearTextData = [string dataUsingEncoding:NSUTF8StringEncoding];
    NSData *keyData = [key dataUsingEncoding:NSUTF8StringEncoding];

    uint8_t digest[CC_SHA1_DIGEST_LENGTH] = {0};

    CCHmacContext hmacContext;
    CCHmacInit(&hmacContext, kCCHmacAlgSHA1, keyData.bytes, keyData.length);
    CCHmacUpdate(&hmacContext, clearTextData.bytes, clearTextData.length);
    CCHmacFinal(&hmacContext, digest);

    return [NSData dataWithBytes:digest length:CC_SHA1_DIGEST_LENGTH];
}


@end
