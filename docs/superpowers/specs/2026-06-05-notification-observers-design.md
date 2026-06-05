# Notification Observers — Design

**Date:** 2026-06-05
**Branch:** `notification-observers`
**Status:** Approved design, pre-implementation

## Background & motivation

FLEX previously exposed registered `NSNotificationCenter` observers via a `flex_observers`
shortcut on the Notification Center object explorer. That implementation scraped
`-[NSNotificationCenter debugDescription]`, parsed raw pointer values out of the text, and
resurrected them into live `id` objects. This crashed intermittently (~50%) with
`EXC_BAD_ACCESS` **inside Apple's `debugDescription`** itself: the center stores observers and
observed objects as non-owning (`unsafe_unretained`) references, so formatting the table
dereferences pointers that may already be dangling. The fault is inside the framework and
cannot be guarded or `@catch`'d (it is a Mach fault, not an `NSException`).

That shortcut has been removed (registration at `FLEXShortcutsFactory+Defaults.m` plus the
`NSNotificationCenter (Observers)` category). This feature replaces it with a safe,
swizzle-based observer registry.

### Why not read the ivars

`NSNotificationCenter` has three ivars: `_impl` (an **opaque** `^{__CFNotificationCenter=}`
C pointer), `actorQueueManagerLock`, and `_actorQueueManager`. The observer table lives inside
the opaque `__CFNotificationCenter` C struct, whose layout is private, undocumented, and
version-dependent. Walking it means reverse-engineering CoreFoundation internals by offset per
OS release — and it would still leave the dangling-pointer hazard, since the stored references
are non-owning. Rejected.

### Chosen approach

Swizzle the registration entry points and maintain FLEX's own registry using **zeroing weak
references**. Weak refs nil out on dealloc, so we can detect a dead observer without ever
messaging it — eliminating the crash by construction — and the design is OS-version
independent because it uses the public API surface.

## Goals

- Show a live list of the app's `NSNotificationCenter` observers with their state.
- Make leaks visible: surface observers that were **deallocated but never removed** (the
  dangerous dangling case) and let the user eyeball long-lived observers that should be gone.
- Attribute each observer to the code that registered it, including block-based observers.
- Filter out system-framework noise by default.

## Non-goals

- No automatic leak "verdict" — the tool shows state; the user judges.
- No reading of `NSNotificationCenter` private internals.
- No capture of observers registered before the user enables tracking (opt-in; see Activation).
- Not always-on; zero cost when disabled.

## Decisions (from brainstorming)

| Decision | Choice |
|----------|--------|
| Core goal | Show everything with state; no auto-verdict. |
| System filtering | Bundle-based classification; system observers hidden by default, revealed via scope. |
| Call-site capture | Capture backtrace cheaply at registration; symbolicate lazily; classify "ours" by first app-image frame. |
| Activation | Opt-in `NSUserDefaults` toggle (matches `FLEXNetworkObserver`); off by default; captures from enable onward. |

## Architecture

Mirrors the existing Network stack (`FLEXNetworkObserver` / `FLEXNetworkRecorder` /
`FLEXNetworkTransaction`). New folder: `Classes/GlobalStateExplorers/NotificationObservers/`.

| Type | Parallels | Role |
|------|-----------|------|
| `FLEXNotificationMonitor` | `FLEXNetworkObserver` | Installs swizzles (once, `dispatch_once`), gated by `NSUserDefaults`. Builds a record per `addObserver`, drops records on `removeObserver`. |
| `FLEXNotificationRecorder` | `FLEXNetworkRecorder` | Thread-safe singleton store (serial queue, sync reads / async writes). Holds records, posts a change notification, supports clear. |
| `FLEXNotificationRegistration` | `FLEXNetworkTransaction` | Model for one observer registration. |
| `FLEXNotificationObserversViewController` | network list VC | Searchable/filterable `FLEXFilteringTableViewController`, reached from the globals menu. |

> Naming: `FLEXNotificationObserver` was avoided for the swizzler because "observer" is the
> domain noun and would be confusing; `Monitor` reads clearer.

## Data model — `FLEXNotificationRegistration`

Captured **synchronously at registration time** (observer guaranteed alive), on the caller's
thread:

- `observerClassName : NSString` — captured now, so it survives the observer's death.
- `observerPointer : uintptr_t` — for display and for matching `removeObserver`. **Never
  messaged when the object is dead.**
- `__weak observer : id` — zeroing weak ref. Detects dealloc without touching the object;
  also allows live exploration while alive.
