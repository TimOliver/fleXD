# Notification Observers Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the removed crash-prone `flex_observers` shortcut with a safe, swizzle-based registry of `NSNotificationCenter` observers, viewable from the FLEX globals menu, that surfaces deallocated-but-still-registered leaks.

**Architecture:** Swizzle `NSNotificationCenter`'s add/remove entry points (via FLEX's existing `FLEXUtility` helpers). Each registration is captured into a `FLEXNotificationRegistration` model holding a *zeroing weak reference* to the observer (so a dead observer is detected without messaging it) plus a backtrace for call-site attribution. Records live in a thread-safe singleton `FLEXNotificationRecorder` (serial queue, mirroring `FLEXNetworkRecorder`). A `FLEXFilteringTableViewController` displays them, hidden behind an opt-in `NSUserDefaults` toggle like `FLEXNetworkObserver`.

**Tech Stack:** Objective-C, UIKit, Objective-C runtime (`objc/runtime.h`), `<execinfo.h>` (`backtrace`), `<dlfcn.h>` (`dladdr`), GCD, XCTest. Built via `FLEX.xcodeproj` (`FLEX` + `FLEXTests` schemes).

**Design spec:** `docs/superpowers/specs/2026-06-05-notification-observers-design.md`

---

## Build & test conventions (read first)

- **Simulator:** use `iPhone 17 Pro` (confirmed available in this environment). To run a single test class, append `-only-testing:FLEXTests/<ClassName>`.
  ```bash
  xcodebuild test -project FLEX.xcodeproj -scheme FLEXTests \
    -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -40
  ```
- **Adding new files to the build:** the `FLEX.xcodeproj` targets do **not** auto-glob (only SPM does). After creating files, add them to the target with the headless helper (no Xcode GUI needed):
  ```bash
  ruby Scripts/xcode_add_file.rb FLEX <new-source-and-header-paths...>
  ruby Scripts/xcode_add_file.rb FLEXTests <new-test-paths...>
  ```
  The helper is idempotent. If a file is missing from the target, the build fails with `Undefined symbols ... _OBJC_CLASS_$_<Class>` — that error is your signal it wasn't added.
- **New folder:** all non-test feature files live in `Classes/GlobalStateExplorers/NotificationObservers/`.
- **Commit cadence:** one commit per task (TDD: red → green → commit).

---

## Task 0: Establish a green baseline

**Files:** none created; possibly modify `FLEX.xcodeproj/project.pbxproj` (target membership only).

- [ ] **Step 1: Build the FLEX framework**

Run:
```bash
xcodebuild build -project FLEX.xcodeproj -scheme FLEX \
  -destination 'generic/platform=iOS Simulator' -configuration Debug 2>&1 | tail -15
```

- [ ] **Step 2: If it fails with `Undefined symbols ... _OBJC_CLASS_$_FLEXImagePreviewController`**

This is a pre-existing photo-viewer-branch issue: `FLEXImagePreviewController.m`/`.h` (and `FLEXImagePreviewTitleView.m`/`.h`) under `Classes/GlobalStateExplorers/FileBrowser/` are not members of the FLEX target. Add them to the **FLEX** target (File Inspector → Target Membership). Rebuild Step 1 until it reports `** BUILD SUCCEEDED **`.

- [ ] **Step 3: Run the existing tests to confirm a green starting point**

Run:
```bash
xcodebuild test -project FLEX.xcodeproj -scheme FLEXTests \
  -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -20
```
Expected: `** TEST SUCCEEDED **`. Do not proceed until green.

- [ ] **Step 4: Commit (only if you changed target membership)**

```bash
git add FLEX.xcodeproj/project.pbxproj
git commit -m "Add photo-viewer files to FLEX target for buildable baseline"
```

---

## Task 1: `FLEXNotificationRegistration` model

**Files:**
- Create: `Classes/GlobalStateExplorers/NotificationObservers/FLEXNotificationRegistration.h`
- Create: `Classes/GlobalStateExplorers/NotificationObservers/FLEXNotificationRegistration.m`
- Test: `FLEXTests/FLEXNotificationRegistrationTests.m`

- [ ] **Step 1: Create the header**

`FLEXNotificationRegistration.h`:
```objc
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, FLEXNotificationObserverState) {
    FLEXNotificationObserverStateAlive,
    FLEXNotificationObserverStateDeallocated,
    FLEXNotificationObserverStateUnknown, // observer class doesn't support weak refs
};

/// An immutable record of one NSNotificationCenter observer registration.
/// Holds a zeroing weak reference to the observer so deallocation can be
/// detected without ever messaging a (possibly dangling) object.
@interface FLEXNotificationRegistration : NSObject

+ (instancetype)registrationWithObserver:(id)observer
                          selectorString:(nullable NSString *)selectorString
                                    name:(nullable NSString *)name
                                  object:(nullable id)object
                         returnAddresses:(NSArray<NSNumber *> *)returnAddresses;

@property (nonatomic, readonly, copy) NSString *observerClassName;
@property (nonatomic, readonly) uintptr_t observerPointer;
/// nil once the observer has been deallocated
@property (nonatomic, readonly, weak, nullable) id observer;
@property (nonatomic, readonly, copy, nullable) NSString *notificationName;
/// Selector name, or @"(block)" for the block-based API
@property (nonatomic, readonly, copy) NSString *selectorString;
@property (nonatomic, readonly, weak, nullable) id observedObject;
@property (nonatomic, readonly) uintptr_t observedObjectPointer;
@property (nonatomic, readonly, copy, nullable) NSString *observedObjectClassName;
@property (nonatomic, readonly, copy) NSArray<NSNumber *> *returnAddresses;
/// YES if a backtrace frame resolves to the main app bundle (incl. embedded frameworks)
@property (nonatomic, readonly) BOOL isOurs;
@property (nonatomic, readonly) NSDate *registeredAt;
/// NO if the observer's class does not support zeroing weak references
@property (nonatomic, readonly) BOOL weakSupported;

@property (nonatomic, readonly) FLEXNotificationObserverState state;
/// Lazily computed, readable frames like "MyApp  0x...  -[Foo bar] + 42"
@property (nonatomic, readonly, copy) NSArray<NSString *> *symbolicatedBacktrace;

@end

NS_ASSUME_NONNULL_END
```

