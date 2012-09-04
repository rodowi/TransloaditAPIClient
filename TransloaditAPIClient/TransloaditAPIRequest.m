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
#import "AFJSONUtilities.h"
#import <CommonCrypto/CommonHMAC.h>

@interface TransloaditAPIRequest ()

@property (nonatomic, retain) NSMutableDictionary *params;

@end

@implementation TransloaditAPIRequest

@synthesize params;

@synthesize authKey;
@synthesize templateId;
@synthesize redirectUrl;
@synthesize notifyUrl;
@synthesize fields;

- (void)dealloc
{
    [params release];

    [authKey release];
    [templateId release];
    [redirectUrl release];
    [notifyUrl release];
    [fields release];

    [super dealloc];
}

#pragma mark - Init

- (id)init
{
    self = [super init];
    if (!self) 
        return nil;

    self.params = [[[NSMutableDictionary alloc] init] autorelease];

    return self;
}

- (void)setAuthKey:(NSString *)_authKey
{
    if ([authKey isEqualToString:_authKey])
        return;

    [authKey autorelease];
    authKey = [_authKey retain];

    NSMutableDictionary *auth = [NSMutableDictionary dictionaryWithObject:_authKey 
                                                                   forKey:@"key"];
    [params setObject:auth forKey:@"auth"];
}

- (void)setTemplateId:(NSString *)_templateId
{
    if ([templateId isEqualToString:_templateId])
        return;

    [templateId autorelease];
    templateId = [_templateId retain];

    [params setObject:_templateId forKey:@"template_id"];
}

- (void)setRedirectUrl:(NSString *)_redirectUrl
{
    if ([redirectUrl isEqualToString:_redirectUrl])
        return;

    [redirectUrl autorelease];
    redirectUrl = [_redirectUrl retain];

    [params setObject:_redirectUrl forKey:@"redirect_url"];
}

- (void)setNotifyUrl:(NSString *)_notifyUrl
{
    if ([notifyUrl isEqualToString:_notifyUrl])
        return;

    [notifyUrl autorelease];
    notifyUrl = [_notifyUrl retain];

    [params setObject:_notifyUrl forKey:@"notify_url"];
}

- (void)setFields:(NSDictionary *)_fields
{
    if (fields == _fields)
        return;

    [fields autorelease];
    fields = [_fields retain];
    
    [params setObject:_fields forKey:@"fields"];
}

#pragma mark - Helpers

- (BOOL)hasAuthorizationKey
{
    return [params valueForKeyPath:@"auth.key"] != nil;
}

#pragma mark - Encoding

- (NSDictionary *)encodedParamsAppendingSignatureUsingSecret:(NSString *)secret
{
    // A timestamp in the (near) future, 
    // after which the signature will no longer be accepted
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
    return [NSDictionary dictionaryWithObjectsAndKeys:
            paramsField, @"params", signatureField, @"signature", nil];
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
