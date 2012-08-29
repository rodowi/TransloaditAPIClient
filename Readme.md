# A Transloadit API Wrapper for iOS

This is a refactored version of the [Transloadit iPhone
SDK](https://github.com/transloadit/iphone-sdk) powered by
AFNetworking and blocks.

## Getting started

To work with the API you will need a [transloadit](http://transloadit.com/) account, as well
as a [template id](http://transloadit.com/docs/templates).

In order to use the SDK in your own app, simply add
TransloaditAPIClient.[h|m] into your XCode project.

TransloaditAPIClient depends on
[AFNetworking](https://github.com/AFNetworking/AFNetworking/)

## A gentle introduction to the TransloaditAPIClient

**Initializing**

```objective-c
[[TransloaditAPIClient sharedClient] authenticateWithKey:@"<AUTH-KEY>" andSecret:@"<AUTH-SECRET>"];
[[TransloaditAPIClient sharedClient] setTemplateId:@"<TEMPLATE-ID>"];
```

**Uploading a picture selected from the UIImagePickerController**

```objective-c
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
  [[TransloaditAPIClient sharedClient] uploadFileFromPicker:info];
}
```

**Uploading progress**

```objective-c
[[TransloaditAPIClient sharedClient] setUploadProgressBlock:^(NSInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
  NSLog(@"Sent %lld of %lld bytes", totalBytesWritten, totalBytesExpectedToWrite);
  if (totalBytesWritten == totalBytesExpectedToWrite)
    NSLog(@"We are done uploading!");
}];
```

**Handling success and failure**

```objective-c
[[TransloaditAPIClient sharedClient] setCompletionBlockWithSuccess:^(NSDictionary *JSON) {
  NSLog(@"Transloadit's response: \n%@", [JSON description]);
} failure:^(NSError *error) {
  NSLog(@"Awww snap! Failed with error '%@'", [error localizedDescription]);
}];
```

## Authors

1. Rod Wilhelmy from CitiVox: [@rod_wilhelmy](http://twitter.com/rod_wilhelmy),
[wilhelmbot](https://github.com/wilhelmbot)
2. Felix Geisendörfer from Transloadit

## License

(The MIT License)

Copyright (c) 2012 CitiVox, Inc.  
Copyright (c) 2010-2012 Felix Geisendörfer (felix.geisendoerfer@transloadit.com)  

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the 'Software'), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
