//
//  FLEXHierarchyViewController.m
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

#import "FLEXHierarchyViewController.h"
#import "FLEXHierarchyTableViewController.h"
#import "FHSViewController.h"
#import "FLEXUtility.h"
#import "FLEXTabList.h"
#import "FLEXResources.h"
#import "UIBarButtonItem+FLEX.h"

typedef NS_ENUM(NSUInteger, FLEXHierarchyViewMode) {
    FLEXHierarchyViewModeTree = 1,
    FLEXHierarchyViewMode3DSnapshot
};

@interface FLEXHierarchyViewController ()
@property (nonatomic, readonly, weak) id<FLEXHierarchyDelegate> hierarchyDelegate;
@property (nonatomic, readonly) FHSViewController *snapshotViewController;
@property (nonatomic, readonly) FLEXHierarchyTableViewController *treeViewController;

@property (nonatomic) FLEXHierarchyViewMode mode;

@property (nonatomic, readonly) UIView *selectedView;
@end

@implementation FLEXHierarchyViewController

#pragma mark - Initialization

+ (instancetype)delegate:(id<FLEXHierarchyDelegate>)delegate {
    return [self delegate:delegate viewsAtTap:nil selectedView:nil];
}

+ (instancetype)delegate:(id<FLEXHierarchyDelegate>)delegate
              viewsAtTap:(NSArray<UIView *> *)viewsAtTap
            selectedView:(UIView *)selectedView {
    return [[self alloc] initWithDelegate:delegate viewsAtTap:viewsAtTap selectedView:selectedView];
}

- (id)initWithDelegate:(id)delegate viewsAtTap:(NSArray<UIView *> *)viewsAtTap selectedView:(UIView *)view {
    self = [super init];
    if (self) {
        NSArray<UIWindow *> *allWindows = FLEXUtility.allWindows;
        _hierarchyDelegate = delegate;
        _treeViewController = [FLEXHierarchyTableViewController
            windows:allWindows viewsAtTap:viewsAtTap selectedView:view
        ];

        if (viewsAtTap) {
            _snapshotViewController = [FHSViewController snapshotViewsAtTap:viewsAtTap selectedView:view];
        } else {
            _snapshotViewController = [FHSViewController snapshotWindows:allWindows];
        }

        self.modalPresentationStyle = UIModalPresentationFullScreen;
    }

    return self;
}


#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    // 3D toggle button
    self.treeViewController.navigationItem.leftBarButtonItem = [UIBarButtonItem
        flex_itemWithImage:FLEXResources.toggle3DIcon target:self action:@selector(toggleHierarchyMode)
    ];

    // Dismiss when tree view row is selected
    __weak id<FLEXHierarchyDelegate> delegate = self.hierarchyDelegate;
    self.treeViewController.didSelectRowAction = ^(UIView *selectedView) {
        [delegate viewHierarchyDidDismiss:selectedView];
    };

    // Start of in tree view
    _mode = FLEXHierarchyViewModeTree;
    [self pushViewController:self.treeViewController animated:NO];
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    // Done button: manually added here because the hierarhcy screens need to actually pass
    // data back to the explorer view controller so that it can highlight selected views
    viewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(donePressed)
    ];

    [super pushViewController:viewController animated:animated];
}


#pragma mark - Private

- (void)donePressed {
    // We need to manually close ourselves here because
    // FLEXNavigationController doesn't ever close tabs itself 
    [FLEXTabList.sharedList closeTab:self];
    [self.hierarchyDelegate viewHierarchyDidDismiss:self.selectedView];
}

- (void)toggleHierarchyMode {
    switch (self.mode) {
        case FLEXHierarchyViewModeTree:
            self.mode = FLEXHierarchyViewMode3DSnapshot;
            break;
        case FLEXHierarchyViewMode3DSnapshot:
            self.mode = FLEXHierarchyViewModeTree;
            break;
    }
}

- (void)setMode:(FLEXHierarchyViewMode)mode {
    if (mode != _mode) {
        // The tree view controller is our top stack view controller, and
        // changing the mode simply pushes the snapshot view. In the future,
        // I would like to have the 3D toggle button transparently switch
        // between two views instead of pushing a new view controller.
        // This way the views should share the search controller somehow.
        switch (mode) {
            case FLEXHierarchyViewModeTree:
                [self popViewControllerAnimated:NO];
                self.toolbarHidden = YES;
                self.treeViewController.selectedView = self.selectedView;
                break;
            case FLEXHierarchyViewMode3DSnapshot:
                [self pushViewController:self.snapshotViewController animated:NO];
                self.toolbarHidden = NO;
                self.snapshotViewController.selectedView = self.selectedView;
                break;
        }

        // Change this last so that self.selectedView works right above
        _mode = mode;
    }
}

- (UIView *)selectedView {
    switch (self.mode) {
        case FLEXHierarchyViewModeTree:
            return self.treeViewController.selectedView;
        case FLEXHierarchyViewMode3DSnapshot:
            return self.snapshotViewController.selectedView;
    }
}

@end
