//
//  UIBarButtonItem+FLEX.m
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

#import "UIBarButtonItem+FLEX.h"

#pragma clang diagnostic ignored "-Wincomplete-implementation"

@implementation UIBarButtonItem (FLEX)

+ (UIBarButtonItem *)flex_flexibleSpace {
    return [self flex_systemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
}

+ (UIBarButtonItem *)flex_fixedSpace {
    UIBarButtonItem *fixed = [self flex_systemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    fixed.width = 60;
    return fixed;
}

+ (instancetype)flex_systemItem:(UIBarButtonSystemItem)item target:(id)target action:(SEL)action {
    return [[self alloc] initWithBarButtonSystemItem:item target:target action:action];
}

+ (instancetype)flex_itemWithCustomView:(UIView *)customView {
    return [[self alloc] initWithCustomView:customView];
}

+ (instancetype)flex_backItemWithTitle:(NSString *)title {
    return [self flex_itemWithTitle:title target:nil action:nil];
}

+ (instancetype)flex_itemWithTitle:(NSString *)title target:(id)target action:(SEL)action {
    return [[self alloc] initWithTitle:title style:UIBarButtonItemStylePlain target:target action:action];
}

+ (instancetype)flex_doneStyleitemWithTitle:(NSString *)title target:(id)target action:(SEL)action {
    return [[self alloc] initWithTitle:title style:UIBarButtonItemStyleDone target:target action:action];
}

+ (instancetype)flex_itemWithImage:(UIImage *)image target:(id)target action:(SEL)action {
    return [[self alloc] initWithImage:image style:UIBarButtonItemStylePlain target:target action:action];
}

+ (instancetype)flex_disabledSystemItem:(UIBarButtonSystemItem)system {
    UIBarButtonItem *item = [self flex_systemItem:system target:nil action:nil];
    item.enabled = NO;
    return item;
}

+ (instancetype)flex_disabledItemWithTitle:(NSString *)title style:(UIBarButtonItemStyle)style {
    UIBarButtonItem *item = [self flex_itemWithTitle:title target:nil action:nil];
    item.enabled = NO;
    return item;
}

+ (instancetype)flex_disabledItemWithImage:(UIImage *)image {
    UIBarButtonItem *item = [self flex_itemWithImage:image target:nil action:nil];
    item.enabled = NO;
    return item;
}

- (UIBarButtonItem *)flex_withTintColor:(UIColor *)tint {
    self.tintColor = tint;
    return self;
}

@end
