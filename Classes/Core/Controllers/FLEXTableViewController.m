//
//  FLEXTableViewController.m
//
//  Copyright (c) Flipboard (2014-2016); FLEX Team (2020-2026).
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without modification,
//  are permitted provided that the following conditions are met:
//
//  * Redistributions of source code must retain the above copyright notice, this
//    list of conditions and the following disclaimer.
//
//  * Redistributions in binary form must reproduce the above copyright notice, this
//    list of conditions and the following disclaimer in the documentation and/or
//    other materials provided with the distribution.
//
//  * Neither the name of Flipboard nor the names of its
//    contributors may be used to endorse or promote products derived from
//    this software without specific prior written permission.
//
//  * You must NOT include this project in an application to be submitted
//    to the App Store™, as this project uses too many private APIs.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
//  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
//  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
//  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
//  ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import "FLEXTableViewController.h"
#import "FLEXExplorerViewController.h"
#import "FLEXBookmarksViewController.h"
#import "FLEXTabsViewController.h"
#import "FLEXScopeCarousel.h"
#import "FLEXTableView.h"
#import "FLEXUtility.h"
#import "FLEXResources.h"
#import "UIBarButtonItem+FLEX.h"
#import <objc/runtime.h>

CGFloat const kFLEXDebounceInstant = 0.f;
CGFloat const kFLEXDebounceFast = 0.05;
CGFloat const kFLEXDebounceForAsyncSearch = 0.15;
CGFloat const kFLEXDebounceForExpensiveIO = 0.5;

@interface FLEXTableViewController ()
@property (nonatomic) NSTimer *debounceTimer;
@property (nonatomic) BOOL didInitiallyRevealSearchBar;
@property (nonatomic) UITableViewStyle style;

@property (nonatomic) BOOL hasAppeared;

@property (nonatomic) UIBarButtonItem *middleToolbarItem;
@property (nonatomic) UIBarButtonItem *middleLeftToolbarItem;
@property (nonatomic) UIBarButtonItem *leftmostToolbarItem;
@end

@implementation FLEXTableViewController
@dynamic tableView;
@synthesize showsShareToolbarItem = _showsShareToolbarItem;
@synthesize automaticallyShowsSearchBarCancelButton = _automaticallyShowsSearchBarCancelButton;

#pragma mark - Initialization

- (id)init {
    return [self initWithStyle:UITableViewStyleInsetGrouped];
}

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];

    if (self) {
        _searchBarDebounceInterval = kFLEXDebounceFast;
        _showSearchBarInitially = YES;
        _style = style;

        // We will be our own search delegate if we implement this method
        if ([self respondsToSelector:@selector(updateSearchResults:)]) {
            self.searchDelegate = (id)self;
        }
    }

    return self;
}


#pragma mark - Public

- (FLEXWindow *)window {
    return (id)self.view.window;
}

- (void)setShowsSearchBar:(BOOL)showsSearchBar {
    if (_showsSearchBar == showsSearchBar) return;
    _showsSearchBar = showsSearchBar;

    if (showsSearchBar) {
        UIViewController *results = self.searchResultsController;
        self.searchController = [[UISearchController alloc] initWithSearchResultsController:results];
        self.searchController.searchBar.placeholder = @"Filter";
        self.searchController.searchResultsUpdater = (id)self;
        self.searchController.delegate = (id)self;
        self.searchController.obscuresBackgroundDuringPresentation = NO;
        self.searchController.hidesNavigationBarDuringPresentation = NO;
        self.searchController.searchBar.delegate = self;
        self.searchController.automaticallyShowsScopeBar = NO;

        self.automaticallyShowsSearchBarCancelButton = YES;

        [self addSearchController:self.searchController];
    } else {
        // Search already shown and just set to NO, so remove it
        [self removeSearchController:self.searchController];
    }
}

