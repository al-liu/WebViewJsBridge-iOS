//
//  DemoViewController.m
//  iOS Example
//
//  Created by 刘海川 on 2019/9/27.
//  Copyright © 2019 lhc. All rights reserved.
//

#import "DemoViewController.h"
#import "HCWebViewJsBridge.h"
#import "DemoJsApi.h"
#import "TestJsApi.h"

@interface DemoViewController () <TestJsApiDelegate>{
    HCWebViewJsBridge *_bridge;
}
@property (weak, nonatomic) IBOutlet UIWebView *webView;

@end

@implementation DemoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSString* htmlPath = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"html"];
    NSString* appHtml = [NSString stringWithContentsOfFile:htmlPath encoding:NSUTF8StringEncoding error:nil];
    NSURL *baseURL = [NSURL fileURLWithPath:htmlPath];
    [self.webView loadHTMLString:appHtml baseURL:baseURL];
    
    _bridge = [HCWebViewJsBridge bridgeWithWebView:self.webView];
    [_bridge enableDebugLogging:YES];
    DemoJsApi *defaultApi = [DemoJsApi new];
    [_bridge addJsBridgeApiObject:defaultApi namespace:@"ui"];
    TestJsApi *testApi = [TestJsApi new];
    testApi.context = self;
    [_bridge addJsBridgeApiObject:testApi namespace:@"test"];
    
    [_bridge callHandler:@"test1" data:@"test1 data" responseCallback:^(id  _Nonnull responseData) {
        NSLog(@"test1 callback data is:%@", responseData);
    }];
    // Do any additional setup after loading the view.
}
- (IBAction)test1:(id)sender {
    [_bridge callHandler:@"test1" data:@"test1 data" responseCallback:^(id  _Nonnull responseData) {
        NSLog(@"test1 callback data is:%@", responseData);
    }];
}
- (IBAction)test2:(id)sender {
    [_bridge callHandler:@"test2" data:@{@"hello":@"world"}];
}
- (IBAction)test3:(id)sender {
    [_bridge callHandler:@"test3"];
}
- (IBAction)test4:(id)sender {
    [_bridge callHandler:@"test1" responseCallback:^(id  _Nullable responseData) {
        NSLog(@"test1 callback data is:%@", responseData);
    }];
}
- (IBAction)backToWKWebView:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
