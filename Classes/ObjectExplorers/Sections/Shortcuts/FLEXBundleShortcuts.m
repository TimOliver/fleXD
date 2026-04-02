//
//  FLEXBundleShortcuts.m
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

#import "FLEXBundleShortcuts.h"
#import "FLEXShortcut.h"
#import "FLEXAlert.h"
#import "FLEXMacros.h"
#import "FLEXRuntimeExporter.h"
#import "FLEXTableListViewController.h"
#import "FLEXFileBrowserController.h"

#pragma mark -
@implementation FLEXBundleShortcuts
#pragma mark Overrides

+ (instancetype)forObject:(NSBundle *)bundle { weakify(self)
    return [self forObject:bundle additionalRows:@[
        [FLEXActionShortcut
            title:@"Browse Bundle Directory" subtitle:nil
            viewer:^UIViewController *(NSBundle *bundle) {
                return [FLEXFileBrowserController path:bundle.bundlePath];
            }
            accessoryType:^UITableViewCellAccessoryType(NSBundle *bundle) {
                return UITableViewCellAccessoryDisclosureIndicator;
            }
        ],
        [FLEXActionShortcut title:@"Browse Bundle as Database…" subtitle:nil
            selectionHandler:^(UIViewController *host, NSBundle *bundle) { strongify(self)
                [self promptToExportBundleAsDatabase:bundle host:host];
            }
            accessoryType:^UITableViewCellAccessoryType(NSBundle *bundle) {
                return UITableViewCellAccessoryDisclosureIndicator;
            }
        ],
    ]];
}

+ (void)promptToExportBundleAsDatabase:(NSBundle *)bundle host:(UIViewController *)host {
    [FLEXAlert makeAlert:^(FLEXAlert *make) {
        make.title(@"Save As…").message(
            @"The database be saved in the Library folder. "
            "Depending on the number of classes, it may take "
            "10 minutes or more to finish exporting. 20,000 "
            "classes takes about 7 minutes."
        );
        make.configuredTextField(^(UITextField *field) {
            field.placeholder = @"FLEXRuntimeExport.objc.db";
            field.text = [NSString stringWithFormat:
                @"%@.objc.db", bundle.executablePath.lastPathComponent
            ];
        });
        make.button(@"Start").handler(^(NSArray<NSString *> *strings) {
            [self browseBundleAsDatabase:bundle host:host name:strings[0]];
        });
        make.button(@"Cancel").cancelStyle();
    } showFrom:host];
}

+ (void)browseBundleAsDatabase:(NSBundle *)bundle host:(UIViewController *)host name:(NSString *)name {
    NSParameterAssert(name.length);

    UIAlertController *progress = [FLEXAlert makeAlert:^(FLEXAlert *make) {
        make.title(@"Generating Database");
        // Some iOS version glitch out of there is
        // no initial message and you add one later
        make.message(@"…");
    }];

    [host presentViewController:progress animated:YES completion:^{
        // Generate path to store db
        NSString *path = [NSSearchPathForDirectoriesInDomains(
            NSLibraryDirectory, NSUserDomainMask, YES
        )[0] stringByAppendingPathComponent:name];

        progress.message = [path stringByAppendingString:@"\n\nCreating database…"];

        // Generate db and show progress
        [FLEXRuntimeExporter createRuntimeDatabaseAtPath:path
            forImages:@[bundle.executablePath]
            progressHandler:^(NSString *status) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    progress.message = [progress.message
                        stringByAppendingFormat:@"\n%@", status
                    ];
                    [progress.view setNeedsLayout];
                    [progress.view layoutIfNeeded];
                });
            } completion:^(NSString *error) {
                // Display error if any
                if (error) {
                    progress.title = @"Error";
                    progress.message = error;
                    [progress addAction:[UIAlertAction
                        actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]
                    ];
                }
                // Browse database
                else {
                    [progress dismissViewControllerAnimated:YES completion:nil];
                    [host.navigationController pushViewController:[
                        [FLEXTableListViewController alloc] initWithPath:path
                    ] animated:YES];
                }
            }
        ];
    }];
}

@end