- [ ] **Step 2: Write the failing test**

`FLEXTests/FLEXNotificationRegistrationTests.m`:
```objc
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
```

- [ ] **Step 3: Run the test to verify it fails**

Run:
```bash
xcodebuild test -project FLEX.xcodeproj -scheme FLEXTests \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:FLEXTests/FLEXNotificationRegistrationTests 2>&1 | tail -20
```
Expected: build failure (`'FLEXNotificationRegistration.h' file not found` until Step 4 adds the file & membership).

- [ ] **Step 4: Create the implementation**

`FLEXNotificationRegistration.m`:
```objc
#import "FLEXNotificationRegistration.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import <dlfcn.h>

/// Mirrors what objc's storeWeak does: respect a class that overrides
/// -allowsWeakReference to return NO, so we never trip the runtime's fatal.
static BOOL FLEXObjectSupportsWeakReference(id object) {
    if (!object) return NO;
    Class cls = object_getClass(object);
    SEL sel = NSSelectorFromString(@"allowsWeakReference");
    IMP base = class_getMethodImplementation(NSObject.class, sel);
    IMP cur = class_getMethodImplementation(cls, sel);
    if (cur == base) {
        return YES; // not overridden; default NSObject behavior allows weak refs
    }
    return ((BOOL (*)(id, SEL))objc_msgSend)(object, sel);
}

static BOOL FLEXAddressesContainAppFrame(NSArray<NSNumber *> *addresses) {
    NSString *mainPath = NSBundle.mainBundle.bundlePath;
    if (!mainPath.length) return NO;
    for (NSNumber *addr in addresses) {
        Dl_info info;
        if (dladdr((const void *)(uintptr_t)addr.unsignedLongLongValue, &info) && info.dli_fname) {
            if ([@(info.dli_fname) hasPrefix:mainPath]) {
                return YES;
            }
        }
    }
    return NO;
}

@implementation FLEXNotificationRegistration {
    __weak id _observer;
    __weak id _observedObject;
}

+ (instancetype)registrationWithObserver:(id)observer
                          selectorString:(NSString *)selectorString
                                    name:(NSString *)name
                                  object:(id)object
                         returnAddresses:(NSArray<NSNumber *> *)returnAddresses {
    FLEXNotificationRegistration *reg = [self new];
    reg->_observerPointer = (uintptr_t)observer;
    reg->_observerClassName = NSStringFromClass(object_getClass(observer));
    reg->_selectorString = [selectorString copy] ?: @"(block)";
    reg->_notificationName = [name copy];
    reg->_observedObjectPointer = (uintptr_t)object;
    reg->_observedObjectClassName = object ? NSStringFromClass(object_getClass(object)) : nil;
    reg->_returnAddresses = [returnAddresses copy] ?: @[];
    reg->_registeredAt = [NSDate date];
    reg->_isOurs = FLEXAddressesContainAppFrame(reg->_returnAddresses);

    if (FLEXObjectSupportsWeakReference(observer)) {
        reg->_observer = observer;
        reg->_weakSupported = YES;
    } else {
        reg->_weakSupported = NO;
    }
    if (object && FLEXObjectSupportsWeakReference(object)) {
        reg->_observedObject = object;
    }
    return reg;
}

- (id)observer { return _observer; }
- (id)observedObject { return _observedObject; }

- (FLEXNotificationObserverState)state {
    if (!_weakSupported) return FLEXNotificationObserverStateUnknown;
    return _observer ? FLEXNotificationObserverStateAlive : FLEXNotificationObserverStateDeallocated;
}

- (NSArray<NSString *> *)symbolicatedBacktrace {
    NSMutableArray<NSString *> *frames = [NSMutableArray array];
    for (NSNumber *addr in _returnAddresses) {
        void *ptr = (void *)(uintptr_t)addr.unsignedLongLongValue;
        Dl_info info;
        if (dladdr(ptr, &info)) {
            NSString *image = info.dli_fname ? @(info.dli_fname).lastPathComponent : @"???";
            NSString *symbol = info.dli_sname ? @(info.dli_sname) : @"???";
            unsigned long offset = (unsigned long)((uintptr_t)ptr - (uintptr_t)info.dli_saddr);
            [frames addObject:[NSString stringWithFormat:@"%@  0x%016lx  %@ + %lu",
                image, (unsigned long)(uintptr_t)ptr, symbol, offset]];
        } else {
            [frames addObject:[NSString stringWithFormat:@"0x%016lx  ???",
                (unsigned long)(uintptr_t)ptr]];
        }
    }
    return frames;
}

@end
```

- [ ] **Step 5: Add files to targets**

Add `FLEXNotificationRegistration.m` to the **FLEX** target and `FLEXNotificationRegistrationTests.m` to the **FLEXTests** target (File Inspector → Target Membership).

- [ ] **Step 6: Run the test to verify it passes**

Run the Step 3 command. Expected: `** TEST SUCCEEDED **` (4 tests pass).

- [ ] **Step 7: Commit**

```bash
git add Classes/GlobalStateExplorers/NotificationObservers/FLEXNotificationRegistration.* \
        FLEXTests/FLEXNotificationRegistrationTests.m FLEX.xcodeproj/project.pbxproj
git commit -m "Add FLEXNotificationRegistration model with weak-ref state tracking"
```

---

## Task 2: `FLEXNotificationRecorder` store

**Files:**
- Create: `Classes/GlobalStateExplorers/NotificationObservers/FLEXNotificationRecorder.h`
- Create: `Classes/GlobalStateExplorers/NotificationObservers/FLEXNotificationRecorder.m`
- Test: `FLEXTests/FLEXNotificationRecorderTests.m`

- [ ] **Step 1: Create the header**

