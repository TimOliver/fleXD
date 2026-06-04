# Toolbar Stash — Picture-in-Picture Feel

- **Date:** 2026-06-04
- **Branch:** `hide-panel`
- **Status:** Approved design — ready for implementation plan
- **Goal:** Make the floating explorer toolbar's off-screen "stash" *feel* like iOS Picture-in-Picture, **without** PiP's corner-anchoring.

## Problem

FLEXD's floating explorer toolbar (`FLEXExplorerToolbar`) can be dragged and flicked; flicks are simulated with UIKit Dynamics (momentum + wall collisions) so it bounces and decelerates realistically. A foundation already exists for "stashing" the toolbar off-screen against the left/right edge, PiP-style — a 25 pt sliver with an inward chevron, restored by tapping or dragging the sliver.

The stash *works* but doesn't *feel* like PiP. This spec closes that gap. The difficulty is purely **feel/fidelity** (confirmed with the user), not behaviour or architecture.

## How PiP actually behaves (reference)

PiP is not a physics simulation; it is a two-phase gesture:

1. **Tracking** — the panel follows the finger 1:1 (rubber-band resistance past bounds).
2. **Release** — iOS *projects* the release velocity to a landing point, picks a target, and runs a **single spring** to it whose **initial velocity is seeded from the gesture**, so the finger's momentum flows straight into the animation.

Hide-off-screen: when the projected landing crosses the edge, the panel tucks off-screen leaving a peek handle; tap/drag restores it with the same velocity-continuous spring; the animation is interruptible mid-flight. We adopt all of this **except** corner-anchoring.

## Current implementation (`FLEXExplorerViewController.m`)

- `handleToolbarPanGesture:` (581) — `Began` tears down Dynamics (586) and clears any stash; `Changed` (605) tracks the finger (hard-clamped on-screen by `constrainedToolbarFrame:`); `Ended` (610) picks stash-or-free-float.
- `stashEdgeForReleaseWithVelocity:` — decides via a raw `|v.x| ≥ 800` cliff (`kToolbarStashFlingVelocity`) **or** a 15% edge zone (`kToolbarStashEdgeZoneFraction`).
- `stashToolbarToEdge:` — tears down Dynamics, animates to the stashed frame with a **fixed-duration, velocity-less** `UIViewPropertyAnimator` (0.4 s / damping 0.8). The animator is a **local variable** (cannot be interrupted).
- `restoreStashedToolbarAnimated:` — same fixed spring back to the edge.
- `applyToolbarMomentumWithVelocity:` (671) — free-float: `UIDynamicItemBehavior` with the **gesture velocity injected** (`addLinearVelocity:`, 678), `resistance 6.0`, `elasticity 0.3`, plus a `UICollisionBehavior` walling the safe area.
- `viewSafeArea` (1173) — only the **top** inset is applied; horizontally the "safe area" spans full `view.bounds`, so stashes hug the true screen edges.
- `constrainedToolbarFrame:` (716) — clamps on-screen when un-stashed; **bypasses the clamp and re-resolves `stashedOriginXForEdge:` when stashed**.

### Core insight

The free-float path **already has velocity continuity** — it injects the gesture velocity into Dynamics. Only the stash path throws it away (fresh velocity-less spring). So the *same flick* feels alive when it free-floats and dead when it stashes. **That discontinuity is the "not-PiP" feeling.**

## Decision: keep the two-engine handoff

Keep **UIKit Dynamics for free wandering** and a **`UISpring` property-animator for the tuck** — use each engine for what it's best at. Rationale: preserves the wall-bounce we want, smallest/lowest-risk change, and matches how PiP is actually built (spring timing, not Dynamics).

Alternatives rejected: *unify on Dynamics* (less precise landing at the sliver, further from real PiP); *re-base everything on the spring model* (loses the multi-wall bounce the user likes).

### Unifying principle

> Every pan release = **project the flick → pick a target → spring there carrying the release velocity.** Free-float and stash are two targets of one model.

## Design

### Fix 1 — Velocity continuity (headline)

`stashToolbarToEdge:` gains the release velocity and uses a velocity-seeded spring. The tuck is horizontal (Y frozen at release), so only `velocity.x` feeds it, normalized to travel distance:

```objc
- (void)stashToolbarToEdge:(FLEXToolbarStashEdge)edge withVelocity:(CGPoint)velocity;

CGFloat dx = target.origin.x - current.origin.x;
CGFloat relVx = fabs(dx) > 0.5 ? velocity.x / dx : 0;       // guard zero-distance; clamp to a sane range
UISpringTimingParameters *spring = [UISpringTimingParameters.alloc
    initWithDampingRatio:0.8 initialVelocity:CGVectorMake(relVx, 0)];
self.toolbarStashAnimator = [UIViewPropertyAnimator.alloc
    initWithDuration:0.5 timingParameters:spring];          // settle time set by the spring physics
```

- Tap-restore has no gesture velocity → routes through the same helper with `relVx = 0` (identical feel, one path).
- If we need to pin the un-flicked settle time to the current 0.4 s, switch to `initWithMass:stiffness:damping:initialVelocity:` for full control.
- `Ended` passes the release velocity into the stash branch.

### Fix 2 — Velocity projection (decision)

Replace the `|v.x| ≥ 800` cliff with a projected-landing test using the **same decay the free-float exhibits**, so the rule is "stash iff this flick would otherwise coast into the wall":

```objc
CGFloat projectedCenterX = centerX + [self projectedTravelForVelocity:velocity.x];
if (projectedCenterX <= CGRectGetMinX(safeArea) + band) return Left;
if (projectedCenterX >= CGRectGetMaxX(safeArea) - band) return Right;
return None;
```

