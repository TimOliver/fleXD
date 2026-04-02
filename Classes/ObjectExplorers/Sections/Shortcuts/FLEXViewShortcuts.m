//
//  FLEXViewShortcuts.m
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

#import "FLEXViewShortcuts.h"
#import "FLEXShortcut.h"
#import "FLEXRuntimeUtility.h"
#import "FLEXObjectExplorerFactory.h"
#import "FLEXImagePreviewViewController.h"

@interface FLEXViewShortcuts ()
@property (nonatomic, readonly) UIView *view;
@end

@implementation FLEXViewShortcuts

#pragma mark - Internal

- (UIView *)view {
    return self.object;
}

+ (UIViewController *)viewControllerForView:(UIView *)view {
    NSString * const viewDelegate = @"viewDelegate";
    if ([view respondsToSelector:NSSelectorFromString(viewDelegate)]) {
        return [view valueForKey:viewDelegate];
    }

    return nil;
}

+ (UIViewController *)viewControllerForAncestralView:(UIView *)view {
    NSString * const _viewControllerForAncestor = @"_viewControllerForAncestor";
    if ([view respondsToSelector:NSSelectorFromString(_viewControllerForAncestor)]) {
        return [view valueForKey:_viewControllerForAncestor];
    }

    return nil;
}

+ (UIViewController *)nearestViewControllerForView:(UIView *)view {
    return [self viewControllerForView:view] ?: [self viewControllerForAncestralView:view];
}


#pragma mark - Overrides

+ (instancetype)forObject:(UIView *)view {
    // In the past, FLEX would not hold a strong reference to something like this.
    // After using FLEX for so long, I am certain it is more useful to eagerly
    // reference something as useful as a view controller so that the reference
    // is not lost and swept out from under you before you can access it.
    //
    // The alternative here is to use a future in place of `controller` which would
    // dynamically grab a reference to the view controller. 99% of the time, however,
    // it is not all that useful. If you need it to refresh, you can simply go back
    // and go forward again and it will show if the view controller is nil or changed.
    UIViewController *controller = [FLEXViewShortcuts nearestViewControllerForView:view];

    return [self forObject:view additionalRows:@[
        [FLEXActionShortcut title:@"Nearest View Controller"
            subtitle:^NSString *(id view) {
                return [FLEXRuntimeUtility safeDescriptionForObject:controller];
            }
            viewer:^UIViewController *(id view) {
                return [FLEXObjectExplorerFactory explorerViewControllerForObject:controller];
            }
            accessoryType:^UITableViewCellAccessoryType(id view) {
                return controller ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
            }
        ],
        [FLEXActionShortcut title:@"Preview Image" subtitle:^NSString *(UIView *view) {
                return !CGRectIsEmpty(view.bounds) ? @"" : @"Unavailable with empty bounds";
            }
            viewer:^UIViewController *(UIView *view) {
                return [FLEXImagePreviewViewController previewForView:view];
            }
            accessoryType:^UITableViewCellAccessoryType(UIView *view) {
                // Disable preview if bounds are CGRectZero
                return !CGRectIsEmpty(view.bounds) ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
            }
        ]
    ]];
}

@end