- `notificationName : NSString?` — nil means "any".
- `selectorString : NSString` — selector name, or `"(block)"` for the block API.
- `__weak observedObject : id` + `observedObjectClassName : NSString?`
- `returnAddresses : NSArray<NSNumber*>` — raw frame addresses from `backtrace()`.
  Symbolicated lazily (`dladdr`) only when a detail row is opened.
- `isOurs : BOOL` — computed once at registration from the **first app-image backtrace frame**
  (frame whose `dladdr` image path is inside `NSBundle.mainBundle.bundlePath`). Correctly
  attributes block observers, whose token class is Foundation's.
- `registeredAt : NSDate`
- **Computed `state`**: `alive` (weak ref non-nil) vs `deallocated` (weak ref nilled). A
  `deallocated` record that is still registered is the dangling leak.

### Weak-reference edge case

Objects that disallow weak references (override `allowsWeakReference`, certain CF-bridged
objects) fall back to recording class name + pointer only, with `state = unknown` (dealloc
cannot be tracked). Guarded so the fallback never crashes.

## Swizzle behavior — `FLEXNotificationMonitor`

Swizzles four `NSNotificationCenter` **instance** methods (covers all centers, not just
default), using FLEX's existing `FLEXUtility` swizzle helpers and a `dispatch_once` install:

- `addObserver:selector:name:object:` → create a record.
- `addObserverForName:object:queue:usingBlock:` → create a record for the returned token;
  `selectorString = "(block)"`.
- `removeObserver:` → drop **all** records whose `observerPointer` matches.
- `removeObserver:name:object:` → drop records matching pointer + name + object.

Threading: capture (class name, weak store, `backtrace`) happens synchronously on the caller's
thread; record insertion/removal is `dispatch_async`'d to the recorder's serial queue.

Gating mirrors `FLEXNetworkObserver`: swizzles install once on first enable and remain
installed; the swizzle bodies no-op when the `NSUserDefaults` flag is off, so toggling off is
free.

### State transitions surfaced

- **Registered & alive** → normal row.
- **Registered & deallocated** (weak nilled, no `removeObserver` seen) → highlighted as a leak.
- **Removed** (`removeObserver` matched) → record dropped (cleaned up properly; no noise).

## Store — `FLEXNotificationRecorder`

- Singleton via `dispatch_once`.
- Serial dispatch queue; `Synchronized`-style sync reads, `dispatch_async` writes (same
  pattern as `FLEXNetworkRecorder`).
- Holds an ordered array of `FLEXNotificationRegistration`.
- Posts a `kFLEXNotificationRecorderUpdated` notification on change; viewer reloads on main.
- `clear` method.
- `enabled` flag backed by `NSUserDefaults` (e.g. `flex_notificationObserverEnabled`).

## Viewer — `FLEXNotificationObserversViewController`

- New globals menu row "Notification Observers" (`bell.badge` SF Symbol; conforms to
  `FLEXGlobalsEntry`). Requires a new `FLEXGlobalsRow` enum case plus the title/color/symbol
  switch arms in `FLEXGlobalsViewController.m`.
- Subclass of `FLEXFilteringTableViewController` with a `FLEXTableViewSection` subclass for the
  rows.
- **Scope bar: "Mine" (default) / "All"** — implements the bundle filter; system observers
  hidden until switched to All.
- Search filters by observer class / notification name.
- **Row** (subtitle cell): title = `ObserverClass — notificationName`; subtitle =
  selector / `(block)` + state badge. Deallocated-but-registered rows tinted/marked as leaks.
- **Tap**: alive → push `FLEXObjectExplorerFactory explorerViewControllerForObject:` on the
  live observer; deallocated → a simple detail screen with the captured fields + the
  symbolicated registration backtrace.
- Right-bar items: enable/disable recording toggle + Clear. If recording is off when opened,
  show an empty-state "Observer tracking is off — Enable" prompt (matching network-observer
  behavior).

## Testing

Added to the existing `FLEXTests` XCTest target; recorder/monitor logic is unit-testable
without UI:

- Register via a real `NSNotificationCenter`; assert the store contains the record.
- Exercise both `removeObserver:` and `removeObserver:name:object:`; assert the correct
  records are dropped.
- Dealloc detection: register an observer created inside an `@autoreleasepool`; after drain,
  assert the record's state flips to `deallocated`.
- Classification: assert a registration made from test (app) code is flagged `isOurs == YES`.

## Open items deferred to implementation

- `Monitor` naming (vs. matching `FLEXNetworkObserver` exactly) — keep `Monitor` unless
  preferred otherwise.
- Removed records are dropped (no history) — confirmed for now; revisit only if history proves
  useful.
- Dead-observer detail screen vs. a plain text dump — start with the simple detail screen.
