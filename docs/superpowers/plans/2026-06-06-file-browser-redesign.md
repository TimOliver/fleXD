# File Browser Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild the FLEX file browser screen to look like Apple's Files app — edge-to-edge list, a consistent icon column, and metadata under each filename — using placeholder icons plus real downsampled image thumbnails.

**Architecture:** Switch the screen from `InsetGrouped` to a plain `UITableView`. Replace the empty inline cell with a dedicated `FLEXFileBrowserCell` that owns a fixed-size icon region and a stacked title/subtitle. The controller resolves each row's icon (SF Symbol folder/doc dummies, or an async-downsampled thumbnail for images) and metadata string.

**Tech Stack:** Objective-C, UIKit (Auto Layout), ImageIO (`CGImageSource` thumbnailing), SwiftPM build via the FLEXample example app.

**Verification approach:** This is a presentation-layer change; FLEX has no UI test harness (its tests are pure-logic only). Each task is verified by building and running the `FLEXample` app in the Simulator and inspecting the App Bundle / Sandbox browser. Use a concrete simulator that exists locally (list with `xcrun simctl list devices available`); the commands below use `iPhone 16` as a placeholder — substitute an available device.

Build/run command used throughout:

```bash
xcodebuild -project Example/FLEXample.xcodeproj -scheme FLEXample \
  -destination 'platform=iOS Simulator,name=iPhone 16' build
```

To view the screen: launch FLEXample in the Simulator, tap the FLEX toolbar, open **App Bundle Directory** (or **App Sandbox Directory**) under the Globals list.

---

## File Structure

- **Create** `Classes/GlobalStateExplorers/FileBrowser/FLEXFileBrowserCell.h` — public interface for the cell: exposed `iconImageView`, `titleLabel`, `subtitleLabel`, a `representedPath` reuse token, and two icon-setting methods.
- **Create** `Classes/GlobalStateExplorers/FileBrowser/FLEXFileBrowserCell.m` — view construction, Auto Layout, separator inset, reuse reset.
- **Modify** `Classes/GlobalStateExplorers/FileBrowser/FLEXFileBrowserController.m` — plain table style, register/dequeue the new cell, populate title/subtitle/icon, async thumbnails, remove the old inline cell + two reuse identifiers, repoint the zoom-transition source.

No `Package.swift` / `project.pbxproj` edits — SwiftPM auto-includes the new files (the folder is already on the header search path, mirroring the existing `FLEXImagePreviewController`).

Layout constants (shared between cell and controller — keep them in sync):

| Constant | Value | Meaning |
|---|---|---|
| icon left inset | `16` | leading edge of icon region |
| icon size | `40` | width & height of icon region |
| icon→text gap | `12` | space between icon and title |
| separator inset left | `68` | `16 + 40 + 12` — aligns separator to title |
| row height | `60` | fixed |

---

## Task 1: Create the `FLEXFileBrowserCell` view

**Files:**
- Create: `Classes/GlobalStateExplorers/FileBrowser/FLEXFileBrowserCell.h`
- Create: `Classes/GlobalStateExplorers/FileBrowser/FLEXFileBrowserCell.m`

- [ ] **Step 1: Write the header**

Create `Classes/GlobalStateExplorers/FileBrowser/FLEXFileBrowserCell.h`:

```objc
//
//  FLEXFileBrowserCell.h
//
//  Copyright (c) Flipboard (2014-2016); FLEX Team (2020-2026).
//  All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// A Files-style file browser row: a fixed-size icon region at the leading edge
/// with a stacked title (filename) and subtitle (metadata) beside it.
@interface FLEXFileBrowserCell : UITableViewCell

/// The fixed-size icon at the leading edge. Exposed so the controller can use it
/// as the source view for the image preview zoom transition.
@property (nonatomic, readonly) UIImageView *iconImageView;

/// The primary filename label.
@property (nonatomic, readonly) UILabel *titleLabel;

/// The secondary metadata label (e.g. "6 Jun 2026 · 13 MB" or "3 items").
@property (nonatomic, readonly) UILabel *subtitleLabel;

/// The file path this cell currently represents. Used as a reuse token so that
/// async thumbnail loads only apply if the cell still shows the same file.
@property (nonatomic, copy, nullable) NSString *representedPath;

/// Display a template/symbol icon: aspect-fit, tinted, no corner rounding.
/// Use for folder and document placeholder icons.
- (void)setSymbolIcon:(nullable UIImage *)image tintColor:(UIColor *)tintColor;

/// Display a photo thumbnail: aspect-fill, clipped to a rounded square.
- (void)setThumbnail:(UIImage *)image;

@end

NS_ASSUME_NONNULL_END
```