`FLEXNotificationRecorder.h`:
```objc
#import <Foundation/Foundation.h>

@class FLEXNotificationRegistration;

NS_ASSUME_NONNULL_BEGIN

/// Posted on the main thread whenever the set of registrations changes.
extern NSString *const kFLEXNotificationRecorderUpdatedNotification;

/// Thread-safe store of observer registrations (serial-queue backed,
/// mirroring FLEXNetworkRecorder).
@interface FLEXNotificationRecorder : NSObject

@property (class, nonatomic, readonly) FLEXNotificationRecorder *sharedRecorder;

/// A snapshot of current registrations, in registration order.
@property (nonatomic, readonly) NSArray<FLEXNotificationRegistration *> *registrations;

- (void)addRegistration:(FLEXNotificationRegistration *)registration;

/// Mirrors -[NSNotificationCenter removeObserver:] — removes every
/// registration for the given observer pointer.
- (void)removeAllRegistrationsForObserverPointer:(uintptr_t)observerPointer;

/// Mirrors -[NSNotificationCenter removeObserver:name:object:] — a nil name
/// (pass nil) or zero objectPointer matches any.
- (void)removeRegistrationsForObserverPointer:(uintptr_t)observerPointer
                                         name:(nullable NSString *)name
                                objectPointer:(uintptr_t)objectPointer;

- (void)clear;

@end

NS_ASSUME_NONNULL_END
```

- [ ] **Step 2: Write the failing test**

`FLEXTests/FLEXNotificationRecorderTests.m`:
```objc
#import <XCTest/XCTest.h>
#import "FLEXNotificationRecorder.h"
#import "FLEXNotificationRegistration.h"

@interface FLEXNotificationRecorderTests : XCTestCase
@end

@implementation FLEXNotificationRecorderTests {
    FLEXNotificationRecorder *_recorder;
    NSObject *_observerA;
    NSObject *_observerB;
}

- (void)setUp {
    _recorder = [FLEXNotificationRecorder new]; // fresh instance, not the singleton
    _observerA = [NSObject new];
    _observerB = [NSObject new];
}

- (FLEXNotificationRegistration *)regFor:(id)observer name:(NSString *)name object:(id)object {
    return [FLEXNotificationRegistration registrationWithObserver:observer
        selectorString:@"x" name:name object:object returnAddresses:@[]];
}

- (void)testAddAndSnapshot {
    [_recorder addRegistration:[self regFor:_observerA name:@"N1" object:nil]];
    [_recorder addRegistration:[self regFor:_observerB name:@"N2" object:nil]];
    XCTAssertEqual(_recorder.registrations.count, 2); // serial queue guarantees ordering
}

- (void)testRemoveAllForObserver {
    [_recorder addRegistration:[self regFor:_observerA name:@"N1" object:nil]];
    [_recorder addRegistration:[self regFor:_observerA name:@"N2" object:nil]];
    [_recorder addRegistration:[self regFor:_observerB name:@"N3" object:nil]];
    [_recorder removeAllRegistrationsForObserverPointer:(uintptr_t)_observerA];
    XCTAssertEqual(_recorder.registrations.count, 1);
    XCTAssertEqual(_recorder.registrations.firstObject.observerPointer, (uintptr_t)_observerB);
}

- (void)testRemoveByNameMatchesOnlyThatName {
    [_recorder addRegistration:[self regFor:_observerA name:@"N1" object:nil]];
    [_recorder addRegistration:[self regFor:_observerA name:@"N2" object:nil]];
    [_recorder removeRegistrationsForObserverPointer:(uintptr_t)_observerA name:@"N1" objectPointer:0];
    XCTAssertEqual(_recorder.registrations.count, 1);
    XCTAssertEqualObjects(_recorder.registrations.firstObject.notificationName, @"N2");
}

- (void)testClear {
    [_recorder addRegistration:[self regFor:_observerA name:@"N1" object:nil]];
    [_recorder clear];
    XCTAssertEqual(_recorder.registrations.count, 0);
}

@end
```

- [ ] **Step 3: Run the test to verify it fails**

Run:
```bash
xcodebuild test -project FLEX.xcodeproj -scheme FLEXTests \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:FLEXTests/FLEXNotificationRecorderTests 2>&1 | tail -20
```
Expected: build failure (`'FLEXNotificationRecorder.h' file not found`).

- [ ] **Step 4: Create the implementation**

`FLEXNotificationRecorder.m`:
```objc
#import "FLEXNotificationRecorder.h"
#import "FLEXNotificationRegistration.h"

NSString *const kFLEXNotificationRecorderUpdatedNotification = @"kFLEXNotificationRecorderUpdatedNotification";

#define FLEXSync(queue, expr) ({ \
    __block id __ret = nil; \
    dispatch_sync(queue, ^{ __ret = (expr); }); \
    __ret; \
})

@interface FLEXNotificationRecorder ()
@property (nonatomic) dispatch_queue_t queue;
@property (nonatomic) NSMutableArray<FLEXNotificationRegistration *> *mutableRegistrations;
@end

@implementation FLEXNotificationRecorder

+ (instancetype)sharedRecorder {
    static FLEXNotificationRecorder *shared = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ shared = [self new]; });
    return shared;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _queue = dispatch_queue_create("com.flex.FLEXNotificationRecorder", DISPATCH_QUEUE_SERIAL);
        _mutableRegistrations = [NSMutableArray array];
    }
    return self;
}

- (NSArray<FLEXNotificationRegistration *> *)registrations {
    return FLEXSync(self.queue, self.mutableRegistrations.copy);
}

- (void)addRegistration:(FLEXNotificationRegistration *)registration {
    dispatch_async(self.queue, ^{
        [self.mutableRegistrations addObject:registration];
        [self postUpdate];
    });
}

- (void)removeAllRegistrationsForObserverPointer:(uintptr_t)observerPointer {
    dispatch_async(self.queue, ^{
        NSIndexSet *idx = [self.mutableRegistrations indexesOfObjectsPassingTest:
            ^BOOL(FLEXNotificationRegistration *r, NSUInteger i, BOOL *stop) {
                return r.observerPointer == observerPointer;
            }];
        if (idx.count) {
            [self.mutableRegistrations removeObjectsAtIndexes:idx];
            [self postUpdate];
        }
    });
}

- (void)removeRegistrationsForObserverPointer:(uintptr_t)observerPointer
                                         name:(NSString *)name
                                objectPointer:(uintptr_t)objectPointer {
    dispatch_async(self.queue, ^{
        NSIndexSet *idx = [self.mutableRegistrations indexesOfObjectsPassingTest:
            ^BOOL(FLEXNotificationRegistration *r, NSUInteger i, BOOL *stop) {
                if (r.observerPointer != observerPointer) return NO;
                if (name && ![r.notificationName isEqualToString:name]) return NO;
                if (objectPointer && r.observedObjectPointer != objectPointer) return NO;
                return YES;
            }];
        if (idx.count) {
            [self.mutableRegistrations removeObjectsAtIndexes:idx];
            [self postUpdate];
        }
    });
}

- (void)clear {
    dispatch_async(self.queue, ^{
        [self.mutableRegistrations removeAllObjects];
        [self postUpdate];
    });
}

- (void)postUpdate {
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSNotificationCenter.defaultCenter
            postNotificationName:kFLEXNotificationRecorderUpdatedNotification object:self];
    });
}

@end
```

