//
//  UIFont+FLEX.h
//  FLEX
//
//  Created by Tanner Bennett on 12/20/19.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIFont (FLEX)

/// The default font used in FLEX table view cells.
@property (nonatomic, readonly, class) UIFont *flex_defaultTableCellFont;

/// A monospaced font for displaying code or raw values at the default cell font size.
@property (nonatomic, readonly, class) UIFont *flex_codeFont;

/// A monospaced font for displaying code or raw values at the small system font size.
@property (nonatomic, readonly, class) UIFont *flex_smallCodeFont;

@end

NS_ASSUME_NONNULL_END
