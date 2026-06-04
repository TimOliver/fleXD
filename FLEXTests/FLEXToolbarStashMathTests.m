//
//  FLEXToolbarStashMathTests.m
//  FLEXTests
//

#import <XCTest/XCTest.h>
#import "FLEXToolbarStashMath.h"

@interface FLEXToolbarStashMathTests : XCTestCase
@end

@implementation FLEXToolbarStashMathTests

#pragma mark - FLEXRelativeSpringVelocity

- (void)testRelativeVelocityIsVelocityOverDistance {
    // 1000 pt/s over 250 pt of remaining travel -> 4.0 (distance-fractions/sec)
    XCTAssertEqualWithAccuracy(FLEXRelativeSpringVelocity(1000, 250, 30), 4.0, 0.0001);
}

- (void)testRelativeVelocityZeroDistanceGuard {
    XCTAssertEqual(FLEXRelativeSpringVelocity(1000, 0,   30), 0.0);
    XCTAssertEqual(FLEXRelativeSpringVelocity(1000, 0.2, 30), 0.0); // below the 0.5 guard
}

- (void)testRelativeVelocityClampsLargeMagnitude {
    // 3000 pt/s over 5 pt would be 600; clamp to +/-30
    XCTAssertEqual(FLEXRelativeSpringVelocity( 3000, 5, 30),  30.0);
    XCTAssertEqual(FLEXRelativeSpringVelocity(-3000, 5, 30), -30.0);
}

#pragma mark - FLEXStashEdgeForRelease

- (void)testHardFlingLeftStashesLeft {
    // projected = 160 + (-2000 * 0.167) = -174 <= 0 + 44 -> Left
    XCTAssertEqual(FLEXStashEdgeForRelease(CGPointMake(-2000, 0), 160, 0, 320, 44, 0.167),
                   FLEXToolbarStashEdgeLeft);
}

- (void)testHardFlingRightStashesRight {
    // projected = 160 + (2000 * 0.167) = 494 >= 320 - 44 -> Right
    XCTAssertEqual(FLEXStashEdgeForRelease(CGPointMake(2000, 0), 160, 0, 320, 44, 0.167),
                   FLEXToolbarStashEdgeRight);
}

- (void)testGentleReleaseFromCenterDoesNotStash {
    // projected = 160 + (100 * 0.167) = 176.7 -> between bands -> None
    XCTAssertEqual(FLEXStashEdgeForRelease(CGPointMake(100, 0), 160, 0, 320, 44, 0.167),
                   FLEXToolbarStashEdgeNone);
}

- (void)testPredominantlyVerticalFlingNeverStashes {
    // |x| 2000 < |y| 3000 -> vertical intent -> None even though x alone reaches the edge
    XCTAssertEqual(FLEXStashEdgeForRelease(CGPointMake(-2000, -3000), 160, 0, 320, 44, 0.167),
                   FLEXToolbarStashEdgeNone);
}

- (void)testProjectionIsPositionAware {
    // From near the right edge (center 290), a modest fling that wouldn't stash
    // from center does stash: projected = 290 + (400 * 0.167) = 356.8 >= 276 -> Right
    XCTAssertEqual(FLEXStashEdgeForRelease(CGPointMake(400, 0), 290, 0, 320, 44, 0.167),
                   FLEXToolbarStashEdgeRight);
}

#pragma mark - FLEXProjectedStashCenterY

- (void)testProjectedStashYProjectsTowardFlick {
    // centerY 400, vy -1000, decel 0.167 -> 400 - 167 = 233, within [100, 700]
    XCTAssertEqualWithAccuracy(FLEXProjectedStashCenterY(400, -1000, 0.167, 100, 700), 233.0, 0.5);
}

- (void)testProjectedStashYClampsToMin {
    // 200 + (-3000 * 0.167) = -301 -> clamp to minY 100
    XCTAssertEqual(FLEXProjectedStashCenterY(200, -3000, 0.167, 100, 700), 100.0);
}

- (void)testProjectedStashYClampsToMax {
    // 600 + (3000 * 0.167) = 1101 -> clamp to maxY 700
    XCTAssertEqual(FLEXProjectedStashCenterY(600, 3000, 0.167, 100, 700), 700.0);
}

- (void)testProjectedStashYNoVerticalVelocityStaysPut {
    XCTAssertEqualWithAccuracy(FLEXProjectedStashCenterY(400, 0, 0.167, 100, 700), 400.0, 0.0001);
}

@end