- [ ] **Step 5: Add files to targets**

`FLEXNotificationRecorder.m` → **FLEX** target; `FLEXNotificationRecorderTests.m` → **FLEXTests** target.

- [ ] **Step 6: Run the test to verify it passes**

Run the Step 3 command. Expected: `** TEST SUCCEEDED **` (4 tests pass).

- [ ] **Step 7: Commit**

```bash
git add Classes/GlobalStateExplorers/NotificationObservers/FLEXNotificationRecorder.* \
        FLEXTests/FLEXNotificationRecorderTests.m FLEX.xcodeproj/project.pbxproj
git commit -m "Add FLEXNotificationRecorder thread-safe registration store"
```

---

## Task 3: `FLEXNotificationMonitor` swizzles + enable toggle

**Files:**
- Create: `Classes/GlobalStateExplorers/NotificationObservers/FLEXNotificationMonitor.h`
- Create: `Classes/GlobalStateExplorers/NotificationObservers/FLEXNotificationMonitor.m`
- Test: `FLEXTests/FLEXNotificationMonitorTests.m`

- [ ] **Step 1: Create the header**

`FLEXNotificationMonitor.h`:
```objc
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Installs swizzles on NSNotificationCenter add/remove methods to feed
/// FLEXNotificationRecorder. Opt-in, gated by NSUserDefaults (mirrors
/// FLEXNetworkObserver). Swizzles install once and remain; recording no-ops
/// while disabled.
@interface FLEXNotificationMonitor : NSObject

@property (class, nonatomic) BOOL enabled;

/// Installs the swizzles if `enabled`. Safe to call repeatedly (dispatch_once).
+ (void)installIfEnabled;

@end

NS_ASSUME_NONNULL_END
```

- [ ] **Step 2: Write the failing test**

`FLEXTests/FLEXNotificationMonitorTests.m`:
```objc
#import <XCTest/XCTest.h>
#import "FLEXNotificationMonitor.h"
#import "FLEXNotificationRecorder.h"
#import "FLEXNotificationRegistration.h"

@interface FLEXNotificationMonitorTests : XCTestCase
@end

@implementation FLEXNotificationMonitorTests {
    BOOL _wasEnabled;
}

- (void)setUp {
    _wasEnabled = FLEXNotificationMonitor.enabled;
    FLEXNotificationMonitor.enabled = YES;   // installs swizzles once
    [FLEXNotificationMonitor installIfEnabled];
    [FLEXNotificationRecorder.sharedRecorder clear];
}

- (void)tearDown {
    FLEXNotificationMonitor.enabled = _wasEnabled;
}

- (FLEXNotificationRegistration *)findRegForName:(NSString *)name {
    for (FLEXNotificationRegistration *r in FLEXNotificationRecorder.sharedRecorder.registrations) {
        if ([r.notificationName isEqualToString:name]) return r;
    }
    return nil;
}

- (void)testSelectorObserverIsRecorded {
    NSNotificationCenter *ctr = [NSNotificationCenter new];
    NSObject *observer = [NSObject new];
    NSString *name = @"FLEXTest.selector";
    [ctr addObserver:observer selector:@selector(description) name:name object:nil];

    FLEXNotificationRegistration *reg = [self findRegForName:name];
    XCTAssertNotNil(reg);
    XCTAssertEqual(reg.observerPointer, (uintptr_t)observer);
    XCTAssertEqualObjects(reg.selectorString, @"description");
    [ctr removeObserver:observer];
}

- (void)testRemoveObserverDropsRecord {
    NSNotificationCenter *ctr = [NSNotificationCenter new];
    NSObject *observer = [NSObject new];
    NSString *name = @"FLEXTest.remove";
    [ctr addObserver:observer selector:@selector(description) name:name object:nil];
    XCTAssertNotNil([self findRegForName:name]);
    [ctr removeObserver:observer];
    XCTAssertNil([self findRegForName:name]);
}

- (void)testBlockObserverRecordedExactlyOnce {
    NSNotificationCenter *ctr = [NSNotificationCenter new];
    NSString *name = @"FLEXTest.block";
    id token = [ctr addObserverForName:name object:nil queue:nil usingBlock:^(NSNotification *n) {}];

    NSUInteger count = 0;
    FLEXNotificationRegistration *found = nil;
    for (FLEXNotificationRegistration *r in FLEXNotificationRecorder.sharedRecorder.registrations) {
        if ([r.notificationName isEqualToString:name]) { count++; found = r; }
    }
    XCTAssertEqual(count, 1, @"block registration should record exactly one entry");
    XCTAssertEqualObjects(found.selectorString, @"(block)");
    [ctr removeObserver:token];
}

- (void)testDisabledDoesNotRecord {
    FLEXNotificationMonitor.enabled = NO;
    [FLEXNotificationRecorder.sharedRecorder clear];
    NSNotificationCenter *ctr = [NSNotificationCenter new];
    NSObject *observer = [NSObject new];
    NSString *name = @"FLEXTest.disabled";
    [ctr addObserver:observer selector:@selector(description) name:name object:nil];
    XCTAssertNil([self findRegForName:name]);
    [ctr removeObserver:observer];
}

@end
```