- [ ] **Step 2: Write the implementation**

Create `Classes/GlobalStateExplorers/FileBrowser/FLEXFileBrowserCell.m`:

```objc
//
//  FLEXFileBrowserCell.m
//
//  Copyright (c) Flipboard (2014-2016); FLEX Team (2020-2026).
//  All rights reserved.
//

#import "FLEXFileBrowserCell.h"
#import "FLEXColor.h"

static const CGFloat kFLEXFileCellIconLeftInset = 16.0;
static const CGFloat kFLEXFileCellIconSize = 40.0;
static const CGFloat kFLEXFileCellIconTextGap = 12.0;
static const CGFloat kFLEXFileCellThumbnailCornerRadius = 6.0;

@interface FLEXFileBrowserCell ()
@property (nonatomic, readwrite) UIImageView *iconImageView;
@property (nonatomic, readwrite) UILabel *titleLabel;
@property (nonatomic, readwrite) UILabel *subtitleLabel;
@end

@implementation FLEXFileBrowserCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self flex_setUpSubviews];
    }
    return self;
}

- (void)flex_setUpSubviews {
    self.iconImageView = [UIImageView new];
    self.iconImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.iconImageView.clipsToBounds = YES;
    [self.contentView addSubview:self.iconImageView];

    self.titleLabel = [UILabel new];
    self.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    self.titleLabel.textColor = FLEXColor.primaryTextColor;
    self.titleLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    self.titleLabel.numberOfLines = 1;

    self.subtitleLabel = [UILabel new];
    self.subtitleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    self.subtitleLabel.textColor = FLEXColor.deemphasizedTextColor;
    self.subtitleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    self.subtitleLabel.numberOfLines = 1;

    UIStackView *textStack = [[UIStackView alloc] initWithArrangedSubviews:@[
        self.titleLabel, self.subtitleLabel
    ]];
    textStack.axis = UILayoutConstraintAxisVertical;
    textStack.alignment = UIStackViewAlignmentFill;
    textStack.spacing = 2.0;
    textStack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:textStack];

    [NSLayoutConstraint activateConstraints:@[
        [self.iconImageView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor
                                                         constant:kFLEXFileCellIconLeftInset],
        [self.iconImageView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
        [self.iconImageView.widthAnchor constraintEqualToConstant:kFLEXFileCellIconSize],
        [self.iconImageView.heightAnchor constraintEqualToConstant:kFLEXFileCellIconSize],

        [textStack.leadingAnchor constraintEqualToAnchor:self.iconImageView.trailingAnchor
                                                constant:kFLEXFileCellIconTextGap],
        [textStack.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-8.0],
        [textStack.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
        [textStack.topAnchor constraintGreaterThanOrEqualToAnchor:self.contentView.topAnchor constant:8.0],
        [textStack.bottomAnchor constraintLessThanOrEqualToAnchor:self.contentView.bottomAnchor constant:-8.0],
    ]];

    // Align the separator with the title's leading edge.
    self.separatorInset = UIEdgeInsetsMake(
        0, kFLEXFileCellIconLeftInset + kFLEXFileCellIconSize + kFLEXFileCellIconTextGap, 0, 0
    );
    self.preservesSuperviewLayoutMargins = NO;
}

- (void)setSymbolIcon:(UIImage *)image tintColor:(UIColor *)tintColor {
    self.iconImageView.layer.cornerRadius = 0.0;
    self.iconImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.iconImageView.tintColor = tintColor;
    self.iconImageView.image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

- (void)setThumbnail:(UIImage *)image {
    self.iconImageView.layer.cornerRadius = kFLEXFileCellThumbnailCornerRadius;
    self.iconImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.iconImageView.image = image;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.representedPath = nil;
    self.iconImageView.image = nil;
    self.iconImageView.layer.cornerRadius = 0.0;
    self.titleLabel.text = nil;
    self.subtitleLabel.text = nil;
}

@end
```

- [ ] **Step 3: Build to verify it compiles**

Run:

