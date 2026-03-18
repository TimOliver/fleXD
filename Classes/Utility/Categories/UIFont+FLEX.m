//
//  UIFont+FLEX.m
//  FLEX
//
//  Created by Tanner Bennett on 12/20/19.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

#import "UIFont+FLEX.h"

#define kFLEXDefaultCellFontSize 12.0

@implementation UIFont (FLEX)

+ (UIFont *)flex_defaultTableCellFont {
    static UIFont *defaultTableCellFont = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        defaultTableCellFont = [UIFont systemFontOfSize:kFLEXDefaultCellFontSize];
    });

    return defaultTableCellFont;
}

+ (UIFont *)flex_codeFont {
    return [self monospacedSystemFontOfSize:kFLEXDefaultCellFontSize weight:UIFontWeightRegular];
}

+ (UIFont *)flex_smallCodeFont {
    return [self monospacedSystemFontOfSize:self.smallSystemFontSize weight:UIFontWeightRegular];
}

@end
