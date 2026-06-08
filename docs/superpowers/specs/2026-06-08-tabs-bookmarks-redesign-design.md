# Tabs & Bookmarks Redesign — Design

**Date:** 2026-06-08
**Branch:** `tabs-bookmarks-redesign`
**Status:** Approved design, pre-implementation

## Background & motivation

FLEX's Tabs and Bookmarks UI has accreted a confusing interaction model. From a trace of the
current behavior (`FLEXExplorerViewController`, `FLEXTableViewController`,
`FLEXTabsViewController`, `FLEXBookmarksViewController`, `FLEXTabList`, `FLEXBookmarkManager`,
`FLEXNavigationController`), three problems stand out:

1. **Implicit tabs + inconsistent dismissal.** A tab is created silently whenever a
   `FLEXNavigationController` appears; the user never explicitly "opens a tab." Worse, pressing
   **Done** *closes* the tab while swiping down *keeps it open* — the same screen, two gestures,
   opposite outcomes.
2. **Too many overlapping entry points for tabs.** Tabs are reachable via the in-explorer
   bottom-toolbar Tabs button, a hidden long-press on the floating toolbar's menu button, and
   the floating toolbar's Recent button (which reopens the active tab).
3. **Tabs and Bookmarks are conflated.** They appear as equal-weight peer icons in the same
   bottom toolbar, yet do very different things, and bookmarks secretly double as a "source
   list" when spawning a new tab. The bookmark *ribbon* glyph also fights its learned
   iBooks/Safari meaning — users expect a ribbon to **toggle** the current item's bookmark
   state, not open a list.

## Goals

- Make the tab lifecycle explicit and predictable (Safari-style).
- Collapse the many tab entry points into one.
- Cleanly separate "tabs" from "bookmarks," and give the bookmark ribbon its conventional
  per-object toggle meaning.

## Non-goals

- No tab-count badge (Safari itself dropped this).
- No on-disk persistence of tabs or bookmarks (remains in-memory, as today).
- No conversion of unrelated PNG icons (only the two icons this redesign touches move to SF
  Symbols).

## Decisions (from brainstorming)

| Decision | Choice |
|----------|--------|
| Tab concept | Keep tabs, make them explicit (Safari-style). |
| Dismiss semantics | Dismissing the explorer (Done **or** swipe) always **backgrounds** the tab; a tab is closed **only** from the switcher. |
| Entry points | One **Tabs** button everywhere opens the switcher; resume by tapping a tab. Remove the Recent button and the long-press gesture. |
| Bookmarks home | The bookmarks **list** moves into the switcher as a segment. |
| Bookmark ribbon | Becomes a **per-object toggle** in the object-explorer nav bar (outline ⇄ filled). |
| Switcher layout | A segmented control: **Tabs \| Bookmarks** (iBooks pattern). |
| Standalone bookmarks screen | Retired entirely. |

## The mental model

> A **tab** is an explorer session you open, switch, and close deliberately; a **bookmark** is
> an object you've starred. Both live in one **switcher**, reached by one **Tabs** button.
> Dismissing the explorer never destroys anything.

## Design

### 1. The switcher (segmented Tabs | Bookmarks)

`FLEXTabsViewController` becomes the single hub. A `UISegmentedControl` ("Tabs" / "Bookmarks")
sits in the navigation title position.

```
┌──────────────────────────────┐
│        [ Tabs | Bookmarks ]   │  ← segmented control (nav title view)
│  ┌────────┐  ┌────────┐       │
│  │ snap   │  │ snap   │   ✕   │  Tabs segment: open tabs w/ snapshots,
│  │ Globals│  │ UIView │       │  tap = switch, swipe/✕ = close, + = new
│  └────────┘  └────────┘       │
│                          [ + ]│
└──────────────────────────────┘
```

- **Tabs segment:** the existing tab list with snapshots — tap to switch, swipe (or an ✕
  affordance) to close, `+` toolbar item to open a new tab.
- **Bookmarks segment:** the bookmark list logic currently in `FLEXBookmarksViewController`,
  folded in — tap a bookmark to open it in a tab, swipe to remove, edit-mode for multi-remove.
- The two segments swap the table's data source / editing behavior; the `+` item is shown only
  on the Tabs segment.

`FLEXBookmarksViewController` is **retired** as a standalone screen; its list/selection/delete
logic is moved into the switcher's Bookmarks segment (extracted into a reusable section or data
source so the switcher stays focused).

### 2. The bookmark ribbon as a per-object toggle

