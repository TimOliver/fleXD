//
//  CALayer+FLEX.m
//  FLEX
//
//  Created by Tanner on 2/28/20.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

#import "CALayer+FLEX.h"

@implementation CALayer (FLEX)

- (BOOL)flex_continuousCorners {
    return self.cornerCurve == kCACornerCurveContinuous;
}

- (void)setFlex_continuousCorners:(BOOL)enabled {
    self.cornerCurve = enabled ? kCACornerCurveContinuous : kCACornerCurveDefault;
}

@end
