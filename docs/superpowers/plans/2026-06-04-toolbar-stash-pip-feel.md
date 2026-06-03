# PiP-Feel Toolbar Stash Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the floating explorer toolbar's off-screen "stash" feel like iOS Picture-in-Picture — momentum flows into the tuck, the stash decision reads flick intent, and the tuck is catchable mid-flight.

**Architecture:** Keep the existing two-engine handoff — UIKit Dynamics for free wandering, a `UISpring` `UIViewPropertyAnimator` for the tuck. Three changes, all on the stash path: (1) seed the tuck/restore spring with the release velocity, (2) replace the raw fling-velocity cliff with a position-aware velocity *projection*, (3) store the tuck animator so a new touch can interrupt it. The two pure-math pieces (projection + edge decision, and spring-velocity normalization) move into a header-only unit and are unit-tested; the UIKit feel is verified manually.

**Tech Stack:** Objective-C, UIKit (`UIViewPropertyAnimator`, `UISpringTimingParameters`, UIKit Dynamics), XCTest. Build: `FLEX.xcodeproj` (schemes `FLEX`, `FLEXTests`; example app `Example/FLEXample.xcodeproj`, scheme `FLEXample`).

**Spec:** `docs/superpowers/specs/2026-06-04-toolbar-stash-pip-feel-design.md`

**Commit convention:** Plain messages, **no `Co-Authored-By` trailer** (user preference).

**Build/test destination:** `platform=iOS Simulator,name=iPhone 16e` (booted). If unavailable, pick another from `xcrun simctl list devices available`.

---

## File Structure

- **Create** `Classes/Toolbar/FLEXToolbarStashMath.h` — header-only `static inline` pure functions: `FLEXRelativeSpringVelocity(...)`, `FLEXStashEdgeForRelease(...)`. No UIKit state; depends only on CoreGraphics types + the `FLEXToolbarStashEdge` enum.
- **Create** `FLEXTests/FLEXToolbarStashMathTests.m` — XCTest coverage for the two pure functions.
- **Modify** `Classes/ExplorerInterface/FLEXExplorerViewController.m` — decision now calls the projection helper; tuck/restore go through one velocity-seeded spring helper; new `toolbarStashAnimator` property; pan `Began` interrupts an in-flight tuck.
- **Modify** `FLEX.xcodeproj/project.pbxproj` — via the `xcodeproj` gem, add the two new files to the right targets.
- **Unchanged:** `FLEXExplorerToolbar.*` (sliver / chevron / cross-fade visuals).

---

## Task 1: Scaffold the pure-math unit and its test, wired into the project

**Files:**
- Create: `Classes/Toolbar/FLEXToolbarStashMath.h`
- Create: `FLEXTests/FLEXToolbarStashMathTests.m`
- Modify: `FLEX.xcodeproj/project.pbxproj` (via script)

- [ ] **Step 1: Create the (function-less) math header**

`Classes/Toolbar/FLEXToolbarStashMath.h`:

```objc
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

// Functions are added in Tasks 2 and 3.
```

- [ ] **Step 2: Create the empty test case**

`FLEXTests/FLEXToolbarStashMathTests.m`:

```objc
//
//  FLEXToolbarStashMathTests.m
//  FLEXTests
//

#import <XCTest/XCTest.h>
#import "FLEXToolbarStashMath.h"

@interface FLEXToolbarStashMathTests : XCTestCase
@end

@implementation FLEXToolbarStashMathTests
@end
```

- [ ] **Step 3: Confirm the FLEX target name, then add both files to the project**