- `projectedTravelForVelocity:` starts from the free-float's linear decay (`travel ≈ v / resistance`, `resistance = 6.0`) and is tuned by feel.
- **Unifies** the two current conditions (fling threshold + edge zone) into one position-aware test — a flick near the edge needs less speed, from center needs more, like PiP.
- The 15% edge-zone branch appears **effectively dead today** (the on-screen drag clamp keeps the pill's center too far from any edge to satisfy it at a normal pill width) — folding it in costs nothing. Confirm against the real pill width during implementation.
- Keep a "predominantly vertical → no stash" guard (cheap; makes intent explicit).
- `kToolbarStashFlingVelocity` and `kToolbarStashEdgeZoneFraction` are removed/replaced by a projection deceleration constant + `band`.

### Fix 3 — Interruptibility

Store the tuck animator so a touch can catch it mid-flight:

```objc
@property (nonatomic) UIViewPropertyAnimator *toolbarStashAnimator;
```

In `handleToolbarPanGesture:` `Began`, **before** `removeAllBehaviors` (586): if `toolbarStashAnimator.isRunning`, call `[self.toolbarStashAnimator stopAnimation:YES]` — this leaves the pill at its current frame, and the drag continues seamlessly from there (PiP's "catch it in flight"). The same guard catches a restore mid-flight. Clear the reference on completion.

## Edge cases

- **Mid-tuck grab** → Fix 3.
- **Rotation / safe-area change while stashed** → already handled: `viewSafeAreaInsetsDidChange` (1179) → `updateToolbarPositionWithUnconstrainedFrame:` → `constrainedToolbarFrame:`, whose stashed branch re-resolves `stashedOriginXForEdge:` for the new geometry. *Pre-existing gap:* a pure size change that doesn't change insets (iPad multitasking) won't re-resolve — out of scope.
- **Drag-out release** routes through `Ended` → inherits projection + continuity for free.
- **Low/zero-velocity release** → projects ≈ current center → no stash. Matches today.
- **Persist-while-stashed (launch):** benign. Left-stash persists a negative X → launch re-centers (155); right-stash persists a positive X → launch clamps to the right edge (un-stashed). Worst case: launches edge-hugging, never off-screen. *(Optional cleanup, out of scope: persist the pre-stash position instead of the stashed frame.)*

## Non-goals (YAGNI)

- _(Originally listed **drag-past-the-edge-to-stash** and **vertical tuck momentum** here. Both were **promoted to goals in Revision 2** below after feel-testing.)_

## Revision 2 — PiP-fidelity additions (2026-06-04, after feel-testing)

Feel-testing the first cut showed three more PiP behaviors are needed. Two were the non-goals above, now in scope:

1. **Flick parallel to a side edge → bounce, not stash.** Already provided by the existing `|vx| < |vy|` vertical guard — a flick parallel to a side edge is mostly vertical, so it falls through to the free-float, which bounces off the collision wall. Verify on re-test; nudge the threshold only if a parallel flick wrongly stashes.

2. **Aggressive-angle flick → stash _while gliding along Y_.** Make the stash **2-D**: the tuck's target Y comes from the flick's projected vertical travel (clamped so the peek stays fully on-screen), and the spring carries the Y velocity too. The same `|vx| > |vy|` flick that already stashes now glides vertically as it tucks. (Reverses the old "Y frozen at release" non-goal.)

3. **Drag past the edge to stash, with a >50% affordance.** During a drag, stop hard-clamping at the side edge so the pill **follows the finger off-screen with no rubber-band** — rubber-banding signals "past the absolute limit / rejected," but here crossing the edge is the _valid_ gesture, so the drag must feel free and inviting. Track the obscured fraction; once **>50%** past an edge, cross-fade the toolbar content out and the chevron in (the existing stash affordance) to signal "release to stash." Release while >50% → commit the stash (carrying release velocity); release under 50% (or drag back) → spring back on-screen. Combined on-release decision: _dragged >50% past_ → stash · else _flick projects past_ (②) → stash-with-glide · else free-float.

Implemented as **Task 9** (2-D glide stash) and **Task 10** (drag-to-stash) — same header-only pure helpers + unit tests for the math, manual feel for the UIKit.

## Testing

- **Unit-testable (pure functions):** `projectedTravelForVelocity:`; the edge decision (given v + geometry → expected edge, including the no-stash and vertical-guard cases); the `relVx` normalization (given v + distance → expected vector, including the zero-distance guard).
- **Manual feel matrix:** soft vs. hard flick from center / near-edge / each side; mid-tuck grab; drag-out-and-reflick; rotation while stashed; tap-restore. Compare side-by-side with system PiP.

## Touch points

- `FLEXExplorerViewController.m`: `handleToolbarPanGesture:` (`Began` + `Ended`), `stashEdgeForReleaseWithVelocity:`, `stashToolbarToEdge:` (signature + spring), `restoreStashedToolbarAnimated:` (shared spring helper), new `projectedTravelForVelocity:`, new `toolbarStashAnimator` property, constants.
- `FLEXExplorerToolbar.*`: visual layer (sliver, chevron, cross-fade) — unchanged.

## Open items to confirm during implementation

1. Real pill width vs. the (suspected dead) edge-zone branch.
2. `UISpringTimingParameters` settle-time behaviour vs. needing the `mass:stiffness:damping:` form to match the current 0.4 s.
3. Sane clamp range for `relVx` when distance is small but velocity is large.
4. Tuned values for the projection deceleration and `band`.
