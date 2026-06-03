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

@end