On object-explorer screens (`FLEXObjectExplorerViewController`), a ribbon toggle moves into the
**nav bar (right side)**:

```
  ‹ Back        NSObject        􀉟      outline  = not bookmarked
  ‹ Back        NSObject        􀉞      filled   = bookmarked
```

- `bookmark` (outline) ⇄ `bookmark.fill` (filled), reflecting whether the current object is in
  `FLEXBookmarkManager.bookmarks`. Tapping toggles add/remove and updates the glyph immediately.
- The buried **Share → "Add to Bookmarks" action is removed**; Share keeps Copy Description and
  Copy Address.
- The toggle appears only where there is a concrete object to star (object explorers), not on
  every table screen.

### 3. Toolbar & gesture changes

**Floating explorer toolbar (`FLEXExplorerToolbar` / `FLEXExplorerViewController`):**
- The **Recent** button (`clock.arrow.circlepath`) is replaced by a **Tabs** button
  (`square.on.square`) that opens the switcher.
- The **hidden long-press gesture** on the menu button (`handleToolbarShowTabsGesture:`) is
  deleted.
- Menu / Views / Select / Move / Close are unchanged.

**In-explorer bottom toolbar (`FLEXTableViewController`):**
- The **Bookmarks button is removed** (its job is now split between the nav-bar toggle and the
  switcher's Bookmarks segment).
- The **Tabs button stays** and opens the same switcher.

### 4. Lifecycle

- `FLEXNavigationController`'s "Done closes the tab" behavior is removed. **Done and swipe-down
  both simply background** the explorer to the floating toolbar; the tab remains open.
- A tab is closed **only** from the switcher's Tabs segment (swipe / ✕ / edit-mode).

### 5. New-tab flow

- The switcher's `+` opens a fresh tab to the **Main Menu** directly. The old "Main Menu vs
  Choose from Bookmarks" action sheet is removed — bookmarks are now one segment away.

### 6. Icons

Because these two buttons are being redefined anyway, both move to **SF Symbols**:
- Tabs button → `square.on.square`
- Bookmark toggle → `bookmark` / `bookmark.fill`

The `tabs` and `bookmarks` embedded-PNG byte-arrays in `FLEXResources.m` and their
`FLEXResources` accessors (`openTabsIcon`, `bookmarksIcon`) are retired. (Other PNG icons are
out of scope.)

## Affected files (anticipated)

- `Classes/ExplorerInterface/Tabs/FLEXTabsViewController.{h,m}` — segmented control; host both segments.
- `Classes/ExplorerInterface/Bookmarks/FLEXBookmarksViewController.{h,m}` — retire; extract list logic into a reusable section/data source consumed by the switcher.
- `Classes/ObjectExplorers/FLEXObjectExplorerViewController.m` — nav-bar ribbon toggle; remove Share-sheet "Add to Bookmarks".
- `Classes/ExplorerInterface/FLEXExplorerViewController.m` — replace Recent with Tabs; delete long-press gesture.
- `Classes/Toolbar/FLEXExplorerToolbar.{m}` — Tabs button (SF Symbol) replacing Recent.
- `Classes/Core/Controllers/FLEXTableViewController.m` — remove Bookmarks toolbar item; keep Tabs item.
- `Classes/Core/Controllers/FLEXNavigationController.m` — remove "Done closes tab" behavior.
- `Classes/Utility/FLEXResources.{h,m}` — retire `openTabsIcon` / `bookmarksIcon` and their byte-arrays.

## Testing

UI/interaction changes are primarily verified by build + manual smoke (FLEXample), since FLEX's
UI is not unit-tested. Where logic is extractable (e.g. the bookmark toggle's add/remove state,
the switcher segment's data source), add focused XCTest coverage in `FLEXTests` if it can be
exercised without UI. Manual smoke checklist:
- New tab via `+`; switch tabs; close a tab only from the switcher.
- Done and swipe both keep the tab open; reopen via Tabs → active tab.
- Bookmark toggle stars/unstars the current object; glyph reflects state; bookmark appears in
  the switcher's Bookmarks segment; tapping it opens the object.
- Long-press on the menu button no longer opens tabs; Recent button is gone.

## Open items deferred to implementation

- Exact placement of the segmented control (nav `titleView` vs. a header) — pick what renders
  cleanly under iOS 26's nav bar.
- Whether the bookmark toggle also belongs on non-object explorer screens that still represent a
  bookmarkable target (default: object explorers only).
