//
//  FLEXToolbarStashMath.h
//  FLEX
//
//  Pure geometry helpers for PiP-style toolbar stashing. Header-only
//  (static inline) so the explorer view controller and the unit tests can
//  both use them without a separate compilation unit.
//

#import <UIKit/UIKit.h>
#import "FLEXExplorerToolbar.h"   // FLEXToolbarStashEdge

/// Normalized initial velocity for one axis of a UISpringTimingParameters:
/// gesture velocity (pt/s) over remaining travel (pt). Returns 0 for a
/// near-zero distance, and clamps the magnitude so a tiny tuck with a fast
/// flick can't produce an explosive spring.
static inline CGFloat FLEXRelativeSpringVelocity(CGFloat velocity, CGFloat distance, CGFloat maxMagnitude) {
    if (fabs(distance) < 0.5) {
        return 0.0;
    }
    CGFloat relative = velocity / distance;
    if (relative >  maxMagnitude) return  maxMagnitude;
    if (relative < -maxMagnitude) return -maxMagnitude;
    return relative;
}