- (void)setShowsCarousel:(BOOL)showsCarousel {
    if (_showsCarousel == showsCarousel) return;
    _showsCarousel = showsCarousel;

    if (showsCarousel) {
        _carousel = ({ weakify(self)

            FLEXScopeCarousel *carousel = [FLEXScopeCarousel new];
            carousel.selectedIndexChangedAction = ^(NSInteger idx) { strongify(self);
                [self.searchDelegate updateSearchResults:self.searchText];
            };

            // UITableView won't update the header size unless you reset the header view
            [carousel registerBlockForDynamicTypeChanges:^(FLEXScopeCarousel *_) { strongify(self);
                [self layoutTableHeaderIfNeeded];
            }];

            carousel;
        });
        [self addCarousel:_carousel];
    } else {
        // Carousel already shown and just set to NO, so remove it
        [self removeCarousel:_carousel];
    }
}

- (NSInteger)selectedScope {
    if (self.searchController.searchBar.showsScopeBar) {
        return self.searchController.searchBar.selectedScopeButtonIndex;
    } else if (self.showsCarousel) {
        return self.carousel.selectedIndex;
    } else {
        return 0;
    }
}

- (void)setSelectedScope:(NSInteger)selectedScope {
    if (self.searchController.searchBar.showsScopeBar) {
        self.searchController.searchBar.selectedScopeButtonIndex = selectedScope;
    } else if (self.showsCarousel) {
        self.carousel.selectedIndex = selectedScope;
    }

    [self.searchDelegate updateSearchResults:self.searchText];
}

- (NSString *)searchText {
    return self.searchController.searchBar.text;
}

- (BOOL)automaticallyShowsSearchBarCancelButton {
    return self.searchController.automaticallyShowsCancelButton;
}

- (void)setAutomaticallyShowsSearchBarCancelButton:(BOOL)value {
    self.searchController.automaticallyShowsCancelButton = value;
    _automaticallyShowsSearchBarCancelButton = value;
}

- (void)onBackgroundQueue:(NSArray *(^)(void))backgroundBlock thenOnMainQueue:(void(^)(NSArray *))mainBlock {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray *items = backgroundBlock();
        dispatch_async(dispatch_get_main_queue(), ^{
            mainBlock(items);
        });
    });
}

- (void)setsShowsShareToolbarItem:(BOOL)showsShareToolbarItem {
    _showsShareToolbarItem = showsShareToolbarItem;
    if (self.isViewLoaded) {
        [self setupToolbarItems];
    }
}

- (void)disableToolbar {
    self.navigationController.toolbarHidden = YES;
    self.navigationController.hidesBarsOnSwipe = NO;
    self.toolbarItems = nil;
}


#pragma mark - View Controller Lifecycle

