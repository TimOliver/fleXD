//
//  FLEXViewControllerShortcuts.m
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

#import "FLEXViewControllerShortcuts.h"
#import "FLEXObjectExplorerFactory.h"
#import "FLEXRuntimeUtility.h"
#import "FLEXShortcut.h"
#import "FLEXAlert.h"

@interface FLEXViewControllerShortcuts ()
@end

@implementation FLEXViewControllerShortcuts

#pragma mark - Overrides

+ (instancetype)forObject:(UIViewController *)viewController {
    BOOL (^vcIsInuse)(UIViewController *) = ^BOOL(UIViewController *controller) {
        if (controller.viewIfLoaded.window) {
            return YES;
        }

        return controller.navigationController != nil;
    };

    return [self forObject:viewController additionalRows:@[
        [FLEXActionShortcut title:@"Push View Controller"
            subtitle:^NSString *(UIViewController *controller) {
                return vcIsInuse(controller) ? @"In use, cannot push" : nil;
            }
            selectionHandler:^void(UIViewController *host, UIViewController *controller) {
                if (!vcIsInuse(controller)) {
                    [host.navigationController pushViewController:controller animated:YES];
                } else {
                    [FLEXAlert
                        showAlert:@"Cannot Push View Controller"
                        message:@"This view controller's view is currently in use."
                        from:host
                    ];
                }
            }
            accessoryType:^UITableViewCellAccessoryType(UIViewController *controller) {
                if (!vcIsInuse(controller)) {
                    return UITableViewCellAccessoryDisclosureIndicator;
                } else {
                    return UITableViewCellAccessoryNone;
                }
            }
        ]
    ]];
}

@end
