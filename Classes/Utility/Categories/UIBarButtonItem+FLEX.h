//
//  UIBarButtonItem+FLEX.h
//  FLEX
//
//  Created by Tanner on 2/4/20.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

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
