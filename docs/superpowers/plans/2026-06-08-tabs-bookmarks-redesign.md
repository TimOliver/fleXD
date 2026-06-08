# Tabs & Bookmarks Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make FLEX's tabs explicit and predictable (Safari-style), collapse the bookmarks list into the tab switcher behind a segmented control, and turn the bookmark ribbon into a per-object toggle.

**Architecture:** A single switcher (`FLEXTabsViewController`) gains a `Tabs | Bookmarks` segmented control in its bottom toolbar and absorbs the bookmarks list (retiring `FLEXBookmarksViewController`). The bookmark ribbon moves to the object-explorer nav bar as an add/remove toggle backed by new `FLEXBookmarkManager` helpers. Dismissing the explorer always backgrounds the tab; tabs close only from the switcher. One Tabs button (SF Symbol `square.on.square`) opens the switcher on both the floating toolbar and the in-explorer toolbar; the Recent button's resume behavior and the hidden long-press gesture are removed.

**Tech Stack:** Objective-C, UIKit, `FLEX.xcodeproj` (targets `FLEX`, `FLEXTests`), XCTest.

**Design spec:** `docs/superpowers/specs/2026-06-08-tabs-bookmarks-redesign-design.md`

---

## Conventions (read first)

- **No co-author trailer** in commit messages (project rule). Plain messages only.
- **Build the framework:** `xcodebuild build -project FLEX.xcodeproj -scheme FLEX -destination 'generic/platform=iOS Simulator' -configuration Debug 2>&1 | grep -E "BUILD SUCCEEDED|BUILD FAILED|error:"`
- **Build the example app (SPM path — auto-globs `Classes/`):** `xcodebuild build -project Example/FLEXample.xcodeproj -scheme FLEXample -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -configuration Debug 2>&1 | grep -E "^\*\* BUILD (SUCCEEDED|FAILED)|: error:"`
- **Tests:** `xcodebuild test -project FLEX.xcodeproj -scheme FLEXTests -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -8` (single class: append `-only-testing:FLEXTests/<ClassName>`).
- **Add a new file to a target** (Xcode targets do not auto-glob): `ruby Scripts/xcode_add_file.rb FLEX <paths...>` / `ruby Scripts/xcode_add_file.rb FLEXTests <paths...>`.
- This is a UI refactor; most tasks are verified by **build + manual smoke**, since FLEX's UI is not unit-tested. Only Task 2's manager helpers get an XCTest.
- Baseline is green; keep it green. Commit once per task.

---

## Task 1: Lifecycle — dismissing always backgrounds the tab

**Files:**
- Modify: `Classes/Core/Controllers/FLEXNavigationController.m` (`dismissAnimated`, ~lines 144-152)

- [ ] **Step 1: Make `dismissAnimated` stop closing the tab**

Replace the current method:
```objc
- (void)dismissAnimated {
    // Tabs are only closed if the done button is pressed; this
    // allows you to leave a tab open by dragging down to dismiss
    if ([self.presentingViewController isKindOfClass:[FLEXExplorerViewController class]]) {
        [FLEXTabList.sharedList closeTab:self];        
    }

    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}
```
with:
```objc
- (void)dismissAnimated {
    // Dismissing always backgrounds the tab (Done and swipe-down behave identically);
    // tabs are closed only from the switcher.
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}
```

- [ ] **Step 2: Build**