```bash
xcodebuild -project Example/FLEXample.xcodeproj -scheme FLEXample \
  -destination 'platform=iOS Simulator,name=iPhone 16' build
```

Expected: **BUILD SUCCEEDED**. (The new class is unused so far; this confirms SwiftPM picks up the new files and the cell compiles.)

- [ ] **Step 4: Commit**

```bash
git add Classes/GlobalStateExplorers/FileBrowser/FLEXFileBrowserCell.h \
        Classes/GlobalStateExplorers/FileBrowser/FLEXFileBrowserCell.m
git commit -m "Add FLEXFileBrowserCell with fixed icon region and stacked labels"
```

---

## Task 2: Wire the controller to the new cell (plain style, dummy icons, metadata)

This task produces a complete modern screen using **placeholder icons for every row** (folder vs. document). Real image thumbnails are added in Task 3.

**Files:**
- Modify: `Classes/GlobalStateExplorers/FileBrowser/FLEXFileBrowserController.m`

- [ ] **Step 1: Import the new cell and remove the old inline cell**

At the top of `FLEXFileBrowserController.m`, add the import alongside the others (after line 46 `#import "FLEXFileBrowserSearchOperation.h"`):

```objc
#import "FLEXFileBrowserCell.h"
```

Delete the forward declaration at the top (lines 48-49):

```objc
@interface FLEXFileBrowserTableViewCell : UITableViewCell
@end
```

Delete the empty implementation at the bottom of the file (lines 569-571):

```objc
@implementation FLEXFileBrowserTableViewCell

@end
```

- [ ] **Step 2: Switch the screen to a plain, edge-to-edge table**

In `initWithPath:`, change the superclass initializer (line 80) from:

```objc
    self = [super init];
```

to:

```objc
    self = [super initWithStyle:UITableViewStylePlain];
```

- [ ] **Step 3: Register the single new cell and set a fixed row height**

Replace the two registrations in `viewDidLoad` (lines 119-120):

```objc
    [self.tableView registerClass:[FLEXFileBrowserTableViewCell class] forCellReuseIdentifier:@"textCell"];
    [self.tableView registerClass:[FLEXFileBrowserTableViewCell class] forCellReuseIdentifier:@"imageCell"];
```

with:

```objc
    [self.tableView registerClass:[FLEXFileBrowserCell class] forCellReuseIdentifier:@"fileCell"];
    self.tableView.rowHeight = 60.0;
```

- [ ] **Step 4: Add shared formatter and icon helpers**