> Note: `testBlockObserverRecordedExactlyOnce` guards against double-recording if `addObserverForName:...` internally routes through `addObserver:selector:name:object:`. If it fails with count==2, add to the selector-swizzle's guard (Step 4) a skip when `[NSStringFromClass(object_getClass(observer)) containsString:@"NSObserver"]`, then re-run.

- [ ] **Step 3: Run the test to verify it fails**

Run:
```bash
xcodebuild test -project FLEX.xcodeproj -scheme FLEXTests \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:FLEXTests/FLEXNotificationMonitorTests 2>&1 | tail -20
```
Expected: build failure (`'FLEXNotificationMonitor.h' file not found`).

- [ ] **Step 4: Create the implementation**

`FLEXNotificationMonitor.m`:
```objc
#import "FLEXNotificationMonitor.h"
#import "FLEXNotificationRecorder.h"
#import "FLEXNotificationRegistration.h"
#import "FLEXUtility.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import <execinfo.h>

static NSString *const kFLEXNotificationMonitorEnabledKey = @"com.flex.notificationObserverEnabled";

static NSArray<NSNumber *> *FLEXCaptureReturnAddresses(void) {
    void *frames[64];
    int count = backtrace(frames, 64);
    NSMutableArray<NSNumber *> *addrs = [NSMutableArray arrayWithCapacity:count];
    // Skip frame 0 (this fn) and 1 (the swizzle block) for cleaner attribution.
    for (int i = 2; i < count; i++) {
        [addrs addObject:@((uintptr_t)frames[i])];
    }
    return addrs;
}

static BOOL FLEXShouldRecordObserver(id observer) {
    if (!observer) return NO;
    // Don't record FLEX's own observers (reduces noise).
    return ![NSStringFromClass(object_getClass(observer)) hasPrefix:@"FLEX"];
}

@implementation FLEXNotificationMonitor

+ (BOOL)enabled {
    return [NSUserDefaults.standardUserDefaults boolForKey:kFLEXNotificationMonitorEnabledKey];
}

+ (void)setEnabled:(BOOL)enabled {
    [NSUserDefaults.standardUserDefaults setBool:enabled forKey:kFLEXNotificationMonitorEnabledKey];
    if (enabled) {
        [self installIfEnabled];
    }
}

+ (void)load {
    // Re-install on launch if the user enabled it in a previous session.
    dispatch_async(dispatch_get_main_queue(), ^{ [self installIfEnabled]; });
}

+ (void)installIfEnabled {
    if (!self.enabled) return;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ [self installSwizzles]; });
}

+ (void)installSwizzles {
    Class cls = NSNotificationCenter.class;

    SEL addSel = @selector(addObserver:selector:name:object:);
    SEL addSwz = [FLEXUtility swizzledSelectorForSelector:addSel];
    [FLEXUtility replaceImplementationOfKnownSelector:addSel onClass:cls
        withBlock:^(NSNotificationCenter *ctr, id observer, SEL selector, NSString *name, id object) {
            if (FLEXNotificationMonitor.enabled && FLEXShouldRecordObserver(observer)) {
                FLEXNotificationRegistration *reg = [FLEXNotificationRegistration
                    registrationWithObserver:observer
                    selectorString:NSStringFromSelector(selector)
                    name:name object:object returnAddresses:FLEXCaptureReturnAddresses()];
                [FLEXNotificationRecorder.sharedRecorder addRegistration:reg];
            }
            ((void (*)(id, SEL, id, SEL, id, id))objc_msgSend)(ctr, addSwz, observer, selector, name, object);
        } swizzledSelector:addSwz];

    SEL blockSel = @selector(addObserverForName:object:queue:usingBlock:);
    SEL blockSwz = [FLEXUtility swizzledSelectorForSelector:blockSel];
    [FLEXUtility replaceImplementationOfKnownSelector:blockSel onClass:cls
        withBlock:^id(NSNotificationCenter *ctr, NSString *name, id object, NSOperationQueue *queue, void(^block)(NSNotification *)) {
            id token = ((id (*)(id, SEL, id, id, id, id))objc_msgSend)(ctr, blockSwz, name, object, queue, block);
            if (FLEXNotificationMonitor.enabled && token) {
                FLEXNotificationRegistration *reg = [FLEXNotificationRegistration
                    registrationWithObserver:token
                    selectorString:nil
                    name:name object:object returnAddresses:FLEXCaptureReturnAddresses()];
                [FLEXNotificationRecorder.sharedRecorder addRegistration:reg];
            }
            return token;
        } swizzledSelector:blockSwz];

    SEL rm1 = @selector(removeObserver:);
    SEL rm1Swz = [FLEXUtility swizzledSelectorForSelector:rm1];
    [FLEXUtility replaceImplementationOfKnownSelector:rm1 onClass:cls
        withBlock:^(NSNotificationCenter *ctr, id observer) {
            if (FLEXNotificationMonitor.enabled && observer) {
                [FLEXNotificationRecorder.sharedRecorder
                    removeAllRegistrationsForObserverPointer:(uintptr_t)observer];
            }
            ((void (*)(id, SEL, id))objc_msgSend)(ctr, rm1Swz, observer);
        } swizzledSelector:rm1Swz];

    SEL rm2 = @selector(removeObserver:name:object:);
    SEL rm2Swz = [FLEXUtility swizzledSelectorForSelector:rm2];
    [FLEXUtility replaceImplementationOfKnownSelector:rm2 onClass:cls
        withBlock:^(NSNotificationCenter *ctr, id observer, NSString *name, id object) {
            if (FLEXNotificationMonitor.enabled && observer) {
                [FLEXNotificationRecorder.sharedRecorder
                    removeRegistrationsForObserverPointer:(uintptr_t)observer
                    name:name objectPointer:(uintptr_t)object];
            }
            ((void (*)(id, SEL, id, id, id))objc_msgSend)(ctr, rm2Swz, observer, name, object);
        } swizzledSelector:rm2Swz];
}

@end
```

- [ ] **Step 5: Add files to targets**

`FLEXNotificationMonitor.m` → **FLEX** target; `FLEXNotificationMonitorTests.m` → **FLEXTests** target.

- [ ] **Step 6: Run the test to verify it passes**

