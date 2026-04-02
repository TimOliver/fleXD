//
//  FLEXUIAppShortcuts.m
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

#import "FLEXUIAppShortcuts.h"
#import "FLEXRuntimeUtility.h"
#import "FLEXShortcut.h"
#import "FLEXAlert.h"

@implementation FLEXUIAppShortcuts

#pragma mark - Overrides

+ (instancetype)forObject:(UIApplication *)application {
    return [self forObject:application additionalRows:@[
        [FLEXActionShortcut title:@"Open URL…"
            subtitle:^NSString *(UIViewController *controller) {
                return nil;
            }
            selectionHandler:^void(UIViewController *host, UIApplication *app) {
                [FLEXAlert makeAlert:^(FLEXAlert *make) {
                    make.title(@"Open URL");
                    make.message(
                        @"This will call openURL: or openURL:options:completion: "
                         "with the string below. 'Open if Universal' will only open "
                         "the URL if it is a registered Universal Link."
                    );

                    make.textField(@"twitter://user?id=12345");
                    make.button(@"Open").handler(^(NSArray<NSString *> *strings) {
                        [self openURL:strings[0] inApp:app onlyIfUniveral:NO host:host];
                    });
                    make.button(@"Open if Universal").handler(^(NSArray<NSString *> *strings) {
                        [self openURL:strings[0] inApp:app onlyIfUniveral:YES host:host];
                    });
                    make.button(@"Cancel").cancelStyle();
                } showFrom:host];
            }
            accessoryType:^UITableViewCellAccessoryType(UIViewController *controller) {
                return UITableViewCellAccessoryDisclosureIndicator;
            }
        ]
    ]];
}

+ (void)openURL:(NSString *)urlString
          inApp:(UIApplication *)app
 onlyIfUniveral:(BOOL)universalOnly
           host:(UIViewController *)host {
    NSURL *url = [NSURL URLWithString:urlString];

    if (url) {
        [app openURL:url options:@{
            UIApplicationOpenURLOptionUniversalLinksOnly: @(universalOnly)
        } completionHandler:^(BOOL success) {
            if (!success) {
                [FLEXAlert showAlert:@"No Universal Link Handler"
                    message:@"No installed application is registered to handle this link."
                    from:host
                ];
            }
        }];
    } else {
        [FLEXAlert showAlert:@"Error" message:@"Invalid URL" from:host];
    }
}

@end