- (void)loadView {
    self.view = [FLEXTableView style:self.style];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;

    self.tableView.estimatedRowHeight = 44;
    self.tableView.estimatedSectionHeaderHeight = 0;
    self.tableView.estimatedSectionFooterHeight = 0;

    _shareToolbarItem = FLEXBarButtonItemSystem(Action, self, @selector(shareButtonPressed:));
    _bookmarksToolbarItem = [UIBarButtonItem
        flex_itemWithImage:FLEXResources.bookmarksIcon target:self action:@selector(showBookmarks)
    ];
    _openTabsToolbarItem = [UIBarButtonItem
        flex_itemWithImage:FLEXResources.openTabsIcon target:self action:@selector(showTabSwitcher)
    ];

    self.leftmostToolbarItem = UIBarButtonItem.flex_fixedSpace;
    self.middleLeftToolbarItem = UIBarButtonItem.flex_fixedSpace;
    self.middleToolbarItem = UIBarButtonItem.flex_fixedSpace;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;

    // Toolbar
    self.navigationController.toolbarHidden = self.toolbarItems.count > 0;
    self.navigationController.hidesBarsOnSwipe = YES;

    // The root view controller shows its search bar no matter what on iOS 13+.
    // Turning this off avoids a weird flash in the navigation bar when we
    // toggle navigationItem.hidesSearchBarWhenScrolling on and off.
    if (self.navigationController.viewControllers.firstObject == self) {
        _showSearchBarInitially = NO;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    // When going back, make the search bar reappear instead of hiding
    if ((self.pinSearchBar || self.showSearchBarInitially) && !self.didInitiallyRevealSearchBar) {
        self.navigationItem.hidesSearchBarWhenScrolling = NO;
    }

    // Make the keyboard seem to appear faster
    if (self.activatesSearchBarAutomatically) {
        [self makeKeyboardAppearNow];
    }

    [self setupToolbarItems];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    // Allow scrolling to collapse the search bar, only if we don't want it pinned
    if (self.showSearchBarInitially && !self.pinSearchBar && !self.didInitiallyRevealSearchBar) {
        self.navigationItem.hidesSearchBarWhenScrolling = YES;
    }

    if (self.activatesSearchBarAutomatically) {
        // Keyboard has appeared, now we call this as we soon present our search bar
        [self removeDummyTextField];

        // Activate the search bar
        dispatch_async(dispatch_get_main_queue(), ^{
            // This doesn't work unless it's wrapped in this dispatch_async call
            [self.searchController.searchBar becomeFirstResponder];
        });
    }

    // We only want to reveal the search bar when the view controller first appears.
    self.didInitiallyRevealSearchBar = YES;
}

- (void)didMoveToParentViewController:(UIViewController *)parent {
    [super didMoveToParentViewController:parent];
    // Reset this since we are re-appearing under a new
    // parent view controller and need to show it again
    self.didInitiallyRevealSearchBar = NO;
}


#pragma mark - Toolbar, Public

- (void)setupToolbarItems {
    if (!self.isViewLoaded) {
        return;
    }

    self.toolbarItems = @[
        self.leftmostToolbarItem,
        UIBarButtonItem.flex_flexibleSpace,
        self.middleLeftToolbarItem,
        UIBarButtonItem.flex_flexibleSpace,
        self.middleToolbarItem,
        UIBarButtonItem.flex_flexibleSpace,
        self.bookmarksToolbarItem,
        UIBarButtonItem.flex_flexibleSpace,
        self.openTabsToolbarItem,
    ];

    for (UIBarButtonItem *item in self.toolbarItems) {
        [item _setWidth:60];
        // This does not work for anything but fixed spaces for some reason
        // item.width = 60;
    }

    // Disable tabs entirely when not presented by FLEXExplorerViewController
    UIViewController *presenter = self.navigationController.presentingViewController;
    if (![presenter isKindOfClass:[FLEXExplorerViewController class]]) {
        self.openTabsToolbarItem.enabled = NO;
    }
}

- (void)addToolbarItems:(NSArray<UIBarButtonItem *> *)items {
    if (self.showsShareToolbarItem) {
        // Share button is in the middle, skip middle button
        if (items.count > 0) {
            self.middleLeftToolbarItem = items[0];
        }
        if (items.count > 1) {
            self.leftmostToolbarItem = items[1];
        }
    } else {
        // Add buttons right-to-left
        if (items.count > 0) {
            self.middleToolbarItem = items[0];
        }
        if (items.count > 1) {
            self.middleLeftToolbarItem = items[1];
        }
        if (items.count > 2) {
            self.leftmostToolbarItem = items[2];
        }
    }

    [self setupToolbarItems];
}

- (void)setShowsShareToolbarItem:(BOOL)showShare {
    if (_showsShareToolbarItem != showShare) {
        _showsShareToolbarItem = showShare;

        if (showShare) {
            // Push out leftmost item
            self.leftmostToolbarItem = self.middleLeftToolbarItem;
            self.middleLeftToolbarItem = self.middleToolbarItem;

            // Use share for middle
            self.middleToolbarItem = self.shareToolbarItem;
        } else {
            // Remove share, shift custom items rightward
            self.middleToolbarItem = self.middleLeftToolbarItem;
            self.middleLeftToolbarItem = self.leftmostToolbarItem;
            self.leftmostToolbarItem = UIBarButtonItem.flex_fixedSpace;
        }
    }

    [self setupToolbarItems];
}

- (void)shareButtonPressed:(UIBarButtonItem *)sender {

}


#pragma mark - Private

- (void)debounce:(void(^)(void))block {
    [self.debounceTimer invalidate];

    self.debounceTimer = [NSTimer
        scheduledTimerWithTimeInterval:self.searchBarDebounceInterval
        repeats:NO
        block:^(NSTimer *_) { block(); }
    ];
}

- (void)layoutTableHeaderIfNeeded {
    if (self.showsCarousel) {
        self.carousel.frame = FLEXRectSetHeight(
            self.carousel.frame, self.carousel.intrinsicContentSize.height
        );
    }

    self.tableView.tableHeaderView = self.tableView.tableHeaderView;
}

- (void)addCarousel:(FLEXScopeCarousel *)carousel {
    self.tableView.tableHeaderView = carousel;
    [self layoutTableHeaderIfNeeded];
}

- (void)removeCarousel:(FLEXScopeCarousel *)carousel {
    [carousel removeFromSuperview];
    self.tableView.tableHeaderView = nil;
}

- (void)addSearchController:(UISearchController *)controller {
    self.navigationItem.searchController = controller;
}

- (void)removeSearchController:(UISearchController *)controller {
    self.navigationItem.searchController = nil;
}

- (void)showBookmarks {
    UINavigationController *nav = [[UINavigationController alloc]
        initWithRootViewController:[FLEXBookmarksViewController new]
    ];
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)showTabSwitcher {
    UINavigationController *nav = [[UINavigationController alloc]
        initWithRootViewController:[FLEXTabsViewController new]
    ];
    [self presentViewController:nav animated:YES completion:nil];
}


#pragma mark - Search Bar

#pragma mark Faster keyboard

static UITextField *kDummyTextField = nil;

/// Make the keyboard appear instantly. We use this to make the
/// keyboard appear faster when the search bar is set to appear initially.
/// You must call \c -removeDummyTextField before your search bar is to appear.
- (void)makeKeyboardAppearNow {
    if (!kDummyTextField) {
        kDummyTextField = [UITextField new];
        kDummyTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    }

    kDummyTextField.inputAccessoryView = self.searchController.searchBar.inputAccessoryView;
    [self.view.window addSubview:kDummyTextField];
    [kDummyTextField becomeFirstResponder];
}

- (void)removeDummyTextField {
    if (kDummyTextField.superview) {
        [kDummyTextField removeFromSuperview];
    }
}

#pragma mark UISearchResultsUpdating

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    [self.debounceTimer invalidate];
    NSString *text = searchController.searchBar.text;

    void (^updateSearchResults)(void) = ^{
        if (self.searchResultsUpdater) {
            [self.searchResultsUpdater updateSearchResults:text];
        } else {
            [self.searchDelegate updateSearchResults:text];
        }
    };

    // Only debounce if we want to, and if we have a non-empty string
    // Empty string events are sent instantly
    if (text.length && self.searchBarDebounceInterval > kFLEXDebounceInstant) {
        [self debounce:updateSearchResults];
    } else {
        updateSearchResults();
    }
}


#pragma mark UISearchControllerDelegate

- (void)willPresentSearchController:(UISearchController *)searchController { }

- (void)willDismissSearchController:(UISearchController *)searchController { }


#pragma mark UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope {
    [self updateSearchResultsForSearchController:self.searchController];
}


#pragma mark Table View

/// Not having a title in the first section looks weird with a rounded-corner table view style
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (self.style == UITableViewStyleInsetGrouped) {
        return @" ";
    }

    return nil;
}

@end