Run the Step 3 command. Expected: `** TEST SUCCEEDED **` (4 tests). If `testBlockObserverRecordedExactlyOnce` reports count==2, apply the guard from the Step 2 note and re-run.

- [ ] **Step 7: Commit**

```bash
git add Classes/GlobalStateExplorers/NotificationObservers/FLEXNotificationMonitor.* \
        FLEXTests/FLEXNotificationMonitorTests.m FLEX.xcodeproj/project.pbxproj
git commit -m "Add FLEXNotificationMonitor swizzles with opt-in toggle"
```

---

## Task 4: Section + viewer + globals menu entry

This task is UI; it is verified by build + manual smoke rather than unit tests.

**Files:**
- Create: `Classes/GlobalStateExplorers/NotificationObservers/FLEXNotificationObserverSection.h`
- Create: `Classes/GlobalStateExplorers/NotificationObservers/FLEXNotificationObserverSection.m`
- Create: `Classes/GlobalStateExplorers/NotificationObservers/FLEXNotificationObserversViewController.h`
- Create: `Classes/GlobalStateExplorers/NotificationObservers/FLEXNotificationObserversViewController.m`
- Modify: `Classes/GlobalStateExplorers/Globals/FLEXGlobalsEntry.h` (enum)
- Modify: `Classes/GlobalStateExplorers/Globals/FLEXGlobalsViewController.m` (4 switch arms + grid order + import)

- [ ] **Step 1: Add the enum case**

In `FLEXGlobalsEntry.h`, add `FLEXGlobalsRowNotificationObservers,` immediately after `FLEXGlobalsRowNotificationCenter,` (line 62) and before `FLEXGlobalsRowFileManager,`.

- [ ] **Step 2: Create the section**

`FLEXNotificationObserverSection.h`:
```objc
#import "FLEXTableViewSection.h"

NS_ASSUME_NONNULL_BEGIN

@interface FLEXNotificationObserverSection : FLEXTableViewSection
/// When YES, only registrations whose `isOurs` is YES are shown.
@property (nonatomic) BOOL appOnly;
@end

NS_ASSUME_NONNULL_END
```

`FLEXNotificationObserverSection.m`:
```objc
#import "FLEXNotificationObserverSection.h"
#import "FLEXNotificationRecorder.h"
#import "FLEXNotificationRegistration.h"
#import "FLEXObjectExplorerFactory.h"
#import "FLEXNotificationObserverDetailViewController.h"
#import "FLEXTableView.h"
#import "FLEXColor.h"

@interface FLEXNotificationObserverSection ()
@property (nonatomic, copy) NSArray<FLEXNotificationRegistration *> *rows;
@end

@implementation FLEXNotificationObserverSection

- (void)setAppOnly:(BOOL)appOnly {
    _appOnly = appOnly;
    [self reloadData];
}

- (void)reloadData {
    NSArray<FLEXNotificationRegistration *> *all = FLEXNotificationRecorder.sharedRecorder.registrations;
    NSString *filter = self.filterText;
    NSMutableArray<FLEXNotificationRegistration *> *result = [NSMutableArray array];
    for (FLEXNotificationRegistration *r in all) {
        if (self.appOnly && !r.isOurs) continue;
        if (filter.length) {
            NSString *haystack = [NSString stringWithFormat:@"%@ %@ %@",
                r.observerClassName, r.notificationName ?: @"", r.selectorString];
            if (![haystack localizedCaseInsensitiveContainsString:filter]) continue;
        }
        [result addObject:r];
    }
    self.rows = result;
}

- (void)setFilterText:(NSString *)filterText {
    super.filterText = filterText;
    [self reloadData];
}

- (NSString *)title { return @"Observers"; }
- (NSInteger)numberOfRows { return self.rows.count; }
- (NSString *)reuseIdentifierForRow:(NSInteger)row { return kFLEXDetailCell; }
- (BOOL)canSelectRow:(NSInteger)row { return YES; }

- (void)configureCell:(__kindof UITableViewCell *)cell forRow:(NSInteger)row {
    FLEXNotificationRegistration *r = self.rows[row];
    NSString *name = r.notificationName ?: @"(any notification)";
    cell.textLabel.text = [NSString stringWithFormat:@"%@ — %@", r.observerClassName, name];

    NSString *stateText;
    switch (r.state) {
        case FLEXNotificationObserverStateAlive: stateText = @"alive"; break;
        case FLEXNotificationObserverStateDeallocated: stateText = @"⚠️ DEALLOCATED"; break;
        case FLEXNotificationObserverStateUnknown: stateText = @"state unknown"; break;
    }
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ · %@", r.selectorString, stateText];
    cell.detailTextLabel.textColor = (r.state == FLEXNotificationObserverStateDeallocated)
        ? UIColor.systemRedColor : FLEXColor.deemphasizedTextColor;
}

- (UIViewController *)viewControllerToPushForRow:(NSInteger)row {
    FLEXNotificationRegistration *r = self.rows[row];
    if (r.state == FLEXNotificationObserverStateAlive && r.observer) {
        return [FLEXObjectExplorerFactory explorerViewControllerForObject:r.observer];
    }
    return [[FLEXNotificationObserverDetailViewController alloc] initWithRegistration:r];
}

- (NSString *)titleForRow:(NSInteger)row {
    return self.rows[row].observerClassName;
}

@end
```

> Verify during build: `FLEXColor.deemphasizedTextColor` — if that selector name differs in this codebase, substitute the correct `FLEXColor` secondary-text accessor (grep `Classes/Utility/FLEXColor.h`).

- [ ] **Step 3: Create the view controller**

`FLEXNotificationObserversViewController.h`:
```objc
#import "FLEXFilteringTableViewController.h"
#import "FLEXGlobalsEntry.h"

NS_ASSUME_NONNULL_BEGIN

@interface FLEXNotificationObserversViewController : FLEXFilteringTableViewController <FLEXGlobalsEntry>
@end

NS_ASSUME_NONNULL_END
```