Add these static helpers just below the imports (e.g. after line 46's import block, before the `FLEXFileBrowserSortAttribute` enum):

```objc
static NSDateFormatter *FLEXFileBrowserDateFormatter(void) {
    static NSDateFormatter *formatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [NSDateFormatter new];
        formatter.dateStyle = NSDateFormatterMediumStyle;
        formatter.timeStyle = NSDateFormatterNoStyle;
    });
    return formatter;
}

static UIImage *FLEXFileBrowserFolderIcon(void) {
    if (@available(iOS 13.0, *)) {
        return [UIImage systemImageNamed:@"folder.fill"];
    }
    return nil;
}

static UIImage *FLEXFileBrowserDocumentIcon(void) {
    if (@available(iOS 13.0, *)) {
        return [UIImage systemImageNamed:@"doc.fill"];
    }
    return nil;
}
```

- [ ] **Step 5: Add a subtitle builder method**

Add this method to the controller (e.g. just above `filePathAtIndexPath:`):

```objc
- (NSString *)subtitleForPath:(NSString *)path
                   attributes:(NSDictionary<NSString *, id> *)attributes
                  isDirectory:(BOOL)isDirectory {
    if (isDirectory) {
        NSUInteger count = [NSFileManager.defaultManager contentsOfDirectoryAtPath:path error:NULL].count;
        return [NSString stringWithFormat:@"%lu item%@", (unsigned long)count, (count == 1 ? @"" : @"s")];
    }

    NSString *sizeString = [NSByteCountFormatter stringFromByteCount:attributes.fileSize
                                                          countStyle:NSByteCountFormatterCountStyleFile];
    NSDate *modified = attributes.fileModificationDate;
    if (modified) {
        NSString *dateString = [FLEXFileBrowserDateFormatter() stringFromDate:modified];
        return [NSString stringWithFormat:@"%@ · %@", dateString, sizeString];
    }
    return sizeString;
}
```

- [ ] **Step 6: Rewrite `cellForRowAtIndexPath:`**

Replace the entire body of `tableView:cellForRowAtIndexPath:` (lines 224-256) with:

```objc
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *fullPath = [self filePathAtIndexPath:indexPath];
    NSDictionary<NSString *, id> *attributes = [NSFileManager.defaultManager attributesOfItemAtPath:fullPath error:NULL];
    BOOL isDirectory = [attributes.fileType isEqual:NSFileTypeDirectory];

    FLEXFileBrowserCell *cell = [tableView dequeueReusableCellWithIdentifier:@"fileCell" forIndexPath:indexPath];
    cell.representedPath = fullPath;
    cell.titleLabel.text = fullPath.lastPathComponent;
    cell.subtitleLabel.text = [self subtitleForPath:fullPath attributes:attributes isDirectory:isDirectory];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    if (isDirectory) {
        [cell setSymbolIcon:FLEXFileBrowserFolderIcon() tintColor:UIColor.systemBlueColor];
    } else {
        [cell setSymbolIcon:FLEXFileBrowserDocumentIcon() tintColor:UIColor.systemGrayColor];
    }

    return cell;
}
```

- [ ] **Step 7: Repoint the image zoom-transition source view**

In `didSelectRowAtIndexPath:`, replace the source-view line (line 378):

```objc
                UIView *source = [tableView cellForRowAtIndexPath:indexPath].imageView;
```

with:

```objc
                UITableViewCell *selectedCell = [tableView cellForRowAtIndexPath:indexPath];
                UIView *source = [selectedCell isKindOfClass:[FLEXFileBrowserCell class]]
                    ? ((FLEXFileBrowserCell *)selectedCell).iconImageView
                    : selectedCell.imageView;
```

- [ ] **Step 8: Build and run, verify the screen**

Run:

```bash
xcodebuild -project Example/FLEXample.xcodeproj -scheme FLEXample \
  -destination 'platform=iOS Simulator,name=iPhone 16' build
```

Expected: **BUILD SUCCEEDED**.

Launch FLEXample in the Simulator, open **App Bundle Directory**. Verify:
- The list is edge-to-edge (no floating rounded card).
- Every row has an icon in the same left column: folders show a blue `folder.fill`, all other files show a gray `doc.fill`.
- Filenames have metadata underneath: files show `date · size`, folders show `N items`.
- Separators start at the filename's leading edge and run to the right screen edge.
- Disclosure chevrons are present; tapping a folder still drills in; tapping files still opens them.

- [ ] **Step 9: Commit**

```bash
git add Classes/GlobalStateExplorers/FileBrowser/FLEXFileBrowserController.m
git commit -m "Rebuild file browser as plain edge-to-edge list with new cell"
```

---

## Task 3: Add async downsampled thumbnails for image files

Layers real image thumbnails into the icon region, replacing the document placeholder for files that are images. Thumbnails are generated off the main thread, downsampled, and cached.

**Files:**
- Modify: `Classes/GlobalStateExplorers/FileBrowser/FLEXFileBrowserController.m`

- [ ] **Step 1: Add a thumbnail cache property**

In the class extension (`@interface FLEXFileBrowserController ()`, lines 57-67), add:

```objc
@property (nonatomic) NSCache<NSString *, id> *thumbnailCache;
```

Initialize it in `initWithPath:`, just after `self.operationQueue = [NSOperationQueue new];`:

```objc
        self.thumbnailCache = [NSCache new];
```

- [ ] **Step 2: Add the downsampling helper**

Add this static function next to the icon helpers from Task 2. It uses ImageIO (already imported at line 45) to produce a small thumbnail, and returns `nil` for non-image files:

```objc
static UIImage *FLEXFileBrowserThumbnail(NSString *path, CGFloat pointSize, CGFloat scale) {
    NSURL *url = [NSURL fileURLWithPath:path];
    CGImageSourceRef source = CGImageSourceCreateWithURL((__bridge CFURLRef)url, NULL);
    if (!source) {
        return nil;
    }
    // Not an image (CGImageSource can't identify a type): bail.
    if (!CGImageSourceGetType(source)) {
        CFRelease(source);
        return nil;
    }

    NSDictionary *options = @{
        (id)kCGImageSourceCreateThumbnailFromImageAlways: @YES,
        (id)kCGImageSourceCreateThumbnailWithTransform: @YES,
        (id)kCGImageSourceThumbnailMaxPixelSize: @(pointSize * scale),
    };
    CGImageRef thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, (__bridge CFDictionaryRef)options);
    CFRelease(source);
    if (!thumbnail) {
        return nil;
    }

    UIImage *image = [UIImage imageWithCGImage:thumbnail scale:scale orientation:UIImageOrientationUp];
    CGImageRelease(thumbnail);
    return image;
}
```

- [ ] **Step 3: Add an async thumbnail loader method**

Add this method to the controller (e.g. just below `subtitleForPath:attributes:isDirectory:`). It checks the cache, applies a cached thumbnail synchronously, and otherwise loads off-main and applies only if the cell still represents the same path. A cached `NSNull` marks "known not an image" so we don't re-sniff on every reuse:

```objc
- (void)loadThumbnailForPath:(NSString *)path intoCell:(FLEXFileBrowserCell *)cell {
    id cached = [self.thumbnailCache objectForKey:path];
    if ([cached isKindOfClass:[UIImage class]]) {
        [cell setThumbnail:cached];
        return;
    }
    if (cached) {
        // Cached NSNull: known to not be an image, leave the document icon.
        return;
    }

    CGFloat scale = UIScreen.mainScreen.scale;
    weakify(self)
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{ strongify(self)
        UIImage *thumbnail = FLEXFileBrowserThumbnail(path, 40.0, scale);
        if (!self) {
            return;
        }
        [self.thumbnailCache setObject:(thumbnail ?: (id)NSNull.null) forKey:path];

        if (!thumbnail) {
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([cell.representedPath isEqualToString:path]) {
                [cell setThumbnail:thumbnail];
            }
        });
    });
}
```

- [ ] **Step 4: Call the loader for non-directory files**

In `cellForRowAtIndexPath:`, change the `else` branch (the non-directory case from Task 2) to set the document placeholder *and* kick off a thumbnail load:

```objc
    if (isDirectory) {
        [cell setSymbolIcon:FLEXFileBrowserFolderIcon() tintColor:UIColor.systemBlueColor];
    } else {
        [cell setSymbolIcon:FLEXFileBrowserDocumentIcon() tintColor:UIColor.systemGrayColor];
        [self loadThumbnailForPath:fullPath intoCell:cell];
    }
```

- [ ] **Step 5: Build and run, verify thumbnails**

Run:

```bash
xcodebuild -project Example/FLEXample.xcodeproj -scheme FLEXample \
  -destination 'platform=iOS Simulator,name=iPhone 16' build
```

Expected: **BUILD SUCCEEDED**.

Launch FLEXample, open **App Bundle Directory**. Verify:
- Image files (`.jpg`, `.jpeg`, the extension-less `image`, etc.) now show a real thumbnail clipped into a rounded square in the icon column; non-images still show the gray `doc.fill`.
- Thumbnails do not shove the filename around — text still starts at the same x as every other row.
- Scrolling a directory with several large images stays smooth (no main-thread stalls).
- Scrolling fast and back does not show a thumbnail on the wrong row (reuse guard works).

- [ ] **Step 6: Commit**

```bash
git add Classes/GlobalStateExplorers/FileBrowser/FLEXFileBrowserController.m
git commit -m "Show async downsampled thumbnails for image files in file browser"
```

---

## Task 4: Final visual QA pass

**Files:** none (verification only)

- [ ] **Step 1: Side-by-side check against Files**

Launch FLEXample, open both **App Bundle Directory** and **App Sandbox Directory**, and confirm the screen reads like Apple's Files app:
- Consistent icon column, metadata under names, edge-to-edge separators inset to the title.
- Folder rows: blue folder icon + item count. Document rows: gray doc icon + `date · size`. Image rows: rounded thumbnail + `date · size`.
- Search still works (type in the search bar; results use the same cell).
- Sort still works (Sort toolbar button → Name / Creation Date reorders rows).
- Long-press context menu (Rename / Delete / Copy Path / Share) still works.
- Tapping an image opens the preview with the zoom transition originating from the thumbnail.

- [ ] **Step 2: Capture a screenshot for the record**

```bash
xcrun simctl io booted screenshot /tmp/flex-file-browser-redesign.png
```

Confirm the screenshot matches the intended design. No commit needed.
