//
//  CALayer+FLEX.h
//  FLEX
//
//  Created by Tanner on 2/28/20.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface CALayer (FLEX)

/// Whether the layer uses continuous (squircle-style) corner curves.
///
/// Wraps \c cornerCurve using \c kCACornerCurveContinuous and \c kCACornerCurveCircular.
@property (nonatomic) BOOL flex_continuousCorners;

@end

NS_ASSUME_NONNULL_END
