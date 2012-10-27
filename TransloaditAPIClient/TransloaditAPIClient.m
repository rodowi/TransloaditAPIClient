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
#import "TransloaditAPIRequest.h"

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

- (void)setRedirectUrl:(NSString *)redirectUrl
{
    [params setObject:redirectUrl forKey:@"redirect_url"];
}

- (void)setFields:(NSDictionary *)fields
{
    [params setObject:fields forKey:@"fields"];
}

- (void)setNotifyUrl:(NSString *)notifyUrl
{
    [params setObject:notifyUrl forKey:@"notify_url"];
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

- (void)uploadImage:(UIImage *)image
{
    NSData *data = UIImageJPEGRepresentation(image, 0.9f);
    [self uploadData:data namedAs:@"iphone_image.jpg" ofContentType:@"image/jpeg"];
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

- (void)uploadData:(NSData *)data namedAs:(NSString *)name ofContentType:(NSString *)type
{
    if ([self allKeysAreSet] == NO) {
        NSLog(@"Awww snap! Some API keys are missing");
        // TODO: call failure block passing a crafted NSError
    }

    NSDictionary *parameters = [TransloaditAPIRequest encodeParameters:params appendingSignatureUsingSecret:_secret];

    // Setup multipart form request
    NSMutableURLRequest *request = [self multipartFormRequestWithMethod:@"POST" path:@"/assemblies?pretty=true" parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        [formData appendPartWithFileData:data name:@"upload_1" fileName:name mimeType:type];
    }];

    // Fire!
    AFHTTPRequestOperation *operation = [[[AFHTTPRequestOperation alloc] initWithRequest:request] autorelease];
    [operation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
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
        NSDictionary *JSON = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableLeaves error:&decodingError];
        if (decodingError)
            NSLog(@"Awww snap! JSON decoding error");

        if (_successBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                _successBlock(JSON);
            });
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        // Parse server response to find a better error description
        NSError *decodingError = nil;
        NSDictionary *errorJSON = [NSJSONSerialization JSONObjectWithData:[operation.responseString dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableLeaves error:&decodingError];
        if (!decodingError) {
            NSDictionary *detail = @{ NSLocalizedDescriptionKey: errorJSON[@"message"] };
            error = [NSError errorWithDomain:errorJSON[@"error"] code:100 userInfo:detail];
        }
        if (_failureBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                _failureBlock(error);
            });
        }
    }];
    // Support background networking
    [operation setShouldExecuteAsBackgroundTaskWithExpirationHandler:^{
        NSLog(@"Awww snap! Couldn't upload on time. Apple's background timeout expired.");
        // TODO: should notify the user, perhaps a UIAlertView
    }];

    [operation start];
}

@end
