//
//  FLEXColorPreviewSection.h
//  FLEX
//
//  Created by Tanner Bennett on 12/12/19.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

#import "FLEXSingleRowSection.h"
#import "FLEXObjectInfoSection.h"

NS_ASSUME_NONNULL_BEGIN

/// A single-row section that displays a color swatch preview for a `UIColor`
@interface FLEXColorPreviewSection : FLEXSingleRowSection <FLEXObjectInfoSection>

+ (instancetype)forObject:(UIColor *)color;

@end

NS_ASSUME_NONNULL_END
