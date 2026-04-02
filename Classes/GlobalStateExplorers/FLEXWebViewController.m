//
//  FLEXWebViewController.m
//
//  Copyright (c) Flipboard (2014-2016); FLEX Team (2020-2026).
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without modification,
//  are permitted provided that the following conditions are met:
//
//  * Redistributions of source code must retain the above copyright notice, this
//    list of conditions and the following disclaimer.
//
//  * Redistributions in binary form must reproduce the above copyright notice, this
//    list of conditions and the following disclaimer in the documentation and/or
//    other materials provided with the distribution.
//
//  * Neither the name of Flipboard nor the names of its
//    contributors may be used to endorse or promote products derived from
//    this software without specific prior written permission.
//
//  * You must NOT include this project in an application to be submitted
//    to the App Store™, as this project uses too many private APIs.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
//  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
//  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
//  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
//  ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import "FLEXWebViewController.h"
#import "FLEXUtility.h"
#import <WebKit/WebKit.h>

@interface FLEXWebViewController () <WKNavigationDelegate>

@property (nonatomic) WKWebView *webView;
@property (nonatomic) NSString *originalText;

@end

@implementation FLEXWebViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        WKWebViewConfiguration *configuration = [WKWebViewConfiguration new];

        configuration.dataDetectorTypes = WKDataDetectorTypeLink;

        self.webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:configuration];
        self.webView.navigationDelegate = self;
    }
    return self;
}

- (id)initWithText:(NSString *)text {
    self = [self initWithNibName:nil bundle:nil];
    if (self) {
        self.originalText = text;

        NSString * const html = @"<head><style>:root{ color-scheme: light dark; }</style>"
            "<meta name='viewport' content='initial-scale=1.0'></head><body><pre>%@</pre></body>";

        // Loading message for when input text takes a long time to escape
        NSString *loadingMessage = [NSString stringWithFormat:html, @"Loading..."];
        [self.webView loadHTMLString:loadingMessage baseURL:nil];

        // Escape HTML on a background thread
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSString *escapedText = [FLEXUtility stringByEscapingHTMLEntitiesInString:text];
            NSString *htmlString = [NSString stringWithFormat:html, escapedText];

            // Update webview on the main thread
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.webView loadHTMLString:htmlString baseURL:nil];
            });
        });
    }

    return self;
}

- (id)initWithURL:(NSURL *)url {
    self = [self initWithNibName:nil bundle:nil];
    if (self) {
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        [self.webView loadRequest:request];
    }

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.view addSubview:self.webView];
    self.webView.frame = self.view.bounds;
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    if (self.originalText.length > 0) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
            initWithTitle:@"Copy" style:UIBarButtonItemStylePlain target:self action:@selector(copyButtonTapped:)
        ];
    }
}

- (void)copyButtonTapped:(id)sender {
    [UIPasteboard.generalPasteboard setString:self.originalText];
}


#pragma mark - WKWebView Delegate

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction
                                                     decisionHandler:(void (^)(WKNavigationActionPolicy))handler {
    WKNavigationActionPolicy policy = WKNavigationActionPolicyCancel;
    if (navigationAction.navigationType == WKNavigationTypeOther) {
        // Allow the initial load
        policy = WKNavigationActionPolicyAllow;
    } else {
        // For clicked links, push another web view controller onto the navigation stack
        // so that hitting the back button works as expected.
        // Don't allow the current web view to handle the navigation.
        NSURLRequest *request = navigationAction.request;
        FLEXWebViewController *webVC = [[[self class] alloc] initWithURL:request.URL];
        webVC.title = request.URL.absoluteString;
        [self.navigationController pushViewController:webVC animated:YES];
    }

    handler(policy);
}


#pragma mark - Class Helpers

+ (BOOL)supportsPathExtension:(NSString *)extension {
    BOOL supported = NO;
    NSSet<NSString *> *supportedExtensions = [self webViewSupportedPathExtensions];
    if ([supportedExtensions containsObject:extension.lowercaseString]) {
        supported = YES;
    }
    return supported;
}

+ (NSSet<NSString *> *)webViewSupportedPathExtensions {
    static NSSet<NSString *> *pathExtensions = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // Note that this is not exhaustive, but all these extensions should work well in the web view.
        // See https://developer.apple.com/library/archive/documentation/AppleApplications/Reference/SafariWebContent/CreatingContentforSafarioniPhone/CreatingContentforSafarioniPhone.html#//apple_ref/doc/uid/TP40006482-SW7
        pathExtensions = [NSSet<NSString *> setWithArray:@[
            @"jpg", @"jpeg", @"png", @"gif", @"pdf", @"svg", @"tiff", @"3gp", @"3gpp", @"3g2",
            @"3gp2", @"aiff", @"aif", @"aifc", @"cdda", @"amr", @"mp3", @"swa", @"mp4", @"mpeg",
            @"mpg", @"mp3", @"wav", @"bwf", @"m4a", @"m4b", @"m4p", @"mov", @"qt", @"mqv", @"m4v"
        ]];

    });

    return pathExtensions;
}

@end