`FLEXNotificationObserversViewController.m`:
```objc
#import "FLEXNotificationObserversViewController.h"
#import "FLEXNotificationObserverSection.h"
#import "FLEXNotificationMonitor.h"
#import "FLEXNotificationRecorder.h"

@interface FLEXNotificationObserversViewController ()
@property (nonatomic) FLEXNotificationObserverSection *observerSection;
@end

@implementation FLEXNotificationObserversViewController

#pragma mark - FLEXGlobalsEntry

+ (NSString *)globalsEntryTitle:(FLEXGlobalsRow)row {
    return @"Notification Observers";
}

+ (UIViewController *)globalsEntryViewController:(FLEXGlobalsRow)row {
    return [self new];
}

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = [self.class globalsEntryTitle:FLEXGlobalsRowNotificationObservers];
    self.showsSearchBar = YES;

    // Scope: App-only (default) vs All
    self.searchController.searchBar.scopeButtonTitles = @[@"App", @"All"];
    self.observerSection.appOnly = YES;

    self.navigationItem.rightBarButtonItems = @[
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash
            target:self action:@selector(clearTapped)],
        [[UIBarButtonItem alloc] initWithTitle:(FLEXNotificationMonitor.enabled ? @"On" : @"Off")
            style:UIBarButtonItemStylePlain target:self action:@selector(toggleTapped:)],
    ];

    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(recorderUpdated)
        name:kFLEXNotificationRecorderUpdatedNotification object:nil];

    [self showEnablePromptIfNeeded];
}

- (NSArray<FLEXTableViewSection *> *)makeSections {
    self.observerSection = [FLEXNotificationObserverSection new];
    self.observerSection.appOnly = YES;
    return @[self.observerSection];
}

#pragma mark - Actions

- (void)recorderUpdated {
    [self reloadData];
}

- (void)clearTapped {
    [FLEXNotificationRecorder.sharedRecorder clear];
    [self reloadData];
}

- (void)toggleTapped:(UIBarButtonItem *)sender {
    BOOL nowOn = !FLEXNotificationMonitor.enabled;
    FLEXNotificationMonitor.enabled = nowOn;
    sender.title = nowOn ? @"On" : @"Off";
    [self showEnablePromptIfNeeded];
}

- (void)showEnablePromptIfNeeded {
    if (!FLEXNotificationMonitor.enabled) {
        self.title = @"Notification Observers (off)";
    } else {
        self.title = [self.class globalsEntryTitle:FLEXGlobalsRowNotificationObservers];
    }
}

#pragma mark - Search scope

- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)scope {
    self.observerSection.appOnly = (scope == 0);
    [self reloadData];
    [super searchBar:searchBar selectedScopeButtonIndexDidChange:scope];
}

@end
```

> Verify during build: that `FLEXFilteringTableViewController` exposes `searchController` and the `searchBar:selectedScopeButtonIndexDidChange:` hook. If the scope-change override signature differs, grep `Classes/Core/Controllers/FLEXTableViewController.h` for the search delegate method and match it. The `appOnly` default is set in both `makeSections` and `viewDidLoad` so behavior is correct regardless of call order.

- [ ] **Step 4: Wire the globals menu**

In `FLEXGlobalsViewController.m`:
1. Add import near the other globals imports (~line 48): `#import "FLEXNotificationObserversViewController.h"`
2. In `globalsEntryForRow:` switch, add:
   ```objc
   case FLEXGlobalsRowNotificationObservers:
       entry = [FLEXNotificationObserversViewController flex_concreteGlobalsEntry:row]; break;
   ```
3. In `colorForRow:` switch, add:
   ```objc
   case FLEXGlobalsRowNotificationObservers:     return UIColor.systemIndigoColor;
   ```
4. In `symbolNameForRow:` switch, add:
   ```objc
   case FLEXGlobalsRowNotificationObservers:     return @"bell.badge";
   ```
5. In the grid-order array (~line 253), add after the `FLEXGlobalsRowNotificationCenter` line:
   ```objc
   [self globalsEntryForRow:FLEXGlobalsRowNotificationObservers],
   ```

- [ ] **Step 5: Add files to the FLEX target**

Add the four new `.m`/`.h` files to the **FLEX** target. (`FLEXNotificationObserverDetailViewController` is referenced by the section but created in Task 5 — to keep this task buildable, create a minimal stub now: a header declaring `- (instancetype)initWithRegistration:(FLEXNotificationRegistration *)registration;` and an empty `.m` returning `[super init]`-backed instance. Task 5 fleshes it out.)

Minimal stub `FLEXNotificationObserverDetailViewController.h`:
```objc
#import "FLEXTableViewController.h"
@class FLEXNotificationRegistration;
NS_ASSUME_NONNULL_BEGIN
@interface FLEXNotificationObserverDetailViewController : FLEXTableViewController
- (instancetype)initWithRegistration:(FLEXNotificationRegistration *)registration;
@end
NS_ASSUME_NONNULL_END
```
Minimal stub `FLEXNotificationObserverDetailViewController.m`:
```objc
#import "FLEXNotificationObserverDetailViewController.h"
#import "FLEXNotificationRegistration.h"
@implementation FLEXNotificationObserverDetailViewController {
    FLEXNotificationRegistration *_registration;
}
- (instancetype)initWithRegistration:(FLEXNotificationRegistration *)registration {
    self = [super init];
    if (self) { _registration = registration; self.title = registration.observerClassName; }
    return self;
}
@end
```
Add both stub files to the **FLEX** target too.

- [ ] **Step 6: Build**

Run:
```bash
xcodebuild build -project FLEX.xcodeproj -scheme FLEX \
  -destination 'generic/platform=iOS Simulator' -configuration Debug 2>&1 | tail -15
```
Expected: `** BUILD SUCCEEDED **`. Fix any membership / selector-name mismatches flagged.

- [ ] **Step 7: Commit**

```bash
git add Classes/GlobalStateExplorers/NotificationObservers/ \
        Classes/GlobalStateExplorers/Globals/FLEXGlobalsEntry.h \
        Classes/GlobalStateExplorers/Globals/FLEXGlobalsViewController.m \
        FLEX.xcodeproj/project.pbxproj
git commit -m "Add notification observers viewer and globals menu entry"
```

---

## Task 5: Dead-observer detail screen with lazy symbolication

