//
//  TransloaditAPIClient.h
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

#import "AFHTTPClient.h"
#import "AFJSONRequestOperation.h"

// Mimicking AFURLConnectionOperationProgressBlock @ AFURLConnectionOperation.m (not exposed)
typedef void (^TransloaditAPIClientProgressBlock)(NSInteger, long long, long long);
typedef void (^TransloaditAPIClientSuccessBlock)(NSDictionary *);
typedef void (^TransloaditAPIClientFailureBlock)(NSError *);

@interface TransloaditAPIClient : AFHTTPClient

@property (nonatomic, retain) NSMutableDictionary *params;

+ (TransloaditAPIClient *)sharedClient;

- (void)authenticateWithKey:(NSString *)key andSecret:(NSString *)secret;
- (void)setTemplateId:(NSString *)identifier;
- (void)setRedirectUrl:(NSString *)redirectUrl;
- (void)setNotifyUrl:(NSString *)notifyUrl;
- (void)setFields:(NSDictionary *)fields;
- (BOOL)allKeysAreSet;
- (void)uploadFileAt:(NSString *)path namedAs:(NSString *)name ofContentType:(NSString *)type;
- (void)uploadFileFromPicker:(NSDictionary *)info;
- (void)uploadImage:(UIImage *)image;

// AFHTTPRequestOperation wrappers
- (void)setUploadProgressBlock:(void (^)(NSInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite))block;
- (void)setCompletionBlockWithSuccess:(void (^)(NSDictionary *JSON))success failure:(void (^)(NSError *error))failure;

@end
