# File Browser Redesign — Design

**Date:** 2026-06-06
**Branch:** file-system
**Status:** Approved (design), pending implementation plan

## Goal

Overhaul the FLEX file browser screen (`FLEXFileBrowserController`) to look modern,
taking visual cues from Apple's Files app: an edge-to-edge list, metadata under each
filename, and a single consistent region for icons.

> **Icon decision (updated):** The folder/document icons use SF Symbols
> (`folder.fill` / `doc.fill`) on iOS 13+, with hand-drawn Core Graphics
> silhouettes as the fallback on iOS 12 (where SF Symbols don't exist). These are
> the final icons for this screen — the PaintCode artwork
> (`Design/FileBrowserIcons.pcvd`) is **not** used. The original plan was to treat
> the symbols as placeholders and wire in PaintCode later; the SF Symbols looked
> good enough to keep, and the CG fallback covers the iOS 12 deployment target that
> ruled out a symbols-only approach.

## Current State & Problems

`FLEXFileBrowserController : FLEXTableViewController` inherits the base controller's
default `UITableViewStyleInsetGrouped`, producing a floating rounded "card". Its cell,
`FLEXFileBrowserTableViewCell`, is an empty `UITableViewCell` subclass using the default
cell style, so:

- **No metadata shows.** `cellForRowAtIndexPath:` computes a `subtitle` and assigns it
  to `detailTextLabel`, but the default cell style has no detail label, so it is never
  displayed.
- **Inconsistent left edge.** Image files load a full-resolution `UIImage` synchronously
  into the built-in `imageView` at varying aspect ratios, shoving filenames around and
  jittering scroll on large images.
- **Separator hack.** Two reuse identifiers (`textCell` / `imageCell`) exist solely to
  work around separator misalignment between image and text rows.

## Design

### 1. Edge-to-edge table

Override the file browser's initializer to call `[super initWithStyle:UITableViewStylePlain]`
instead of inheriting `InsetGrouped`. This yields a full-width, edge-to-edge list.

The base class's only inset-grouped-specific behavior is returning a placeholder `@" "`
header for section 0; the file browser already overrides `titleForHeaderInSection:` with
its real "N files (size)" string, so nothing is lost. That header is retained as the
plain-style section header.

### 2. Dedicated cell — `FLEXFileBrowserCell`

Replace the empty inline `FLEXFileBrowserTableViewCell` and the two-identifier hack with a
single real cell class in its own file pair
(`GlobalStateExplorers/FileBrowser/FLEXFileBrowserCell.{h,m}`). SwiftPM auto-includes it
(target `path: "Classes"`); the folder is already in the header search paths. iOS 12-safe,
Auto Layout.

Anatomy:

```
│←16→┌──────┐←12→ FileName.ext                    › │   title    (label color, 17pt)
│    │ icon │     6 Jun 2026 · 13 MB                 │   subtitle (secondary, 13pt)
│    └──────┘                                        │
│             └─────────── separator inset to title ─┤
```

- **Fixed 40×40 icon region** at a constant left inset, so every row's text begins at the
  same x.
- **Title** + **subtitle** stacked vertically, centered against the icon. Title uses
  `UIColor.labelColor`, single line, middle truncation. Subtitle uses
  `FLEXColor.deemphasizedTextColor` / secondary label, single line.
- Disclosure chevron (`UITableViewCellAccessoryDisclosureIndicator`) preserved.
- `separatorInset.left` aligned to the title's leading edge (icon left inset + icon width
  + gap) so separators run from the title to the screen's right edge.
- Public API: a settable title string, subtitle string, and an exposed `iconImageView`
  (see §5). An `-setIcon:` / icon property accepts the resolved image.

### 3. Icon strategy

A single `iconForPath:` (or equivalent) seam resolves the image for the icon region:

- **Directory** → `folder.fill` SF Symbol, tinted `systemBlue`.
- **Image file** → real thumbnail, **downsampled off the main thread** via `CGImageSource`
  with `kCGImageSourceCreateThumbnailFromImageAlways` +
  `kCGImageSourceThumbnailMaxPixelSize` (~80px for a 40pt @2x region), aspect-fill,
  clipped to a ~6pt rounded square. Cached by path. On completion, applied to the cell only
  if its index path is still the one that requested it (guard against reuse).
- **Any other file** → `doc.fill` SF Symbol, tinted `systemGray`.

`folder.fill` / `doc.fill` are iOS 13+. On iOS 12 (a live deployment target) they are
replaced by cached, hand-drawn Core Graphics silhouettes — a tabbed folder and a page with
a folded top-right corner — drawn black and re-templated/tinted by the cell exactly like
the symbols. This keeps the SF Symbol look on iOS 13+ while ensuring iOS 12 rows aren't
iconless. The PaintCode artwork is not used.

### 4. Metadata line

- **Files:** `medium-style date · size` → e.g. `6 Jun 2026 · 13 MB`, built from a shared
  cached `NSDateFormatter` (date only, no time) and `NSByteCountFormatter`
  (`NSByteCountFormatterCountStyleFile`).
- **Folders:** `N item` / `N items` (retains the current count logic).

### 5. Image zoom-transition fix

`didSelectRowAtIndexPath:` currently uses `[tableView cellForRowAtIndexPath:indexPath].imageView`
(the built-in image view) as the source view for the iOS 18 zoom transition into
`FLEXImagePreviewController`. The custom cell no longer populates the built-in `imageView`,
so the source must be repointed to the custom cell's exposed `iconImageView`.

## Files Touched

- **New:** `Classes/GlobalStateExplorers/FileBrowser/FLEXFileBrowserCell.h`
- **New:** `Classes/GlobalStateExplorers/FileBrowser/FLEXFileBrowserCell.m`
- **Modified:** `Classes/GlobalStateExplorers/FileBrowser/FLEXFileBrowserController.m`
  - Override init to use `UITableViewStylePlain`.
  - Register / dequeue the single new cell; remove `textCell` / `imageCell` split and the
    inline empty cell class.
  - Move subtitle/icon resolution into the new flow; use the shared formatters.
  - Repoint the zoom-transition source view to the cell's `iconImageView`.

No `Package.swift` change required (SwiftPM globs `Classes/`). The new cell **is** added
to `FLEX.xcodeproj` (the project is hand-maintained and was already missing
`FLEXImagePreviewController` from the photo-viewer merge; both are added so the target
links and the unit tests run).

## Out of Scope

- The PaintCode `FileBrowserIcons.pcvd` artwork (superseded — SF Symbols + CG fallback).
- File-type-specific document icons (e.g. distinct ZIP / plist / db icons).
- Moving the file count to a centered footer (kept as the section header).
- Any change to navigation, search, sort, or context-menu behavior.

## Verification

- Build the Example app (`FLEXample`) via the SwiftPM target and open the App Bundle /
  Sandbox browser.
- Confirm: edge-to-edge list; consistent icon column; metadata under names; image rows show
  downsampled rounded thumbnails without shoving text; folders show `folder.fill` + item
  count; other files show `doc.fill` + date · size; separators inset to the title; chevrons
  present; tapping an image still zoom-transitions from its thumbnail; scrolling a directory
  of large images stays smooth.
