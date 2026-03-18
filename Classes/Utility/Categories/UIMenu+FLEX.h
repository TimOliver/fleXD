//
//  UIMenu+FLEX.h
//  FLEX
//
//  Created by Tanner on 1/28/20.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIMenu (FLEX)

/// Creates a menu configured with `UIMenuOptionsDisplayInline` causing its children
/// to appear inline within the parent menu rather than as a submenu.
+ (instancetype)flex_inlineMenuWithTitle:(NSString *)title
                                   image:(nullable UIImage *)image
                                children:(NSArray<UIMenuElement *> *)children;

/// Returns a copy of the receiver configured with `UIMenuOptionsDisplayInline`
- (instancetype)flex_collapsed;

@end

NS_ASSUME_NONNULL_END