**Files:**
- Modify: `Classes/GlobalStateExplorers/NotificationObservers/FLEXNotificationObserverDetailViewController.h`
- Modify: `Classes/GlobalStateExplorers/NotificationObservers/FLEXNotificationObserverDetailViewController.m`

- [ ] **Step 1: Replace the stub implementation**

`FLEXNotificationObserverDetailViewController.m`:
```objc
#import "FLEXNotificationObserverDetailViewController.h"
#import "FLEXNotificationRegistration.h"
#import "FLEXMutableListSection.h"
#import "FLEXTableView.h"

@implementation FLEXNotificationObserverDetailViewController {
    FLEXNotificationRegistration *_registration;
}

- (instancetype)initWithRegistration:(FLEXNotificationRegistration *)registration {
    self = [super init];
    if (self) {
        _registration = registration;
        self.title = registration.observerClassName;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self reloadData];
}

- (NSArray<FLEXTableViewSection *> *)makeSections {
    FLEXNotificationRegistration *r = _registration;

    NSString *stateText;
    switch (r.state) {
        case FLEXNotificationObserverStateAlive: stateText = @"Alive"; break;
        case FLEXNotificationObserverStateDeallocated: stateText = @"Deallocated (still registered)"; break;
        case FLEXNotificationObserverStateUnknown: stateText = @"Unknown (no weak support)"; break;
    }

    NSArray<NSString *> *fields = @[
        [NSString stringWithFormat:@"Observer:  %@ (0x%016lx)", r.observerClassName, (unsigned long)r.observerPointer],
        [NSString stringWithFormat:@"Notification:  %@", r.notificationName ?: @"(any)"],
        [NSString stringWithFormat:@"Selector:  %@", r.selectorString],
        [NSString stringWithFormat:@"Object:  %@", r.observedObjectClassName ?: @"(any)"],
        [NSString stringWithFormat:@"State:  %@", stateText],
        [NSString stringWithFormat:@"From app code:  %@", r.isOurs ? @"Yes" : @"No"],
        [NSString stringWithFormat:@"Registered:  %@", r.registeredAt],
    ];

    FLEXMutableListSection<NSString *> *info = [FLEXMutableListSection
        list:fields cellConfiguration:^(__kindof UITableViewCell *cell, NSString *text, NSInteger row) {
            cell.textLabel.text = text;
            cell.textLabel.numberOfLines = 0;
        } filterMatcher:nil];
    info.customTitle = @"Registration";

    FLEXMutableListSection<NSString *> *trace = [FLEXMutableListSection
        list:r.symbolicatedBacktrace cellConfiguration:^(__kindof UITableViewCell *cell, NSString *frame, NSInteger row) {
            cell.textLabel.text = frame;
            cell.textLabel.font = [UIFont monospacedSystemFontOfSize:11 weight:UIFontWeightRegular];
            cell.textLabel.numberOfLines = 0;
        } filterMatcher:nil];
    trace.customTitle = @"Registration call site";

    return @[info, trace];
}

@end
```

> Verify during build: the exact `FLEXMutableListSection` factory signature (grep `Classes/Core/FLEXMutableListSection.h`). If it differs, match it; the intent is two static sections — a key/value field list and the monospaced backtrace. `customTitle` is the section title setter on that class.

- [ ] **Step 2: Build**

Run:
```bash
xcodebuild build -project FLEX.xcodeproj -scheme FLEX \
  -destination 'generic/platform=iOS Simulator' -configuration Debug 2>&1 | tail -15
```
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 3: Commit**

```bash
git add Classes/GlobalStateExplorers/NotificationObservers/FLEXNotificationObserverDetailViewController.*
git commit -m "Flesh out notification observer detail screen with backtrace"
```

---

## Task 6: Full verification, manual smoke, and docs

**Files:**
- Modify: `README.md` (optional feature mention)

- [ ] **Step 1: Run the full test suite**

Run:
```bash
xcodebuild test -project FLEX.xcodeproj -scheme FLEXTests \
  -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -25
```
Expected: `** TEST SUCCEEDED **`, including all three new test classes plus the pre-existing tests.

- [ ] **Step 2: Manual smoke test in the example app**

Build & run the `FLEXample` app (Example/FLEXample.xcodeproj or the example scheme). Then:
1. Open FLEX → globals menu → "Notification Observers". Confirm the off-state prompt appears.
2. Tap the On toggle. Navigate the app to register some observers.
3. Confirm rows appear, "App" scope hides system noise, "All" reveals it.
4. Tap an alive row → object explorer opens on the observer.
5. Force a leak (register a block observer capturing self, drop the owner without removeObserver) → confirm a ⚠️ DEALLOCATED row appears and tapping it shows the detail + backtrace.

Record the result of each step in your commit message or PR description.

- [ ] **Step 3: Optional — mention the feature in README**

Add a short bullet under the features list noting the Notification Observers tool. Keep it one line.

- [ ] **Step 4: Final commit**

```bash
git add -A
git commit -m "Verify notification observers feature end-to-end"
```

---

## Self-review notes (author)

- **Spec coverage:** model (Task 1), recorder (Task 2), swizzles + opt-in toggle (Task 3), bundle classification & scope filter (Task 1 `isOurs` + Task 4 section), backtrace lazy symbolication (Task 1 + Task 5), globals entry & viewer (Task 4), dead-observer detail (Task 5), tests (Tasks 1–3), manual UI verification (Task 6). All spec sections map to a task.
- **Naming consistency:** `FLEXNotificationRegistration`, `FLEXNotificationRecorder` (`sharedRecorder`, `registrations`, `addRegistration:`, `removeAllRegistrationsForObserverPointer:`, `removeRegistrationsForObserverPointer:name:objectPointer:`, `clear`), `FLEXNotificationMonitor` (`enabled`, `installIfEnabled`), `kFLEXNotificationRecorderUpdatedNotification` — used identically across tasks.
- **Known verification points (flagged inline, not placeholders):** exact `FLEXColor` secondary-text accessor, `FLEXMutableListSection` factory signature, the search-scope delegate hook signature, and the block-observer double-record guard. Each has a concrete grep target and fallback.
</content>
