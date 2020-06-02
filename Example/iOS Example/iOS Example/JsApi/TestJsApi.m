//
//  TestJsApi.m
//  Demo
//
//  Created by 刘海川 on 2019/9/29.
//  Copyright © 2019 刘海川. All rights reserved.
//

#import "TestJsApi.h"
#import "HCWKWebViewJsBridge.h"

@interface TestJsApi () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic, copy) HCJBResponseCallback selectPhotoCB;

@end

@implementation TestJsApi

- (void)alert:(NSDictionary *)data callback:(HCJBResponseCallback)callback {
    NSString *title = data[@"title"];
    NSString *description = data[@"desc"];
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                             message:description
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * _Nonnull action) {
                                                             if (self.context && [self.context respondsToSelector:@selector(alertCancelResponseData)]) {
                                                                 callback([self.context alertCancelResponseData]);
                                                             } else {
                                                                 callback(@"cancel action finished.");
                                                             }
    }];
    [alertController addAction:cancelAction];
    [self.context presentViewController:alertController animated:YES completion:nil];
}

- (void)selectPhoto:(HCJBResponseCallback)callback {
    UIImagePickerController * imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.editing = YES;
    imagePicker.delegate = self;
    imagePicker.allowsEditing = YES;
    
    UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Select Image" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction * camera = [UIAlertAction actionWithTitle:@"Camera" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        imagePicker.sourceType =  UIImagePickerControllerSourceTypeCamera;
        imagePicker.modalPresentationStyle = UIModalPresentationFullScreen;
        imagePicker.cameraCaptureMode = UIImagePickerControllerCameraCaptureModePhoto;
        [self.context presentViewController:imagePicker animated:YES completion:nil];
    }];
    
    UIAlertAction * photo = [UIAlertAction actionWithTitle:@"Album" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        [self.context presentViewController:imagePicker animated:YES completion:nil];
    }];
    
    UIAlertAction * cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    }];
    
    [alert addAction:camera];
    [alert addAction:photo];
    [alert addAction:cancel];
    
    [self.context presentViewController:alert animated:YES completion:nil];
    self.selectPhotoCB = callback;
}

- (void)getRequest:(NSDictionary *)data callback:(HCJBResponseCallback)callback {
    NSString *url = data[@"url"];
    NSDictionary *params = data[@"params"];
    NSMutableString *parameterString = [[NSMutableString alloc] initWithString:url];
    if (params && params.allKeys.count > 0) {
        [parameterString appendString:@"?"];
        int pos =0;
        for (NSString *key in params.allKeys) {
            [parameterString appendFormat:@"%@=%@", key, params[key]];
            if(pos  < params.allKeys.count - 1){
                [parameterString appendString:@"&"];
            }
            pos++;
        }
    }
    NSString * encodingString = [[parameterString copy] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSURL *_url = [NSURL URLWithString:encodingString];
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:_url];
    [urlRequest setTimeoutInterval:15.0];
    [urlRequest setHTTPMethod:@"GET"];
    
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *urlSession = [NSURLSession sessionWithConfiguration:sessionConfiguration];
    NSURLSessionDataTask *task = [urlSession dataTaskWithRequest:urlRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            NSLog(@"error description: %@", [error description]);
            callback([error description]);
        } else {
            NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            callback(responseString);
        }
    }];
    [task resume];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    
    [picker dismissViewControllerAnimated:YES completion:nil];
    UIImage * image = [info valueForKey:UIImagePickerControllerEditedImage];
    NSData *imageData = UIImagePNGRepresentation(image);
    NSString *imageBase64 = [imageData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
    NSDictionary *dict = @{@"image": imageBase64};
    self.selectPhotoCB(dict);
}



@end