Run (lists targets so the script's `'FLEX'` lookup is correct — adjust if your framework target is named differently):

```bash
ruby -e "require 'xcodeproj'; Xcodeproj::Project.open('FLEX.xcodeproj').targets.each { |t| puts t.name }"
```

Then create `add_stash_math_files.rb` at the repo root:

```ruby
#!/usr/bin/env ruby
require 'xcodeproj'

proj = Xcodeproj::Project.open('FLEX.xcodeproj')

# Add a new file into the same group as an existing sibling (so the on-disk
# path resolves correctly regardless of how groups are laid out).
def group_of(proj, sibling_name)
  ref = proj.files.find { |f| f.display_name == sibling_name }
  raise "Could not find #{sibling_name} in project" unless ref
  ref.parent
end

# --- Header: same group as FLEXExplorerToolbar.h; project (private) visibility on FLEX ---
unless proj.files.any? { |f| f.display_name == 'FLEXToolbarStashMath.h' }
  hdr = group_of(proj, 'FLEXExplorerToolbar.h').new_file('FLEXToolbarStashMath.h')
  flex = proj.targets.find { |t| t.name == 'FLEX' }
  if flex
    bf = flex.headers_build_phase.add_file_reference(hdr, true)
    bf.settings = { 'ATTRIBUTES' => ['Project'] }
  end
end

# --- Test: same group as FLEXTests.m; compiled by the FLEXTests target ---
unless proj.files.any? { |f| f.display_name == 'FLEXToolbarStashMathTests.m' }
  tref = group_of(proj, 'FLEXTests.m').new_file('FLEXToolbarStashMathTests.m')
  tests = proj.targets.find { |t| t.name == 'FLEXTests' }
  raise 'FLEXTests target not found' unless tests
  tests.source_build_phase.add_file_reference(tref, true)
end

proj.save
puts 'OK: added FLEXToolbarStashMath.h + FLEXToolbarStashMathTests.m'
```

Run it:

```bash
ruby add_stash_math_files.rb
```

Expected: `OK: added FLEXToolbarStashMath.h + FLEXToolbarStashMathTests.m`

- [ ] **Step 4: Verify both files are referenced**

Run:

```bash
grep -c 'FLEXToolbarStashMath' FLEX.xcodeproj/project.pbxproj
```

Expected: a non-zero count (typically 4–6 — file references + build files).

- [ ] **Step 5: Build the test target to confirm it compiles and the class is discovered**

Run:

```bash
xcodebuild test -project FLEX.xcodeproj -scheme FLEXTests \
  -destination 'platform=iOS Simulator,name=iPhone 16e' \
  -only-testing:FLEXTests/FLEXToolbarStashMathTests 2>&1 | tail -25
```

Expected: `TEST SUCCEEDED` (zero tests run is success — the class compiles and is found). First build compiles the whole framework, so this is slow; later runs are faster.

- [ ] **Step 6: Commit**

```bash
rm add_stash_math_files.rb
git add Classes/Toolbar/FLEXToolbarStashMath.h FLEXTests/FLEXToolbarStashMathTests.m FLEX.xcodeproj/project.pbxproj
git commit -m "Scaffold FLEXToolbarStashMath unit and test target wiring"
```

---

## Task 2: `FLEXRelativeSpringVelocity` (TDD)

Normalizes a gesture velocity into a `UISpringTimingParameters` initial-velocity component: `velocity / distance`, with a zero-distance guard and a magnitude clamp.

**Files:**
- Modify: `FLEXTests/FLEXToolbarStashMathTests.m`
- Modify: `Classes/Toolbar/FLEXToolbarStashMath.h`

- [ ] **Step 1: Write the failing tests**

Insert these methods inside `@implementation FLEXToolbarStashMathTests` in `FLEXTests/FLEXToolbarStashMathTests.m`:

```objc
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
```

- [ ] **Step 2: Run the tests — expect a compile failure**

Run:

```bash
xcodebuild test -project FLEX.xcodeproj -scheme FLEXTests \
  -destination 'platform=iOS Simulator,name=iPhone 16e' \
  -only-testing:FLEXTests/FLEXToolbarStashMathTests 2>&1 | tail -25
```

Expected: build fails — `implicit declaration of function 'FLEXRelativeSpringVelocity'` (the function doesn't exist yet).

- [ ] **Step 3: Implement the function**

Add to `Classes/Toolbar/FLEXToolbarStashMath.h`, replacing the `// Functions are added...` comment:

```objc
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
```

- [ ] **Step 4: Run the tests — expect pass**

Run:

```bash
xcodebuild test -project FLEX.xcodeproj -scheme FLEXTests \
  -destination 'platform=iOS Simulator,name=iPhone 16e' \
  -only-testing:FLEXTests/FLEXToolbarStashMathTests 2>&1 | tail -25
```

Expected: `TEST SUCCEEDED`, 3 tests pass.

- [ ] **Step 5: Commit**

```bash
git add Classes/Toolbar/FLEXToolbarStashMath.h FLEXTests/FLEXToolbarStashMathTests.m
git commit -m "Add FLEXRelativeSpringVelocity with zero-distance guard and clamp"
```

---

## Task 3: `FLEXStashEdgeForRelease` (TDD)

Projects the horizontal flick and decides the stash edge (or none); a predominantly-vertical flick never stashes.

**Files:**
- Modify: `FLEXTests/FLEXToolbarStashMathTests.m`
- Modify: `Classes/Toolbar/FLEXToolbarStashMath.h`

- [ ] **Step 1: Write the failing tests**

Insert inside `@implementation FLEXToolbarStashMathTests` (geometry: 320-pt-wide bounds, `minX=0`, `maxX=320`, `band=44`, `deceleration=0.167`):

```objc
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
```

- [ ] **Step 2: Run the tests — expect a compile failure**

Run:

```bash
xcodebuild test -project FLEX.xcodeproj -scheme FLEXTests \
  -destination 'platform=iOS Simulator,name=iPhone 16e' \
  -only-testing:FLEXTests/FLEXToolbarStashMathTests 2>&1 | tail -25
```

Expected: build fails — `implicit declaration of function 'FLEXStashEdgeForRelease'`.

- [ ] **Step 3: Implement the function**

Append to `Classes/Toolbar/FLEXToolbarStashMath.h` (after `FLEXRelativeSpringVelocity`):

```objc
/// Decide which edge a pan release should stash against, PiP-style: project the
/// horizontal flick under a linear decay and stash if the projected center lands
/// within `band` of (or past) an edge. A predominantly-vertical flick never
/// stashes. All geometry is passed explicitly so this is unit-testable with no view.
///
/// @param velocity     release velocity (pt/s); x drives the stash, y is the vertical guard
/// @param centerX      toolbar center X at release
/// @param minX         left edge, e.g. CGRectGetMinX(safeArea)
/// @param maxX         right edge, e.g. CGRectGetMaxX(safeArea)
/// @param band         how close to an edge the projected center must land to stash (pt)
/// @param deceleration projected travel per (pt/s) of velocity: travel = velocity.x * deceleration
static inline FLEXToolbarStashEdge FLEXStashEdgeForRelease(CGPoint velocity,
                                                           CGFloat centerX,
                                                           CGFloat minX,
                                                           CGFloat maxX,
                                                           CGFloat band,
                                                           CGFloat deceleration) {
    if (fabs(velocity.x) < fabs(velocity.y)) {
        return FLEXToolbarStashEdgeNone;
    }
    CGFloat projectedCenterX = centerX + velocity.x * deceleration;
    if (projectedCenterX <= minX + band) {
        return FLEXToolbarStashEdgeLeft;
    }
    if (projectedCenterX >= maxX - band) {
        return FLEXToolbarStashEdgeRight;
    }
    return FLEXToolbarStashEdgeNone;
}
```

- [ ] **Step 4: Run the tests — expect pass**

Run:

```bash
xcodebuild test -project FLEX.xcodeproj -scheme FLEXTests \
  -destination 'platform=iOS Simulator,name=iPhone 16e' \
  -only-testing:FLEXTests/FLEXToolbarStashMathTests 2>&1 | tail -25
```

Expected: `TEST SUCCEEDED`, 8 tests pass.

- [ ] **Step 5: Commit**

```bash
git add Classes/Toolbar/FLEXToolbarStashMath.h FLEXTests/FLEXToolbarStashMathTests.m
git commit -m "Add FLEXStashEdgeForRelease projection-based stash decision"
```

---

## Task 4: Use the projection helper for the stash decision

Replace the raw fling-velocity cliff + 15% edge zone with the projected-landing test. Introduce the three tunable constants.

**Files:**
- Modify: `Classes/ExplorerInterface/FLEXExplorerViewController.m`

- [ ] **Step 1: Import the math header**

Near the other `#import` lines at the top of `Classes/ExplorerInterface/FLEXExplorerViewController.m`, add:

```objc
#import "FLEXToolbarStashMath.h"
```

- [ ] **Step 2: Replace the stash constants**

Find:

```objc
/// Horizontal fling speed (pt/s) past which a release stashes the toolbar against that edge.
static const CGFloat kToolbarStashFlingVelocity = 800.0;
/// Fraction of the safe-area width near each edge within which a slow release still stashes.
static const CGFloat kToolbarStashEdgeZoneFraction = 0.15;
```

Replace with:

```objc
/// Projected travel per (pt/s) of release velocity, matching the free-float
/// UIDynamics decay (~ 1/resistance, resistance = 6.0). Tuned by feel in Task 8.
static const CGFloat kToolbarStashProjectionDeceleration = 1.0 / 6.0;
/// How close to an edge the projected center must land to commit to a stash (pt). Tuned.
static const CGFloat kToolbarStashEdgeBand = 44.0;
/// Clamp on the tuck spring's normalized initial velocity, so a tiny tuck distance
/// with a fast flick can't explode the spring. Tuned.
static const CGFloat kToolbarStashMaxRelativeVelocity = 30.0;
```

- [ ] **Step 3: Rewrite the decision method to call the helper**

Find the whole body of `- (FLEXToolbarStashEdge)stashEdgeForReleaseWithVelocity:(CGPoint)velocity` and replace it with:

```objc
- (FLEXToolbarStashEdge)stashEdgeForReleaseWithVelocity:(CGPoint)velocity {
    const CGRect safeArea = [self viewSafeArea];
    return FLEXStashEdgeForRelease(
        velocity,
        CGRectGetMidX(self.explorerToolbar.frame),
        CGRectGetMinX(safeArea),
        CGRectGetMaxX(safeArea),
        kToolbarStashEdgeBand,
        kToolbarStashProjectionDeceleration
    );
}
```

- [ ] **Step 4: Build the framework to verify it compiles**

Run:

```bash
xcodebuild -project FLEX.xcodeproj -scheme FLEX \
  -destination 'platform=iOS Simulator,name=iPhone 16e' build 2>&1 | tail -15
```

Expected: `BUILD SUCCEEDED`. (If the compiler reports `kToolbarStashFlingVelocity`/`kToolbarStashEdgeZoneFraction` still referenced, search the file and remove the stragglers — they should have no other uses.)

- [ ] **Step 5: Commit**

```bash
git add Classes/ExplorerInterface/FLEXExplorerViewController.m
git commit -m "Decide toolbar stash by projecting the flick instead of a velocity cliff"
```

---

## Task 5: Velocity continuity — seed the tuck spring from the release velocity

Add the stored animator property and one shared velocity-seeded spring helper, and route stashing through it.

**Files:**
- Modify: `Classes/ExplorerInterface/FLEXExplorerViewController.m`

- [ ] **Step 1: Add the animator property**

In the class extension at the top of `FLEXExplorerViewController.m` (near `@property (nonatomic) UIDynamicAnimator *toolbarAnimator;`), add:

```objc
/// The in-flight stash/restore spring, retained so a new touch can interrupt it.
@property (nonatomic, nullable) UIViewPropertyAnimator *toolbarStashAnimator;
```

- [ ] **Step 2: Add the shared spring helper**

Add this method next to `stashToolbarToEdge:` (in the `#pragma mark - Toolbar Stashing` section):

```objc
/// Springs the toolbar to `target`, seeding the spring's initial velocity from
/// the release velocity (PiP-style continuity). Retains the animator so a new
/// touch can interrupt it, and clears + persists on completion.
- (void)animateToolbarToFrame:(CGRect)target withVelocity:(CGPoint)velocity {
    const CGFloat dx = target.origin.x - self.explorerToolbar.frame.origin.x;
    const CGFloat relVx = FLEXRelativeSpringVelocity(velocity.x, dx, kToolbarStashMaxRelativeVelocity);

    UISpringTimingParameters *spring = [[UISpringTimingParameters alloc]
        initWithDampingRatio:0.8 initialVelocity:CGVectorMake(relVx, 0.0)
    ];
    UIViewPropertyAnimator *animator = [[UIViewPropertyAnimator alloc]
        initWithDuration:0.5 timingParameters:spring
    ];
    [animator addAnimations:^{
        self.explorerToolbar.frame = target;
    }];

    __weak typeof(self) weakSelf = self;
    [animator addCompletion:^(UIViewAnimatingPosition finalPosition) {
        weakSelf.toolbarStashAnimator = nil;
        [weakSelf persistToolbarPosition];
    }];

    self.toolbarStashAnimator = animator;
    [animator startAnimation];
}
```

- [ ] **Step 3: Route `stashToolbarToEdge:` through the helper and take the velocity**

Replace the whole body of `- (void)stashToolbarToEdge:(FLEXToolbarStashEdge)edge` with the new signature + body:

```objc
- (void)stashToolbarToEdge:(FLEXToolbarStashEdge)edge withVelocity:(CGPoint)velocity {
    [self.toolbarAnimator removeAllBehaviors];

    const CGRect target = [self stashedToolbarFrameForEdge:edge fromFrame:self.explorerToolbar.frame];

    self.toolbarStashEdge = edge;
    [self.explorerToolbar setStashEdge:edge animated:YES];

    [self animateToolbarToFrame:target withVelocity:velocity];
    [self persistToolbarPosition];
}
```

- [ ] **Step 4: Update the call site in the pan handler**

In `handleToolbarPanGesture:`, in the `UIGestureRecognizerStateEnded` / `Cancelled` case, find:

```objc
            if (edge != FLEXToolbarStashEdgeNone) {
                [self stashToolbarToEdge:edge];
            } else {
```

Replace with:

```objc
            if (edge != FLEXToolbarStashEdgeNone) {
                [self stashToolbarToEdge:edge withVelocity:velocity];
            } else {
```

- [ ] **Step 5: Build to verify it compiles**

Run:

```bash
xcodebuild -project FLEX.xcodeproj -scheme FLEX \
  -destination 'platform=iOS Simulator,name=iPhone 16e' build 2>&1 | tail -15
```

Expected: `BUILD SUCCEEDED`.

- [ ] **Step 6: Commit**

```bash
git add Classes/ExplorerInterface/FLEXExplorerViewController.m
git commit -m "Carry release velocity into the toolbar stash spring"
```

---

## Task 6: Route restore through the same spring helper

**Files:**
- Modify: `Classes/ExplorerInterface/FLEXExplorerViewController.m`

- [ ] **Step 1: Replace the restore animation with the helper**

In `- (void)restoreStashedToolbarAnimated:(BOOL)animated`, find the animated/non-animated tail that builds its own `UIViewPropertyAnimator`:

```objc
    if (animated) {
        UIViewPropertyAnimator *animator = [[UIViewPropertyAnimator alloc]
            initWithDuration:0.4 dampingRatio:0.8 animations:^{
                self.explorerToolbar.frame = target;
            }
        ];
        [animator addCompletion:^(UIViewAnimatingPosition finalPosition) {
            [self persistToolbarPosition];
        }];
        [animator startAnimation];
    } else {
        self.explorerToolbar.frame = target;
    }

    [self persistToolbarPosition];
```

Replace with (tap-restore has no gesture momentum → zero velocity; the helper persists on completion, so only the non-animated branch persists inline):

```objc
    if (animated) {
        [self animateToolbarToFrame:target withVelocity:CGPointZero];
    } else {
        self.explorerToolbar.frame = target;
        [self persistToolbarPosition];
    }
```

- [ ] **Step 2: Build to verify it compiles**

Run:

```bash
xcodebuild -project FLEX.xcodeproj -scheme FLEX \
  -destination 'platform=iOS Simulator,name=iPhone 16e' build 2>&1 | tail -15
```

Expected: `BUILD SUCCEEDED`.

- [ ] **Step 3: Commit**

```bash
git add Classes/ExplorerInterface/FLEXExplorerViewController.m
git commit -m "Restore the stashed toolbar through the shared spring helper"
```

---

## Task 7: Interruptibility — catch an in-flight tuck on a new touch

**Files:**
- Modify: `Classes/ExplorerInterface/FLEXExplorerViewController.m`

- [ ] **Step 1: Stop the stash animator at the start of a pan**

In `handleToolbarPanGesture:`, in the `UIGestureRecognizerStateBegan` case, find:

```objc
        case UIGestureRecognizerStateBegan: {
            [self.toolbarAnimator removeAllBehaviors];
```

Replace with (stop first, so `self.explorerToolbar` is left at its interrupted frame before we read its center for the drag offset):

```objc
        case UIGestureRecognizerStateBegan: {
            // Catch an in-flight stash/restore tuck so the drag continues from
            // wherever it had reached, instead of fighting the running spring.
            if (self.toolbarStashAnimator.isRunning) {
                [self.toolbarStashAnimator stopAnimation:YES]; // leaves the pill at its current frame
                self.toolbarStashAnimator = nil;
            }
            [self.toolbarAnimator removeAllBehaviors];
```

Note: `stopAnimation:YES` does **not** call the animator's completion block, which is why we clear the reference here.

- [ ] **Step 2: Build to verify it compiles**

Run:

```bash
xcodebuild -project FLEX.xcodeproj -scheme FLEX \
  -destination 'platform=iOS Simulator,name=iPhone 16e' build 2>&1 | tail -15
```

Expected: `BUILD SUCCEEDED`.

- [ ] **Step 3: Re-run the unit tests (guard against regressions in the math unit)**

Run:

```bash
xcodebuild test -project FLEX.xcodeproj -scheme FLEXTests \
  -destination 'platform=iOS Simulator,name=iPhone 16e' \
  -only-testing:FLEXTests/FLEXToolbarStashMathTests 2>&1 | tail -25
```

Expected: `TEST SUCCEEDED`, 8 tests pass.

- [ ] **Step 4: Commit**

```bash
git add Classes/ExplorerInterface/FLEXExplorerViewController.m
git commit -m "Make the toolbar stash tuck interruptible mid-flight"
```

---

## Task 8: Manual feel verification and tuning (user checkpoint)

The math is unit-tested; the *feel* is judged by hand against system PiP. This task is a review checkpoint, not an automated gate.

**Files:**
- Possibly modify constants in `Classes/ExplorerInterface/FLEXExplorerViewController.m` (Task 4) — `kToolbarStashProjectionDeceleration`, `kToolbarStashEdgeBand`, `kToolbarStashMaxRelativeVelocity`, and the `0.8` damping in `animateToolbarToFrame:withVelocity:`.

- [ ] **Step 1: Build and launch the example app**

Run:

```bash
xcodebuild -project Example/FLEXample.xcodeproj -scheme FLEXample \
  -destination 'platform=iOS Simulator,name=iPhone 16e' build 2>&1 | tail -15
```

Expected: `BUILD SUCCEEDED`. Then launch it in the booted simulator (open the built app, or run the `FLEXample` scheme from Xcode) and bring up the FLEX toolbar.

- [ ] **Step 2: Walk the feel matrix (user judges each against PiP)**

- Soft vs. hard horizontal flick from **center** → soft free-floats/bounces; hard tucks, and the tuck **continues the flick's momentum** (no stop-and-restart).
- Flick from **near each edge** → a gentle flick toward the near edge stashes (position-aware projection).
- Flick toward each **side** (left and right) → stashes to the correct edge.
- **Grab the pill mid-tuck** → it's caught instantly and follows the finger from where it was (no fight, no jump).
- **Drag the sliver out and re-flick** back toward the edge → re-stashes with momentum.
- **Rotate** the device while stashed → the sliver stays correctly tucked against its edge.
- **Tap** the sliver → restores with a gentle spring (no momentum needed).
- Predominantly **vertical** flick near an edge → does **not** stash (free-floats).

- [ ] **Step 3: Tune to taste**

- Stashes too eagerly / too reluctantly → adjust `kToolbarStashProjectionDeceleration` (higher = a given flick projects farther = stashes more easily) and/or `kToolbarStashEdgeBand`.
- Tuck overshoots or feels loose/stiff → adjust the `0.8` damping ratio in `animateToolbarToFrame:withVelocity:`; for an un-flicked tuck that must match the old 0.4 s settle exactly, switch that spring to `initWithMass:stiffness:damping:initialVelocity:`.
- A fast flick over a tiny tuck distance snaps too hard → lower `kToolbarStashMaxRelativeVelocity`.
- If grabbing mid-tuck shows a positional jump, switch `animateToolbarToFrame:` to animate `self.explorerToolbar.center` (deriving the target center from `target`) instead of `frame` — `UIViewPropertyAnimator` interrupts `center` more cleanly.

- [ ] **Step 4: Commit any tuning**

```bash
git add Classes/ExplorerInterface/FLEXExplorerViewController.m
git commit -m "Tune toolbar stash feel"
```

---

## Self-Review

- **Spec coverage:** velocity continuity → Tasks 5–6; velocity projection → Tasks 3–4; interruptibility → Task 7; pure-function unit tests → Tasks 2–3; manual feel matrix → Task 8. Edge cases from the spec (rotation re-resolves via the existing `viewSafeAreaInsetsDidChange` path; persist-while-stashed is benign) need no code and are exercised in Task 8. Non-goals (drag-past-edge-to-stash, vertical tuck momentum) are excluded. Open items map to Task 8 tuning + the `mass:stiffness:damping:` note.
- **Type consistency:** `FLEXStashEdgeForRelease` / `FLEXRelativeSpringVelocity` signatures match between header (Tasks 2–3) and call sites (Tasks 4–5); `animateToolbarToFrame:withVelocity:`, `stashToolbarToEdge:withVelocity:`, and the `toolbarStashAnimator` property are used consistently across Tasks 5–7.
- **No placeholders:** every step has concrete code/commands; the only "to taste" values are the tuning constants, which ship with working defaults and are adjusted in Task 8.
