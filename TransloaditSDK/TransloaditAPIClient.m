//
//  TransloaditAPIClient.m
//
//  Created by Rodolfo Wilhelmy on 8/14/12.
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

#import "TransloaditAPIClient.h"
#import "AFJSONUtilities.h"
#import <CommonCrypto/CommonHMAC.h>

static NSString * const kTransloaditAPIBaseURLString = @"http://api2.transloadit.com";

@implementation TransloaditAPIClient
{
    NSString *_secret;
    TransloaditAPIClientProgressBlock _uploadProgressBlock;
    TransloaditAPIClientFailureBlock _failureBlock;
    TransloaditAPIClientSuccessBlock _successBlock;
}

@synthesize params;

- (void)dealloc
{
    [_secret release];
    [_uploadProgressBlock release];
    [_failureBlock release];
    [_successBlock release];
    
    [params release];
    
    [super dealloc];
}

#pragma mark - Initialization

+ (TransloaditAPIClient *)sharedClient {
    static TransloaditAPIClient *_sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedClient = [[TransloaditAPIClient alloc] initWithBaseURL:[NSURL URLWithString:kTransloaditAPIBaseURLString]];
    });

    return _sharedClient;
}

- (id)initWithBaseURL:(NSURL *)url {
    self = [super initWithBaseURL:url];
    if (!self) {
        return nil;
    }

    [self registerHTTPOperationClass:[AFJSONRequestOperation class]];

    // Accept HTTP Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.1
	[self setDefaultHeader:@"Accept" value:@"application/json"];

    // Body parameters should be url encoded; see https://transloadit.com/docs/authentication
    [self setParameterEncoding:AFFormURLParameterEncoding];

    params = [[NSMutableDictionary alloc] init];
    
    return self;
}

#pragma mark - API

- (void)authenticateWithKey:(NSString *)key andSecret:(NSString *)secret
{
    NSMutableDictionary *auth = [[[NSMutableDictionary alloc] init] autorelease];
    [auth setObject:key forKey:@"key"];
    [params setObject:auth forKey:@"auth"];
    _secret = [secret retain];
}

- (void)setTemplateId:(NSString *)identifier
{
    [params setObject:identifier forKey:@"template_id"];
}

- (BOOL)allKeysAreSet
{
    NSMutableDictionary *auth = [params objectForKey:@"auth"];
    return auth && [auth objectForKey:@"key"] && _secret;
}

- (void)uploadFileAt:(NSString *)path namedAs:(NSString *)name ofContentType:(NSString *)type
{
    NSData *data = [[NSFileManager defaultManager] contentsAtPath:[NSString stringWithFormat:@"%@%@", path, name]];
    [self uploadData:data namedAs:name ofContentType:type];
}

- (void)uploadFileFromPicker:(NSDictionary *)info
{
    NSString *field = @"upload_1";
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    
	if ([mediaType isEqualToString:@"public.image"]) {
		NSMutableDictionary *file = [[NSMutableDictionary alloc] init];
		[file setObject:info forKey:@"info"];
		[file setObject:field forKey:@"field"];        
        UIImage *image = [[file objectForKey:@"info"] objectForKey:@"UIImagePickerControllerOriginalImage"];
        NSData *imageData = UIImageJPEGRepresentation(image, 0.9f);
        [self uploadData:imageData namedAs:@"iphone_image.jpg" ofContentType:@"image/jpeg"];
        [file release];
	} else if ([mediaType isEqualToString:@"public.movie"]) {
		NSURL *fileUrl = [info valueForKey:UIImagePickerControllerMediaURL];
		NSString *filePath = [fileUrl path];
        [self uploadFileAt:filePath namedAs:@"iphone_video.mov" ofContentType:@"video/quicktime"];
	}
}

#pragma mark AFHTTPRequestOperation wrappers

- (void)setUploadProgressBlock:(TransloaditAPIClientProgressBlock)block 
{
    _uploadProgressBlock = [block copy];
}

- (void)setCompletionBlockWithSuccess:(TransloaditAPIClientSuccessBlock)success failure:(TransloaditAPIClientFailureBlock)failure
{
    _successBlock = [success copy];
    _failureBlock = [failure copy];
}

#pragma mark - Network requests

- (void)addExpirationParameterToDictionary:(NSMutableDictionary *)dictionary
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

- (void)uploadData:(NSData *)data namedAs:(NSString *)name ofContentType:(NSString *)type
{
    if ([self allKeysAreSet] == NO) {
        NSLog(@"Awww snap! Some API keys are missing");
    }
    
    // A timestamp in the (near) future, after which the signature will no longer be accepted
    [self addExpirationParameterToDictionary:[params objectForKey:@"auth"]];
    
    // Authentication parameters should be JSON encoded
    NSError *JSONEncodingError = nil;
    NSData *JSONData = AFJSONEncode(params, &JSONEncodingError);
    if (JSONEncodingError)
        NSLog(@"Awww snap! JSON encoding error");
    NSString *paramsField = [[[NSString alloc] initWithData:JSONData encoding:NSUTF8StringEncoding] autorelease];
    
    // Signature of the request
    NSString *signatureField = [self stringWithHexBytes:[self hmacSha1withKey:_secret forString:paramsField]];
        
    // Extra wrapper to join both JSON encoded parameters and the signature
    NSDictionary *postParameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                    paramsField, @"params", 
                                    signatureField, @"signature",
                                    nil];

    // Setup POST request
    NSMutableURLRequest *request = [self multipartFormRequestWithMethod:@"POST" path:@"/assemblies?pretty=true" parameters:postParameters constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        [formData appendPartWithFileData:data name:@"upload_1" fileName:name mimeType:type];
    }];
    
    // Fire & notify listener
    AFHTTPRequestOperation *operation = [[[AFHTTPRequestOperation alloc] initWithRequest:request] autorelease];
    [operation setUploadProgressBlock:^(NSInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) { 
        if (_uploadProgressBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                _uploadProgressBlock(bytesWritten, totalBytesWritten, totalBytesExpectedToWrite);
            });
        }
    }];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) { 
        // We need to decode the response string since responseObject arrives as NSData
        // This happens apparently because we did not invoke AFJSONRequestOperation but AFHTTPRequestOperation 
        NSError *decodingError = nil;
        NSDictionary *JSON = AFJSONDecode(responseObject, &decodingError);
        if (decodingError)
            NSLog(@"Awww snap! JSON decoding error");

        if (_successBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                _successBlock(JSON);
            });
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) { 
        if (_failureBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                _failureBlock(error);
            });
        }
    }];
    [operation start];
}

#pragma mark - Utilities

- (NSString *)stringWithHexBytes:(NSData *)data
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

- (NSData *)hmacSha1withKey:(NSString *)key forString:(NSString *)string
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
