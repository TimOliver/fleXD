//
//  UIBarButtonItem+FLEX.h
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

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#define FLEXBarButtonItem(title, tgt, sel) \
    [UIBarButtonItem flex_itemWithTitle:title target:tgt action:sel]
#define FLEXBarButtonItemSystem(item, tgt, sel) \
    [UIBarButtonItem flex_systemItem:UIBarButtonSystemItem##item target:tgt action:sel]

@interface UIBarButtonItem (FLEX)

/// A flexible-space bar button item.
@property (nonatomic, readonly, class) UIBarButtonItem *flex_flexibleSpace;
/// A zero-width fixed-space bar button item.
@property (nonatomic, readonly, class) UIBarButtonItem *flex_fixedSpace;

/// Creates a bar button item wrapping a custom view.
+ (instancetype)flex_itemWithCustomView:(UIView *)customView;
/// Creates a back bar button item with the given title.
+ (instancetype)flex_backItemWithTitle:(NSString *)title;

/// Creates a bar button item using a system item style with a target and action.
+ (instancetype)flex_systemItem:(UIBarButtonSystemItem)item
                         target:(nullable id)target
                         action:(nullable SEL)action;

/// Creates a plain bar button item with the given title, target, and action.
+ (instancetype)flex_itemWithTitle:(NSString *)title
                            target:(nullable id)target
                            action:(nullable SEL)action;
/// Creates a done-style bar button item with the given title, target, and action.
+ (instancetype)flex_doneStyleitemWithTitle:(NSString *)title
                                     target:(nullable id)target
                                     action:(nullable SEL)action;

/// Creates a bar button item with the given image, target, and action.
+ (instancetype)flex_itemWithImage:(UIImage *)image
                            target:(nullable id)target
                            action:(nullable SEL)action;

/// Creates a disabled bar button item using a system item style.
+ (instancetype)flex_disabledSystemItem:(UIBarButtonSystemItem)item;
/// Creates a disabled bar button item with the given title and style.
+ (instancetype)flex_disabledItemWithTitle:(NSString *)title style:(UIBarButtonItemStyle)style;
/// Creates a disabled bar button item with the given image.
+ (instancetype)flex_disabledItemWithImage:(UIImage *)image;

/// Applies the given tint color to the receiver and returns it.
- (UIBarButtonItem *)flex_withTintColor:(UIColor *)tint;

- (void)_setWidth:(CGFloat)width;

@end

NS_ASSUME_NONNULL_END
