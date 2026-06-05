#import <XCTest/XCTest.h>
#import <execinfo.h>
#import "FLEXNotificationRegistration.h"

static NSArray<NSNumber *> *CaptureAddresses(void) {
    void *frames[64];
    int n = backtrace(frames, 64);
    NSMutableArray<NSNumber *> *a = [NSMutableArray array];
    for (int i = 0; i < n; i++) { [a addObject:@((uintptr_t)frames[i])]; }
    return a;
}

@interface FLEXNotificationRegistrationTests : XCTestCase
@end

@implementation FLEXNotificationRegistrationTests

- (void)testCapturesIdentifyingFields {
    NSObject *observer = [NSObject new];
    NSObject *object = [NSObject new];
    FLEXNotificationRegistration *reg = [FLEXNotificationRegistration
        registrationWithObserver:observer selectorString:@"handle:"
        name:@"MyNote" object:object returnAddresses:CaptureAddresses()];

    XCTAssertEqualObjects(reg.observerClassName, @"NSObject");
    XCTAssertEqual(reg.observerPointer, (uintptr_t)observer);
    XCTAssertEqualObjects(reg.selectorString, @"handle:");
    XCTAssertEqualObjects(reg.notificationName, @"MyNote");
    XCTAssertEqual(reg.observedObjectPointer, (uintptr_t)object);
    XCTAssertEqual(reg.state, FLEXNotificationObserverStateAlive);
}

- (void)testNilSelectorBecomesBlockMarker {
    NSObject *token = [NSObject new];
    FLEXNotificationRegistration *reg = [FLEXNotificationRegistration
        registrationWithObserver:token selectorString:nil
        name:nil object:nil returnAddresses:@[]];
    XCTAssertEqualObjects(reg.selectorString, @"(block)");
}

- (void)testStateFlipsToDeallocatedAfterObserverDies {
    FLEXNotificationRegistration *reg;
    @autoreleasepool {
        NSObject *observer = [NSObject new];
        reg = [FLEXNotificationRegistration
            registrationWithObserver:observer selectorString:@"x"
            name:nil object:nil returnAddresses:@[]];
        XCTAssertEqual(reg.state, FLEXNotificationObserverStateAlive);
    }
    XCTAssertEqual(reg.state, FLEXNotificationObserverStateDeallocated);
    XCTAssertNil(reg.observer);
}

- (void)testIsOursForAppCodeBacktrace {
    FLEXNotificationRegistration *reg = [FLEXNotificationRegistration
        registrationWithObserver:[NSObject new] selectorString:@"x"
        name:nil object:nil returnAddresses:CaptureAddresses()];
    XCTAssertTrue(reg.isOurs); // this test code lives in the test bundle == main bundle
}

@end
