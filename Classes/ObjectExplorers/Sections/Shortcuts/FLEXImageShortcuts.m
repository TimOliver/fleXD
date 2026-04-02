//
//  FLEXImageShortcuts.m
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

#import "FLEXImageShortcuts.h"
#import "FLEXImagePreviewViewController.h"
#import "FLEXShortcut.h"
#import "FLEXAlert.h"
#import "FLEXMacros.h"

@interface UIAlertController (FLEXImageShortcuts)
- (void)flex_image:(UIImage *)image disSaveWithError:(NSError *)error :(void *)context;
@end

@implementation FLEXImageShortcuts

#pragma mark - Overrides

+ (instancetype)forObject:(UIImage *)image {
    // These additional rows will appear at the beginning of the shortcuts section.
    // The methods below are written in such a way that they will not interfere
    // with properties/etc being registered alongside these
    return [self forObject:image additionalRows:@[
        [FLEXActionShortcut title:@"View Image" subtitle:nil
            viewer:^UIViewController *(id image) {
                return [FLEXImagePreviewViewController forImage:image];
            }
            accessoryType:^UITableViewCellAccessoryType(id image) {
                return UITableViewCellAccessoryDisclosureIndicator;
            }
        ],
        [FLEXActionShortcut title:@"Save Image" subtitle:nil
            selectionHandler:^(UIViewController *host, id image) {
                // Present modal alerting user about saving
                UIAlertController *alert = [FLEXAlert makeAlert:^(FLEXAlert *make) {
                    make.title(@"Saving Image…");
                }];
                [host presentViewController:alert animated:YES completion:nil];

                // Save the image
                UIImageWriteToSavedPhotosAlbum(
                    image, alert, @selector(flex_image:disSaveWithError::), nil
                );
            }
            accessoryType:^UITableViewCellAccessoryType(id image) {
                return UITableViewCellAccessoryDisclosureIndicator;
            }
        ]
    ]];
}

@end


@implementation UIAlertController (FLEXImageShortcuts)

- (void)flex_image:(UIImage *)image disSaveWithError:(NSError *)error :(void *)context {
    self.title = @"Image Saved";
    flex_dispatch_after(1, dispatch_get_main_queue(), ^{
        [self dismissViewControllerAnimated:YES completion:nil];
    });
}

@end