Run the framework build command. Expected: `** BUILD SUCCEEDED **`. (`FLEXExplorerViewController`/`FLEXTabList` imports may now be unused in this file — that's a warning at most, not an error; leave the imports.)

- [ ] **Step 3: Commit**

```bash
git add Classes/Core/Controllers/FLEXNavigationController.m
git commit -m "Tabs: dismissing the explorer always backgrounds the tab"
```

---

## Task 2: Bookmark toggle + manager helpers

**Files:**
- Modify: `Classes/ExplorerInterface/Bookmarks/FLEXBookmarkManager.h`
- Modify: `Classes/ExplorerInterface/Bookmarks/FLEXBookmarkManager.m`
- Modify: `Classes/ObjectExplorers/FLEXObjectExplorerViewController.m`
- Test: `FLEXTests/FLEXBookmarkManagerTests.m`

Current `FLEXBookmarkManager.h` interface is just:
```objc
@interface FLEXBookmarkManager : NSObject
@property (nonatomic, readonly, class) NSMutableArray *bookmarks;
@end
```

- [ ] **Step 1: Write the failing test**

`FLEXTests/FLEXBookmarkManagerTests.m`:
```objc
#import <XCTest/XCTest.h>
#import "FLEXBookmarkManager.h"

@interface FLEXBookmarkManagerTests : XCTestCase
@end

@implementation FLEXBookmarkManagerTests

- (void)setUp {
    [FLEXBookmarkManager.bookmarks removeAllObjects];
}

- (void)testIsBookmarkedUsesIdentityNotEquality {
    NSString *a = [@"x" mutableCopy];           // distinct instances that are -isEqual:
    NSString *b = [@"x" mutableCopy];
    [FLEXBookmarkManager addBookmark:a];
    XCTAssertTrue([FLEXBookmarkManager isObjectBookmarked:a]);
    XCTAssertFalse([FLEXBookmarkManager isObjectBookmarked:b]); // identity, not equality
}

- (void)testAddIsIdempotent {
    NSObject *o = [NSObject new];
    [FLEXBookmarkManager addBookmark:o];
    [FLEXBookmarkManager addBookmark:o];
    XCTAssertEqual(FLEXBookmarkManager.bookmarks.count, 1);
}

- (void)testRemove {
    NSObject *o = [NSObject new];
    [FLEXBookmarkManager addBookmark:o];
    [FLEXBookmarkManager removeBookmark:o];
    XCTAssertFalse([FLEXBookmarkManager isObjectBookmarked:o]);
    XCTAssertEqual(FLEXBookmarkManager.bookmarks.count, 0);
}

- (void)testNilIsSafe {
    XCTAssertFalse([FLEXBookmarkManager isObjectBookmarked:nil]);
    [FLEXBookmarkManager addBookmark:nil];      // no-op, no crash
    [FLEXBookmarkManager removeBookmark:nil];   // no-op, no crash
    XCTAssertEqual(FLEXBookmarkManager.bookmarks.count, 0);
}

@end
```

- [ ] **Step 2: Add the test to the target and run it (expect build failure)**

```bash
ruby Scripts/xcode_add_file.rb FLEXTests FLEXTests/FLEXBookmarkManagerTests.m
xcodebuild test -project FLEX.xcodeproj -scheme FLEXTests -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:FLEXTests/FLEXBookmarkManagerTests 2>&1 | tail -20
```
Expected: build failure (the three `+` methods don't exist yet).

- [ ] **Step 3: Add the manager helpers**

In `FLEXBookmarkManager.h`, add the three methods inside the interface:
```objc
@interface FLEXBookmarkManager : NSObject
@property (nonatomic, readonly, class) NSMutableArray *bookmarks;

/// Identity-based (not -isEqual:) membership check.
+ (BOOL)isObjectBookmarked:(nullable id)object;
/// Adds the object if not already bookmarked (by identity). nil is a no-op.
+ (void)addBookmark:(nullable id)object;
/// Removes the object by identity if present. nil is a no-op.
+ (void)removeBookmark:(nullable id)object;
@end
```
(If the header doesn't already wrap its interface in `NS_ASSUME_NONNULL_BEGIN/END`, the `nullable` annotations are still fine on their own.)

In `FLEXBookmarkManager.m`, add the implementations inside `@implementation`:
```objc
+ (BOOL)isObjectBookmarked:(id)object {
    if (!object) return NO;
    return [self.bookmarks indexOfObjectIdenticalTo:object] != NSNotFound;
}

+ (void)addBookmark:(id)object {
    if (object && ![self isObjectBookmarked:object]) {
        [self.bookmarks addObject:object];
    }
}

+ (void)removeBookmark:(id)object {
    if (!object) return;
    NSUInteger index = [self.bookmarks indexOfObjectIdenticalTo:object];
    if (index != NSNotFound) {
        [self.bookmarks removeObjectAtIndex:index];
    }
}
```

- [ ] **Step 4: Run the test (expect pass)**

Run the Step 2 test command. Expected: `** TEST SUCCEEDED **` (4 tests).

- [ ] **Step 5: Add the per-object toggle to the object explorer**

In `Classes/ObjectExplorers/FLEXObjectExplorerViewController.m`:

(a) Add a private property to the class extension at the top of the file (find the `@interface FLEXObjectExplorerViewController ()` extension and add):
```objc
@property (nonatomic) UIBarButtonItem *bookmarkItem;
```

(b) In `viewDidLoad`, after the existing `addToolbarItems:` block (around line 140), add:
```objc
// Per-object bookmark toggle (ribbon) in the nav bar
self.bookmarkItem = [[UIBarButtonItem alloc]
    initWithImage:[self bookmarkImage]
    style:UIBarButtonItemStylePlain
    target:self action:@selector(toggleBookmark:)];
self.navigationItem.rightBarButtonItem = self.bookmarkItem;
```

(c) Add these two methods (anywhere in the implementation, e.g. near `shareButtonPressed:`):
```objc
- (UIImage *)bookmarkImage {
    BOOL bookmarked = [FLEXBookmarkManager isObjectBookmarked:self.object];
    return [UIImage systemImageNamed:(bookmarked ? @"bookmark.fill" : @"bookmark")];
}

- (void)toggleBookmark:(UIBarButtonItem *)sender {
    if ([FLEXBookmarkManager isObjectBookmarked:self.object]) {
        [FLEXBookmarkManager removeBookmark:self.object];
    } else {
        [FLEXBookmarkManager addBookmark:self.object];
    }
    self.bookmarkItem.image = [self bookmarkImage];
}
```

(d) Remove the "Add to Bookmarks" action from `shareButtonPressed:` (lines ~260-273). Change:
```objc
- (void)shareButtonPressed:(UIBarButtonItem *)sender {
    [FLEXAlert makeSheet:^(FLEXAlert *make) {
        make.button(@"Add to Bookmarks").handler(^(NSArray<NSString *> *strings) {
            [FLEXBookmarkManager.bookmarks addObject:self.object];
        });
        make.button(@"Copy Description").handler(^(NSArray<NSString *> *strings) {
            UIPasteboard.generalPasteboard.string = self.explorer.objectDescription;
        });
        make.button(@"Copy Address").handler(^(NSArray<NSString *> *strings) {
            UIPasteboard.generalPasteboard.string = [FLEXUtility addressOfObject:self.object];
        });
        make.button(@"Cancel").cancelStyle();
    } showFrom:self source:sender];
}
```
to:
```objc
- (void)shareButtonPressed:(UIBarButtonItem *)sender {
    [FLEXAlert makeSheet:^(FLEXAlert *make) {
        make.button(@"Copy Description").handler(^(NSArray<NSString *> *strings) {
            UIPasteboard.generalPasteboard.string = self.explorer.objectDescription;
        });
        make.button(@"Copy Address").handler(^(NSArray<NSString *> *strings) {
            UIPasteboard.generalPasteboard.string = [FLEXUtility addressOfObject:self.object];
        });
        make.button(@"Cancel").cancelStyle();
    } showFrom:self source:sender];
}
```

- [ ] **Step 6: Build and verify the toggle coexists with Done**

Run the framework build. Expected: `** BUILD SUCCEEDED **`.

> Verify during build/smoke: `FLEXNavigationController` prepends a Done/Cancel item to `rightBarButtonItems`, so the object explorer should show `[Done] [ribbon]`. If the base class is found to clobber `rightBarButtonItem`, instead append: `self.navigationItem.rightBarButtonItems = [@[self.bookmarkItem] arrayByAddingObjectsFromArray:(self.navigationItem.rightBarButtonItems ?: @[])];` — but the simple assignment is expected to work since the explorer sets it in `viewDidLoad` before presentation.

- [ ] **Step 7: Commit**

```bash
git add Classes/ExplorerInterface/Bookmarks/FLEXBookmarkManager.h \
        Classes/ExplorerInterface/Bookmarks/FLEXBookmarkManager.m \
        Classes/ObjectExplorers/FLEXObjectExplorerViewController.m \
        FLEXTests/FLEXBookmarkManagerTests.m FLEX.xcodeproj/project.pbxproj
git commit -m "Bookmarks: per-object ribbon toggle in object explorer; identity-based manager helpers"
```

---

## Task 3: Switcher — fold bookmarks in behind a segmented control

**Files:**
- Modify: `Classes/ExplorerInterface/Tabs/FLEXTabsViewController.m` (full replacement of the implementation)

This merges the bookmarks list (currently in `FLEXBookmarksViewController`) into the switcher as a second segment, adds the `Tabs | Bookmarks` segmented control to the bottom toolbar, and simplifies the `+` flow. The header (`FLEXTabsViewController.h`) is unchanged.

- [ ] **Step 1: Replace `FLEXTabsViewController.m`'s code**

Replace everything from the first `#import` to the final `@end` with:
```objc
#import "FLEXTabsViewController.h"
#import "FLEXNavigationController.h"
#import "FLEXTabList.h"
#import "FLEXBookmarkManager.h"
#import "FLEXTableView.h"
#import "FLEXUtility.h"
#import "FLEXColor.h"
#import "UIBarButtonItem+FLEX.h"
#import "FLEXExplorerViewController.h"
#import "FLEXGlobalsViewController.h"
#import "FLEXObjectExplorerFactory.h"
#import "FLEXRuntimeUtility.h"

typedef NS_ENUM(NSUInteger, FLEXSwitcherMode) {
    FLEXSwitcherModeTabs = 0,
    FLEXSwitcherModeBookmarks = 1,
};

@interface FLEXTabsViewController ()
@property (nonatomic, copy) NSArray<UINavigationController *> *openTabs;
@property (nonatomic, copy) NSArray<UIImage *> *tabSnapshots;
@property (nonatomic) NSInteger activeIndex;
@property (nonatomic) BOOL presentNewActiveTabOnDismiss;

@property (nonatomic, copy) NSArray *bookmarks;
@property (nonatomic) FLEXSwitcherMode mode;
@property (nonatomic) UISegmentedControl *modeControl;

@property (nonatomic, readonly) FLEXExplorerViewController *corePresenter;
@end

@implementation FLEXTabsViewController

#pragma mark - Initialization

- (id)init {
    return [self initWithStyle:UITableViewStylePlain];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationController.hidesBarsOnSwipe = NO;
    self.tableView.allowsMultipleSelectionDuringEditing = YES;

    self.modeControl = [[UISegmentedControl alloc] initWithItems:@[@"Tabs", @"Bookmarks"]];
    self.modeControl.selectedSegmentIndex = FLEXSwitcherModeTabs;
    [self.modeControl addTarget:self action:@selector(modeChanged:)
              forControlEvents:UIControlEventValueChanged];

    [self reloadData:NO];
    [self updateTitle];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setupDefaultBarItems];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    // Update the active tab snapshot after presenting to avoid pre-presentation latency
    dispatch_async(dispatch_get_main_queue(), ^{
        [FLEXTabList.sharedList updateSnapshotForActiveTab];
        [self reloadData:NO];
        [self.tableView reloadData];
    });
}


#pragma mark - Private

- (void)updateTitle {
    self.title = (self.mode == FLEXSwitcherModeTabs) ? @"Tabs" : @"Bookmarks";
}

- (NSInteger)currentListCount {
    return (self.mode == FLEXSwitcherModeTabs) ? self.openTabs.count : self.bookmarks.count;
}

/// @param trackActiveTabDelta whether to check if the active
/// tab changed and needs to be presented upon "Done" dismissal.
/// @return whether the active tab changed or not (if there are any tabs left)
- (BOOL)reloadData:(BOOL)trackActiveTabDelta {
    BOOL activeTabDidChange = NO;
    FLEXTabList *list = FLEXTabList.sharedList;

    if (trackActiveTabDelta) {
        NSInteger oldActiveIndex = self.activeIndex;
        if (oldActiveIndex != list.activeTabIndex && list.activeTabIndex != NSNotFound) {
            self.presentNewActiveTabOnDismiss = YES;
            activeTabDidChange = YES;
        } else if (self.presentNewActiveTabOnDismiss) {
            self.presentNewActiveTabOnDismiss = NO;
        }
    }

    self.openTabs = list.openTabs;
    self.tabSnapshots = list.openTabSnapshots;
    self.activeIndex = list.activeTabIndex;
    self.bookmarks = FLEXBookmarkManager.bookmarks;

    return activeTabDidChange;
}

- (void)reloadActiveTabRowIfChanged:(BOOL)activeTabChanged {
    if (activeTabChanged) {
        NSIndexPath *active = [NSIndexPath indexPathForRow:self.activeIndex inSection:0];
        [self.tableView reloadRowsAtIndexPaths:@[active] withRowAnimation:UITableViewRowAnimationNone];
    }
}

- (void)setupDefaultBarItems {
    self.navigationItem.rightBarButtonItem = FLEXBarButtonItemSystem(Done, self, @selector(dismissAnimated));

    UIBarButtonItem *segment = [[UIBarButtonItem alloc] initWithCustomView:self.modeControl];
    UIBarButtonItem *add = FLEXBarButtonItemSystem(Add, self, @selector(addTabButtonPressed:));
    UIBarButtonItem *edit = FLEXBarButtonItemSystem(Edit, self, @selector(toggleEditing));

    // New Tab only applies to the Tabs segment
    add.enabled = (self.mode == FLEXSwitcherModeTabs);
    // Disable editing if the current list is empty
    edit.enabled = [self currentListCount] > 0;

    self.toolbarItems = @[
        add,
        UIBarButtonItem.flex_flexibleSpace,
        segment,
        UIBarButtonItem.flex_flexibleSpace,
        edit,
    ];
}

- (void)setupEditingBarItems {
    self.navigationItem.rightBarButtonItem = nil;
    NSString *clearTitle = (self.mode == FLEXSwitcherModeTabs) ? @"Close All" : @"Remove All";
    self.toolbarItems = @[
        [UIBarButtonItem flex_itemWithTitle:clearTitle target:self action:@selector(closeAllButtonPressed:)],
        UIBarButtonItem.flex_flexibleSpace,
        // Non-system done item because we change its title dynamically
        [UIBarButtonItem flex_doneStyleitemWithTitle:@"Done" target:self action:@selector(toggleEditing)]
    ];

    self.toolbarItems.firstObject.tintColor = FLEXColor.destructiveColor;
}

- (FLEXExplorerViewController *)corePresenter {
    FLEXExplorerViewController *presenter = (id)self.presentingViewController;
    presenter = (id)presenter.presentingViewController ?: presenter;
    NSAssert(
        [presenter isKindOfClass:[FLEXExplorerViewController class]],
        @"The tabs view controller expects to be presented by the explorer controller"
    );
    return presenter;
}

- (void)openBookmark:(id)selectedObject {
    UIViewController *explorer = [FLEXObjectExplorerFactory explorerViewControllerForObject:selectedObject];
    if ([self.presentingViewController isKindOfClass:[FLEXNavigationController class]]) {
        // Presented on an existing navigation stack: dismiss myself and push there
        UINavigationController *presenter = (id)self.presentingViewController;
        [presenter dismissViewControllerAnimated:YES completion:^{
            [presenter pushViewController:explorer animated:YES];
        }];
    } else {
        // Dismiss myself and present the explorer as a new tab
        UIViewController *presenter = self.corePresenter;
        [presenter dismissViewControllerAnimated:YES completion:^{
            [presenter presentViewController:[FLEXNavigationController
                withRootViewController:explorer
            ] animated:YES completion:nil];
        }];
    }
}


#pragma mark Button Actions

- (void)modeChanged:(UISegmentedControl *)sender {
    if (self.editing) {
        self.editing = NO; // exit editing to avoid cross-mode selection state
    }
    self.mode = sender.selectedSegmentIndex;
    [self reloadData:NO];
    [self.tableView reloadData];
    [self setupDefaultBarItems];
    [self updateTitle];
}

- (void)dismissAnimated {
    if (self.presentNewActiveTabOnDismiss) {
        // The active tab was closed so we need to present the new one
        UIViewController *activeTab = FLEXTabList.sharedList.activeTab;
        FLEXExplorerViewController *presenter = self.corePresenter;
        [presenter dismissViewControllerAnimated:YES completion:^{
            [presenter presentViewController:activeTab animated:YES completion:nil];
        }];
    } else if (self.activeIndex == NSNotFound) {
        // The only tab was closed, so dismiss everything
        [self.corePresenter dismissViewControllerAnimated:YES completion:nil];
    } else {
        // Simple dismiss, only dismiss myself
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)toggleEditing {
    NSArray<NSIndexPath *> *selected = self.tableView.indexPathsForSelectedRows;
    self.editing = !self.editing;

    if (self.isEditing) {
        [self setupEditingBarItems];
    } else {
        [self setupDefaultBarItems];

        NSMutableIndexSet *indexes = [NSMutableIndexSet new];
        for (NSIndexPath *ip in selected) {
            [indexes addIndex:ip.row];
        }

        if (selected.count) {
            if (self.mode == FLEXSwitcherModeTabs) {
                [FLEXTabList.sharedList closeTabsAtIndexes:indexes];
                BOOL activeTabChanged = [self reloadData:YES];
                [self.tableView deleteRowsAtIndexPaths:selected withRowAnimation:UITableViewRowAnimationAutomatic];
                [self reloadActiveTabRowIfChanged:activeTabChanged];
            } else {
                [FLEXBookmarkManager.bookmarks removeObjectsAtIndexes:indexes];
                [self reloadData:NO];
                [self.tableView deleteRowsAtIndexPaths:selected withRowAnimation:UITableViewRowAnimationAutomatic];
            }
        }
    }
}

- (void)addTabButtonPressed:(UIBarButtonItem *)sender {
    // New tabs always start at the Main Menu; bookmarks are one segment away.
    [self addTabAndDismiss:[FLEXNavigationController
        withRootViewController:[FLEXGlobalsViewController new]
    ]];
}

- (void)addTabAndDismiss:(UINavigationController *)newTab {
    FLEXExplorerViewController *presenter = self.corePresenter;
    [presenter dismissViewControllerAnimated:YES completion:^{
        [presenter presentViewController:newTab animated:YES completion:nil];
    }];
}

- (void)closeAllButtonPressed:(UIBarButtonItem *)sender {
    [FLEXAlert makeSheet:^(FLEXAlert *make) {
        NSInteger count = [self currentListCount];
        NSString *title = (self.mode == FLEXSwitcherModeTabs)
            ? FLEXPluralFormatString(count, @"Close %@ tabs", @"Close %@ tab")
            : FLEXPluralFormatString(count, @"Remove %@ bookmarks", @"Remove %@ bookmark");
        make.button(title).destructiveStyle().handler(^(NSArray<NSString *> *strings) {
            [self closeAll];
            [self toggleEditing];
        });
        make.button(@"Cancel").cancelStyle();
    } showFrom:self source:sender];
}

- (void)closeAll {
    NSInteger rowCount = [self currentListCount];

    if (self.mode == FLEXSwitcherModeTabs) {
        [FLEXTabList.sharedList closeAllTabs];
        [self reloadData:YES];
    } else {
        [FLEXBookmarkManager.bookmarks removeAllObjects];
        [self reloadData:NO];
    }

    NSArray<NSIndexPath *> *allRows = [NSArray flex_forEachUpTo:rowCount map:^id(NSUInteger row) {
        return [NSIndexPath indexPathForRow:row inSection:0];
    }];
    [self.tableView deleteRowsAtIndexPaths:allRows withRowAnimation:UITableViewRowAnimationAutomatic];
}


#pragma mark - Table View Data Source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self currentListCount];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kFLEXDetailCell forIndexPath:indexPath];

    if (self.mode == FLEXSwitcherModeTabs) {
        UINavigationController *tab = self.openTabs[indexPath.row];
        cell.imageView.image = self.tabSnapshots[indexPath.row];
        cell.textLabel.text = tab.topViewController.title;
        cell.detailTextLabel.text = FLEXPluralString(tab.viewControllers.count, @"pages", @"page");
        cell.textLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        cell.textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
        cell.detailTextLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
        cell.backgroundColor = (indexPath.row == self.activeIndex)
            ? FLEXColor.secondaryBackgroundColor : FLEXColor.primaryBackgroundColor;
    } else {
        id object = self.bookmarks[indexPath.row];
        cell.imageView.image = nil;
        cell.textLabel.text = [FLEXRuntimeUtility safeDescriptionForObject:object];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ — %p", [object class], object];
        cell.textLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        cell.textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
        cell.detailTextLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
        cell.backgroundColor = FLEXColor.primaryBackgroundColor;
    }

    return cell;
}


#pragma mark - Table View Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.editing) {
        self.toolbarItems.lastObject.title = (self.mode == FLEXSwitcherModeTabs) ? @"Close Selected" : @"Remove Selected";
        self.toolbarItems.lastObject.tintColor = FLEXColor.destructiveColor;
        return;
    }

    if (self.mode == FLEXSwitcherModeTabs) {
        if (self.activeIndex == indexPath.row && self.corePresenter != self.presentingViewController) {
            [self dismissAnimated];
        } else {
            FLEXTabList.sharedList.activeTabIndex = indexPath.row;
            self.presentNewActiveTabOnDismiss = YES;
            [self dismissAnimated];
        }
    } else {
        [self openBookmark:self.bookmarks[indexPath.row]];
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSParameterAssert(self.editing);

    if (tableView.indexPathsForSelectedRows.count == 0) {
        self.toolbarItems.lastObject.title = @"Done";
        self.toolbarItems.lastObject.tintColor = self.view.tintColor;
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)table
commitEditingStyle:(UITableViewCellEditingStyle)edit
forRowAtIndexPath:(NSIndexPath *)indexPath {
    NSParameterAssert(edit == UITableViewCellEditingStyleDelete);

    if (self.mode == FLEXSwitcherModeTabs) {
        [FLEXTabList.sharedList closeTab:self.openTabs[indexPath.row]];
        BOOL activeTabChanged = [self reloadData:YES];
        [table deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self reloadActiveTabRowIfChanged:activeTabChanged];
    } else {
        [FLEXBookmarkManager.bookmarks removeObjectAtIndex:indexPath.row];
        [self reloadData:NO];
        [table deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

@end
```

- [ ] **Step 2: Build**

Run the framework build. Expected: `** BUILD SUCCEEDED **`. (`FLEXBookmarksViewController.h` is no longer imported here — that's intended; it's retired in Task 5.)

- [ ] **Step 3: Commit**

```bash
git add Classes/ExplorerInterface/Tabs/FLEXTabsViewController.m
git commit -m "Switcher: fold bookmarks into a Tabs|Bookmarks segmented switcher"
```

---

## Task 4: Consolidate the toolbar entry points

**Files:**
- Modify: `Classes/Toolbar/FLEXExplorerToolbar.m` (recentItem icon/title, ~lines 102-103)
- Modify: `Classes/ExplorerInterface/FLEXExplorerViewController.m` (recent handler, long-press gesture + handler, recentItem.enabled)
- Modify: `Classes/Core/Controllers/FLEXTableViewController.h` (remove `bookmarksToolbarItem` property)
- Modify: `Classes/Core/Controllers/FLEXTableViewController.m` (remove bookmarks item + `showBookmarks`; SF-Symbol the tabs item)

- [ ] **Step 1: Floating toolbar — turn the Recent button into the Tabs button**

In `FLEXExplorerToolbar.m` (~lines 102-103), change:
```objc
        self.recentItem    = [FLEXExplorerToolbarItem itemWithTitle:@"Recent" image:
            [UIImage systemImageNamed:@"clock.arrow.circlepath" withConfiguration:symbolConfig]];
```
to:
```objc
        // Formerly "Recent" (resumed the active tab). Now opens the tab/bookmark switcher.
        self.recentItem    = [FLEXExplorerToolbarItem itemWithTitle:@"Tabs" image:
            [UIImage systemImageNamed:@"square.on.square" withConfiguration:symbolConfig]];
```
(The property/ivar name `recentItem` is intentionally kept to avoid touching the stash "sibling" plumbing; only its icon, title, and behavior change.)

- [ ] **Step 2: Floating toolbar handler — open the switcher instead of resuming**

In `FLEXExplorerViewController.m`, replace `recentButtonTapped:` (~line 511):
```objc
- (void)recentButtonTapped:(FLEXExplorerToolbarItem *)sender {
    NSAssert(FLEXTabList.sharedList.activeTab, @"Must have active tab");
    [self presentViewController:FLEXTabList.sharedList.activeTab animated:YES completion:nil];
}
```
with:
```objc
- (void)recentButtonTapped:(FLEXExplorerToolbarItem *)sender {
    // Opens the tab/bookmark switcher (formerly resumed the active tab).
    [self presentViewController:[[UINavigationController alloc]
        initWithRootViewController:[FLEXTabsViewController new]
    ] animated:YES completion:nil];
}
```

- [ ] **Step 3: Delete the hidden long-press gesture and its handler**

In `FLEXExplorerViewController.m`, remove the gesture attachment (~lines 582-585):
```objc
    // Long press gesture to present tabs manager
    [toolbar.globalsItem addGestureRecognizer:[[UILongPressGestureRecognizer alloc]
        initWithTarget:self action:@selector(handleToolbarShowTabsGesture:)
    ]];
```
and remove the handler method (~lines 991-998):
```objc
- (void)handleToolbarShowTabsGesture:(UILongPressGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        // Don't use FLEXNavigationController because the tab viewer itself is not a tab
        [super presentViewController:[[UINavigationController alloc]
            initWithRootViewController:[FLEXTabsViewController new]
        ] animated:YES completion:nil];
    }
}
```

- [ ] **Step 4: Keep the Tabs button always enabled**

In `FLEXExplorerViewController.m`, find the `recentItem.enabled` assignments (~lines 541-543), currently:
```objc
        toolbar.recentItem.enabled = FLEXTabList.sharedList.activeTab != nil;
```
…(in the other branch)…
```objc
        toolbar.recentItem.enabled = NO;
```
Set both to `YES` (the switcher is always reachable — it can open a new tab or show bookmarks even with no active tab):
```objc
        toolbar.recentItem.enabled = YES;
```
(Apply to both the if and else branches that set `recentItem.enabled`.)

- [ ] **Step 5: In-explorer bottom toolbar — drop Bookmarks, SF-Symbol the Tabs button**

In `FLEXTableViewController.m`, the items are created (~lines 221-226):
```objc
    _bookmarksToolbarItem = [UIBarButtonItem
        flex_itemWithImage:FLEXResources.bookmarksIcon target:self action:@selector(showBookmarks)
    ];
    _openTabsToolbarItem = [UIBarButtonItem
        flex_itemWithImage:FLEXResources.openTabsIcon target:self action:@selector(showTabSwitcher)
    ];
```
Replace with (remove bookmarks; SF Symbol for tabs):
```objc
    _openTabsToolbarItem = [UIBarButtonItem
        flex_itemWithImage:[UIImage systemImageNamed:@"square.on.square"] target:self action:@selector(showTabSwitcher)
    ];
```

In `setupToolbarItems` (~lines 316-354), remove `self.bookmarksToolbarItem,` from **both** the iOS 26 array and the pre-26 array. In the pre-26 array also remove the now-redundant `UIBarButtonItem.flex_flexibleSpace,` that preceded the bookmarks item, so spacing stays balanced. After the change the iOS 26 array ends `…, self.middleToolbarItem, self.openTabsToolbarItem,` and the pre-26 array ends `…, self.middleToolbarItem, UIBarButtonItem.flex_flexibleSpace, self.openTabsToolbarItem,`.

Remove the `showBookmarks` method (~lines 519-524):
```objc
- (void)showBookmarks {
    UINavigationController *nav = [[UINavigationController alloc]
        initWithRootViewController:[FLEXBookmarksViewController new]
    ];
    [self presentViewController:nav animated:YES completion:nil];
}
```
Remove the `#import "FLEXBookmarksViewController.h"` from this file.

In `FLEXTableViewController.h`, remove the `bookmarksToolbarItem` property declaration (search for `bookmarksToolbarItem`).

- [ ] **Step 6: Build**

Run the framework build. Expected: `** BUILD SUCCEEDED **`. (`FLEXResources.openTabsIcon`/`bookmarksIcon` are now unused — they're retired in Task 5.)

- [ ] **Step 7: Commit**

```bash
git add Classes/Toolbar/FLEXExplorerToolbar.m \
        Classes/ExplorerInterface/FLEXExplorerViewController.m \
        Classes/Core/Controllers/FLEXTableViewController.h \
        Classes/Core/Controllers/FLEXTableViewController.m
git commit -m "Toolbars: one Tabs button to the switcher; remove Recent resume, long-press, and the bookmarks button"
```

---

## Task 5: Retire FLEXBookmarksViewController and the PNG icons

**Files:**
- Delete: `Classes/ExplorerInterface/Bookmarks/FLEXBookmarksViewController.h` and `.m`
- Modify: `FLEX.xcodeproj/project.pbxproj` (remove the deleted files' references)
- Modify: `Classes/Utility/FLEXResources.h` and `.m` (remove `bookmarksIcon`/`openTabsIcon` + byte arrays)

- [ ] **Step 1: Confirm there are no remaining references**

```bash
grep -rn "FLEXBookmarksViewController" Classes
```
Expected: no matches (Tasks 3 and 4 removed the two callers). If any remain, remove them before continuing.

- [ ] **Step 2: Delete the files and remove them from the Xcode project**

```bash
rm Classes/ExplorerInterface/Bookmarks/FLEXBookmarksViewController.h \
   Classes/ExplorerInterface/Bookmarks/FLEXBookmarksViewController.m

ruby -e '
require "xcodeproj"
project = Xcodeproj::Project.open("FLEX.xcodeproj")
project.files.select { |f| f.path && f.path.include?("FLEXBookmarksViewController") }.each do |ref|
  ref.build_files.each { |bf| bf.remove_from_project }
  ref.remove_from_project
end
project.save
puts "removed FLEXBookmarksViewController references"
'
```
(SPM auto-globs `Classes/`, so deleting the files is enough for the SPM build; the ruby step keeps the Xcode project consistent.)

- [ ] **Step 3: Retire the icon accessors**

In `FLEXResources.h`, remove the two declarations (~lines 54-55):
```objc
@property (readonly, class) UIImage *bookmarksIcon;
@property (readonly, class) UIImage *openTabsIcon;
```

In `FLEXResources.m`, remove the two method implementations (~lines 8768-8775):
```objc
+ (UIImage *)bookmarksIcon {
    return FLEXImage(FLEXBookmarksIcon);
}
+ (UIImage *)openTabsIcon {
    return FLEXImage(FLEXOpenTabsIcon);
}
```
Then remove the now-unused embedded byte arrays. Search for each of these identifiers and delete its `static ... [] = { ... };` definition (and any matching `1x`/`2x`/`3x` variants):
`FLEXBookmarksIcon2x`, `FLEXBookmarksIcon3x`, `FLEXOpenTabsIcon2x`, `FLEXOpenTabsIcon3x`.
The compiler will flag any lingering reference; if removing a byte array proves error-prone, it is acceptable to leave the unused arrays in place for a follow-up — the functional requirement is that the accessors are gone. Note in the commit if any arrays were left.

- [ ] **Step 4: Build framework + example app**

```bash
xcodebuild build -project FLEX.xcodeproj -scheme FLEX -destination 'generic/platform=iOS Simulator' -configuration Debug 2>&1 | grep -E "BUILD SUCCEEDED|BUILD FAILED|error:"
xcodebuild build -project Example/FLEXample.xcodeproj -scheme FLEXample -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -configuration Debug 2>&1 | grep -E "^\*\* BUILD (SUCCEEDED|FAILED)|: error:"
```
Both expected: `** BUILD SUCCEEDED **`. (The example build proves the SPM path is clean after the file deletions.)

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "Retire standalone bookmarks screen and the tabs/bookmarks PNG icons"
```

---

## Task 6: Full verification, manual smoke, and docs

**Files:**
- Modify: `docs/superpowers/specs/2026-06-08-tabs-bookmarks-redesign-design.md` (optional: mark shipped)

- [ ] **Step 1: Full test suite**

```bash
xcodebuild test -project FLEX.xcodeproj -scheme FLEXTests -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -10
```
Expected: `** TEST SUCCEEDED **` (existing tests + the new `FLEXBookmarkManagerTests`).

- [ ] **Step 2: Manual smoke in FLEXample**

Build & run `FLEXample`, open FLEX, and verify:
1. **Lifecycle:** open the menu (a tab), press **Done** → returns to the app, tab still open. Reopen via the floating toolbar's **Tabs** button (`square.on.square`) → switcher → tap the tab to resume. Swipe-down to dismiss also keeps the tab.
2. **One entry point:** long-pressing the menu button does **nothing** now; the floating-toolbar Tabs button and the in-explorer bottom Tabs button both open the same switcher.
3. **Switcher:** the bottom toolbar shows `[ + ]  [ Tabs | Bookmarks ]  [ Edit ]`. `+` opens a new Main-Menu tab (only on the Tabs segment). Switching to **Bookmarks** shows saved objects; tapping one opens it; Edit/swipe removes them; `+` is disabled.
4. **Bookmark toggle:** on an object explorer, the nav-bar ribbon shows outline; tap → fills; the object now appears under the switcher's Bookmarks segment; tap again → outline and it's removed. Share sheet no longer has "Add to Bookmarks".

Record the result of each step.

- [ ] **Step 3: Commit any doc update**

```bash
git add -A
git commit -m "Verify tabs/bookmarks redesign end-to-end"
```

---

## Self-review notes (author)

- **Spec coverage:** explicit tabs lifecycle = Task 1; bookmark toggle + manager helpers = Task 2; segmented switcher with folded-in bookmarks + simplified `+` = Task 3; one Tabs button / remove Recent + long-press / remove bottom bookmarks button + SF Symbol = Task 4; retire standalone bookmarks screen + PNG icons = Task 5; verification = Task 6. All spec sections map to a task.
- **Naming consistency:** `FLEXBookmarkManager` API (`isObjectBookmarked:`, `addBookmark:`, `removeBookmark:`) is defined in Task 2 and reused by the toggle; `FLEXSwitcherMode`, `mode`, `currentListCount`, `modeControl`, `openBookmark:` are introduced and used consistently within Task 3; `recentItem`/`recentButtonTapped:` are deliberately kept (icon/behavior change only) and referenced consistently in Task 4.
- **Known verification points (flagged inline, not placeholders):** object-explorer nav-bar toggle coexisting with the injected Done item (Task 2 Step 6); exact pre-26 toolbar array spacing (Task 4 Step 5); whether any embedded byte array is awkward to remove (Task 5 Step 3). Each has a concrete fallback.
