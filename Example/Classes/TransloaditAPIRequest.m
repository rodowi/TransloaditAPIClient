//
//  TransloaditAPIRequest.m
//  TransloaditIphoneSdk
//
//  Created by Rodolfo Wilhelmy on 8/16/12.
//  Copyright (c) 2012 CitiVox. All rights reserved.
//

#import "TransloaditAPIRequest.h"
#import "AFJSONUtilities.h"
#import <CommonCrypto/CommonHMAC.h>

@implementation TransloaditAPIRequest

+ (NSDictionary *)encodeParameters:(NSDictionary *)params appendingSignatureUsingSecret:(NSString *)secret
{
    // A timestamp in the (near) future, after which the signature will no longer be accepted
    addExpirationParameterToDictionary([params objectForKey:@"auth"]);

    // Parameters should be JSON encoded
    NSError *JSONEncodingError = nil;
    NSData *JSONData = AFJSONEncode(params, &JSONEncodingError);
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
