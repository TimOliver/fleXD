//
//  FLEXExplorerViewController.m
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

#import "FLEXExplorerViewController.h"
#import "FLEXExplorerToolbarItem.h"
#import "FLEXUtility.h"
#import "FLEXWindow.h"
#import "FLEXTabList.h"
#import "FLEXNavigationController.h"
#import "FLEXHierarchyViewController.h"
#import "FLEXGlobalsViewController.h"
#import "FLEXObjectExplorerViewController.h"
#import "FLEXObjectExplorerFactory.h"
#import "FLEXNetworkMITMViewController.h"
#import "FLEXTabsViewController.h"
#import "FLEXWindowManagerController.h"
#import "FLEXViewControllersViewController.h"
#import "NSUserDefaults+FLEX.h"
#import "FLEXToolbarStashMath.h"

typedef NS_ENUM(NSUInteger, FLEXExplorerMode) {
    FLEXExplorerModeDefault,
    FLEXExplorerModeSelect,
    FLEXExplorerModeMove
};

@interface FLEXExplorerViewController () <FLEXHierarchyDelegate, UIAdaptivePresentationControllerDelegate, UIGestureRecognizerDelegate>

/// Tracks the currently active tool/mode
@property (nonatomic) FLEXExplorerMode currentMode;

/// Gesture recognizer for dragging a view in move mode
@property (nonatomic) UIPanGestureRecognizer *movePanGR;

/// Gesture recognizer for showing additional details on the selected view
@property (nonatomic) UITapGestureRecognizer *detailsTapGR;
/// Gesture recognizer for dragging the explorer toolbar.
@property (nonatomic) UIPanGestureRecognizer *toolbarPanGR;
/// Gesture recognizer for restoring the toolbar when it's stashed against an edge.
@property (nonatomic) UITapGestureRecognizer *toolbarUnstashTapGR;

/// The edge the toolbar is currently stashed against, if any.
@property (nonatomic) FLEXToolbarStashEdge toolbarStashEdge;
/// Gesture recognizer for cycling through views under the selection point.
@property (nonatomic) UIPanGestureRecognizer *changeSelectedViewPanGR;

/// Only valid while a move pan gesture is in progress.
@property (nonatomic) CGRect selectedViewFrameBeforeDragging;

/// The touch offset from the toolbar's center when drag begins.
@property (nonatomic) UIOffset toolbarDragOffset;

/// UIKit Dynamics animator for toolbar momentum after release.
@property (nonatomic) UIDynamicAnimator *toolbarAnimator;

/// The in-flight stash/restore spring, retained so a new touch can interrupt it.
@property (nonatomic, nullable) UIViewPropertyAnimator *toolbarStashAnimator;

/// YES while a toolbar drag is in progress, so the pill can be dragged off the
/// side edges (drag-to-stash) without being clamped back on-screen.
@property (nonatomic) BOOL toolbarDraggingPastEdge;

/// Only valid while a selected view pan gesture is in progress.
@property (nonatomic) CGFloat selectedViewLastPanX;

/// Borders of all the visible views in the hierarchy at the selection point.
/// The keys are NSValues with the corresponding view (nonretained).
@property (nonatomic) NSDictionary<NSValue *, UIView *> *outlineViewsForVisibleViews;

/// The actual views at the selection point with the deepest view last.
@property (nonatomic) NSArray<UIView *> *viewsAtTapPoint;

/// Last tap point for detecting same-point re-taps to cycle through the view hierarchy.
@property (nonatomic) CGPoint lastTapPoint;

/// The view that we're currently highlighting with an overlay and displaying details for.
@property (nonatomic) UIView *selectedView;

/// A colored transparent overlay to indicate that the view is selected.
@property (nonatomic) UIView *selectedViewOverlay;

/// Used to actuate changes in view selection on iOS 10+
@property (nonatomic, readonly) UISelectionFeedbackGenerator *selectionFBG;

/// self.view.window as a \c FLEXWindow
@property (nonatomic, readonly) FLEXWindow *window;

/// All views that we're KVOing. Used to help us clean up properly.
@property (nonatomic) NSMutableSet<UIView *> *observedViews;


@end

@implementation FLEXExplorerViewController

static const CGFloat kToolbarSafeAreaPadding = 4.0;

/// Projected travel per (pt/s) of release velocity, matching the free-float
/// UIDynamics decay (~ 1/resistance, resistance = 6.0). Starting value, tuned by feel.
static const CGFloat kToolbarStashProjectionDeceleration = 1.0 / 6.0;
/// How close to an edge the projected center must land to commit to a stash (pt).
/// Starting value, tuned by feel.
static const CGFloat kToolbarStashEdgeBand = 44.0;

/// Clamp on the tuck spring's normalized initial velocity, so a tiny tuck distance
/// with a fast flick can't explode the spring. Starting value, tuned by feel.
static const CGFloat kToolbarStashMaxRelativeVelocity = 30.0;

/// Fraction of the pill that must be off an edge (dragged or projected) to commit a stash.
static const CGFloat kToolbarStashDragCommitFraction = 0.5;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.observedViews = [NSMutableSet new];
    }
    return self;
}

- (void)dealloc {
    for (UIView *view in _observedViews) {
        [self stopObservingView:view];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Toolbar
    _explorerToolbar = [FLEXExplorerToolbar new];

    const CGRect safeArea = [self viewSafeArea];
    const CGSize toolbarSize = [self.explorerToolbar sizeThatFits:CGSizeMake(
        CGRectGetWidth(safeArea), CGRectGetHeight(safeArea)
    )];

    // Restore persisted position, or center horizontally on first launch
    CGFloat toolbarOriginY = NSUserDefaults.standardUserDefaults.flex_toolbarTopMargin;
    CGFloat toolbarOriginX = NSUserDefaults.standardUserDefaults.flex_toolbarLeftMargin;
    if (toolbarOriginX < 0) {
        toolbarOriginX = CGRectGetMinX(safeArea) +
            FLEXFloor((CGRectGetWidth(safeArea) - toolbarSize.width) / 2.0);
    }

    // The toolbar always launches un-stashed and fully visible — a stashed
    // toolbar can't be closed, so we deliberately don't persist that state.
    [self updateToolbarPositionWithUnconstrainedFrame:CGRectMake(
        toolbarOriginX, toolbarOriginY, toolbarSize.width, toolbarSize.height
    )];
    self.explorerToolbar.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin |
                                            UIViewAutoresizingFlexibleTopMargin |
                                            UIViewAutoresizingFlexibleLeftMargin |
                                            UIViewAutoresizingFlexibleRightMargin;
    [self.view addSubview:self.explorerToolbar];
    [self setupToolbarActions];
    [self setupToolbarGestures];

    // Dynamics for toolbar momentum on release
    self.toolbarAnimator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];

    // View selection
    UITapGestureRecognizer *selectionTapGR = [[UITapGestureRecognizer alloc]
        initWithTarget:self action:@selector(handleSelectionTap:)
    ];
    [self.view addGestureRecognizer:selectionTapGR];

    // View moving
    self.movePanGR = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleMovePan:)];
    self.movePanGR.enabled = self.currentMode == FLEXExplorerModeMove;
    [self.view addGestureRecognizer:self.movePanGR];

    // Feedback
    _selectionFBG = [UISelectionFeedbackGenerator new];

    // Observe keyboard to move self out of the way
    [NSNotificationCenter.defaultCenter
        addObserver:self
        selector:@selector(keyboardShown:)
        name:UIKeyboardWillShowNotification
        object:nil
    ];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self updateButtonStates];
}


#pragma mark - Rotation

- (UIViewController *)viewControllerForRotationAndOrientation {
    UIViewController *viewController = FLEXUtility.appKeyWindow.rootViewController;
    // Obfuscating selector _viewControllerForSupportedInterfaceOrientations
    NSString *viewControllerSelectorString = [@[
        @"_vie", @"wContro", @"llerFor", @"Supported", @"Interface", @"Orientations"
    ] componentsJoinedByString:@""];
    SEL viewControllerSelector = NSSelectorFromString(viewControllerSelectorString);
    if ([viewController respondsToSelector:viewControllerSelector]) {
        viewController = [viewController valueForKey:viewControllerSelectorString];
    }

    return viewController;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    // Commenting this out until I can figure out a better way to solve this
//    if (self.window.isKeyWindow) {
//        [self.window resignKeyWindow];
//    }

    UIViewController *viewControllerToAsk = [self viewControllerForRotationAndOrientation];
    UIInterfaceOrientationMask supportedOrientations = FLEXUtility.infoPlistSupportedInterfaceOrientationsMask;
    // We check its class by name because using isKindOfClass will fail for the same class defined
    // twice in the runtime; and the goal here is to avoid calling -supportedInterfaceOrientations
    // recursively when I'm inspecting FLEX with itself from a tweak dylib
    if (viewControllerToAsk && ![NSStringFromClass([viewControllerToAsk class]) hasPrefix:@"FLEX"]) {
        supportedOrientations = [viewControllerToAsk supportedInterfaceOrientations];
    }

    // The UIViewController docs state that this method must not return zero.
    // If we weren't able to get a valid value for the supported interface
    // orientations, default to all supported.
    if (supportedOrientations == 0) {
        supportedOrientations = UIInterfaceOrientationMaskAll;
    }

    return supportedOrientations;
}

- (BOOL)shouldAutorotate {
    UIViewController *viewControllerToAsk = [self viewControllerForRotationAndOrientation];
    BOOL shouldAutorotate = YES;
    if (viewControllerToAsk && viewControllerToAsk != self) {
        shouldAutorotate = [viewControllerToAsk shouldAutorotate];
    }
    return shouldAutorotate;
}

- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [self.toolbarAnimator removeAllBehaviors];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        for (UIView *outlineView in self.outlineViewsForVisibleViews.allValues) {
            outlineView.hidden = YES;
        }
        self.selectedViewOverlay.hidden = YES;
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        for (UIView *view in self.viewsAtTapPoint) {
            NSValue *key = [NSValue valueWithNonretainedObject:view];
            UIView *outlineView = self.outlineViewsForVisibleViews[key];
            outlineView.frame = [self frameInLocalCoordinatesForView:view];
            if (self.currentMode == FLEXExplorerModeSelect) {
                outlineView.hidden = NO;
            }
        }

        if (self.selectedView) {
            self.selectedViewOverlay.frame = [self frameInLocalCoordinatesForView:self.selectedView];
            self.selectedViewOverlay.hidden = NO;
        }
    }];
}


#pragma mark - Setter Overrides

- (void)setSelectedView:(UIView *)selectedView {
    if (![_selectedView isEqual:selectedView]) {
        if (![self.viewsAtTapPoint containsObject:_selectedView]) {
            [self stopObservingView:_selectedView];
        }

        _selectedView = selectedView;

        [self beginObservingView:selectedView];

        // Update the toolbar and selected overlay
        self.explorerToolbar.selectedViewDescription = [FLEXUtility
            descriptionForView:selectedView includingFrame:YES
        ];
        self.explorerToolbar.selectedViewOverlayColor = [FLEXUtility
            consistentRandomColorForObject:selectedView
        ];

        if (selectedView) {
            if (!self.selectedViewOverlay) {
                self.selectedViewOverlay = [UIView new];
                [self.view addSubview:self.selectedViewOverlay];
                self.selectedViewOverlay.layer.borderWidth = 1.0;
            }
            UIColor *outlineColor = [FLEXUtility consistentRandomColorForObject:selectedView];
            self.selectedViewOverlay.backgroundColor = [outlineColor colorWithAlphaComponent:0.2];
            self.selectedViewOverlay.layer.borderColor = outlineColor.CGColor;
            self.selectedViewOverlay.frame = [self.view convertRect:selectedView.bounds fromView:selectedView];

            // Make sure the selected overlay is in front of all the other subviews
            // except the toolbar, which should always stay on top.
            [self.view bringSubviewToFront:self.selectedViewOverlay];
            [self.view bringSubviewToFront:self.explorerToolbar];
        } else {
            [self.selectedViewOverlay removeFromSuperview];
            self.selectedViewOverlay = nil;
        }

        // Some of the button states depend on whether we have a selected view.
        [self updateButtonStates];
    }
}

- (void)setViewsAtTapPoint:(NSArray<UIView *> *)viewsAtTapPoint {
    if (![_viewsAtTapPoint isEqual:viewsAtTapPoint]) {
        for (UIView *view in _viewsAtTapPoint) {
            if (view != self.selectedView) {
                [self stopObservingView:view];
            }
        }

        _viewsAtTapPoint = viewsAtTapPoint;

        for (UIView *view in viewsAtTapPoint) {
            [self beginObservingView:view];
        }
    }
}

- (void)setCurrentMode:(FLEXExplorerMode)currentMode {
    if (_currentMode != currentMode) {
        _currentMode = currentMode;
        switch (currentMode) {
            case FLEXExplorerModeDefault:
                [self removeAndClearOutlineViews];
                self.viewsAtTapPoint = nil;
                self.selectedView = nil;
                break;

            case FLEXExplorerModeSelect:
                // Make sure the outline views are unhidden in case we came from the move mode.
                for (NSValue *key in self.outlineViewsForVisibleViews) {
                    UIView *outlineView = self.outlineViewsForVisibleViews[key];
                    outlineView.hidden = NO;
                }
                break;

            case FLEXExplorerModeMove:
                // Hide all the outline views to focus on the selected view,
                // which is the only one that will move.
                for (NSValue *key in self.outlineViewsForVisibleViews) {
                    UIView *outlineView = self.outlineViewsForVisibleViews[key];
                    outlineView.hidden = YES;
                }
                break;
        }
        self.movePanGR.enabled = currentMode == FLEXExplorerModeMove;
        [self updateButtonStates];
    }
}


#pragma mark - View Tracking

- (void)beginObservingView:(UIView *)view {
    // Bail if we're already observing this view or if there's nothing to observe.
    if (!view || [self.observedViews containsObject:view]) {
        return;
    }

    for (NSString *keyPath in self.viewKeyPathsToTrack) {
        [view addObserver:self forKeyPath:keyPath options:0 context:NULL];
    }

    [self.observedViews addObject:view];
}

- (void)stopObservingView:(UIView *)view {
    if (!view) {
        return;
    }

    for (NSString *keyPath in self.viewKeyPathsToTrack) {
        [view removeObserver:self forKeyPath:keyPath];
    }

    [self.observedViews removeObject:view];
}

- (NSArray<NSString *> *)viewKeyPathsToTrack {
    static NSArray<NSString *> *trackedViewKeyPaths = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *frameKeyPath = NSStringFromSelector(@selector(frame));
        trackedViewKeyPaths = @[frameKeyPath];
    });
    return trackedViewKeyPaths;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary<NSString *, id> *)change
                       context:(void *)context {
    [self updateOverlayAndDescriptionForObjectIfNeeded:object];
}

- (void)updateOverlayAndDescriptionForObjectIfNeeded:(id)object {
    const NSUInteger indexOfView = [self.viewsAtTapPoint indexOfObject:object];
    if (indexOfView != NSNotFound) {
        UIView *view = self.viewsAtTapPoint[indexOfView];
        NSValue *key = [NSValue valueWithNonretainedObject:view];
        UIView *outline = self.outlineViewsForVisibleViews[key];
        if (outline) {
            outline.frame = [self frameInLocalCoordinatesForView:view];
        }
    }
    if (object == self.selectedView) {
        // Update the selected view description since we show the frame value there.
        self.explorerToolbar.selectedViewDescription = [FLEXUtility
            descriptionForView:self.selectedView includingFrame:YES
        ];
        CGRect selectedViewOutlineFrame = [self frameInLocalCoordinatesForView:self.selectedView];
        self.selectedViewOverlay.frame = selectedViewOutlineFrame;
    }
}

- (CGRect)frameInLocalCoordinatesForView:(UIView *)view {
    // Convert to window coordinates since the view may be in a different window than our view
    CGRect frameInWindow = [view convertRect:view.bounds toView:nil];
    // Convert from the window to our view's coordinate space
    return [self.view convertRect:frameInWindow fromView:nil];
}

- (void)keyboardShown:(NSNotification *)notif {
    [self.toolbarAnimator removeAllBehaviors];
    CGRect keyboardFrame = [notif.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect toolbarFrame = self.explorerToolbar.frame;

    if (CGRectGetMinY(keyboardFrame) < CGRectGetMaxY(toolbarFrame)) {
        toolbarFrame.origin.y = keyboardFrame.origin.y - toolbarFrame.size.height;
        // Subtract a little more, to ignore accessory input views
        toolbarFrame.origin.y -= 50;

        [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:1 initialSpringVelocity:0.5
                            options:UIViewAnimationOptionCurveEaseOut animations:^{
            [self updateToolbarPositionWithUnconstrainedFrame:toolbarFrame];
        } completion:nil];
    }
}

#pragma mark - Toolbar Buttons

- (void)setupToolbarActions {
    FLEXExplorerToolbar *toolbar = self.explorerToolbar;
    NSDictionary<NSString *, FLEXExplorerToolbarItem *> *actionsToItems = @{
        NSStringFromSelector(@selector(selectButtonTapped:)):        toolbar.selectItem,
        NSStringFromSelector(@selector(hierarchyButtonTapped:)):     toolbar.hierarchyItem,
        NSStringFromSelector(@selector(recentButtonTapped:)):        toolbar.recentItem,
        NSStringFromSelector(@selector(moveButtonTapped:)):          toolbar.moveItem,
        NSStringFromSelector(@selector(globalsButtonTapped:)):       toolbar.globalsItem,
    };

    [actionsToItems enumerateKeysAndObjectsUsingBlock:^(NSString *sel, FLEXExplorerToolbarItem *item, BOOL *stop) {
        [item addTarget:self action:NSSelectorFromString(sel) forControlEvents:UIControlEventTouchUpInside];
    }];

    [toolbar.closeButton addTarget:self action:@selector(closeButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)selectButtonTapped:(FLEXExplorerToolbarItem *)sender {
    [self toggleSelectTool];
}

- (void)hierarchyButtonTapped:(FLEXExplorerToolbarItem *)sender {
    [self toggleViewsTool];
}

- (UIWindow *)statusWindow {
    return nil;
}

- (void)recentButtonTapped:(FLEXExplorerToolbarItem *)sender {
    NSAssert(FLEXTabList.sharedList.activeTab, @"Must have active tab");
    [self presentViewController:FLEXTabList.sharedList.activeTab animated:YES completion:nil];
}

- (void)moveButtonTapped:(FLEXExplorerToolbarItem *)sender {
    [self toggleMoveTool];
}

- (void)globalsButtonTapped:(FLEXExplorerToolbarItem *)sender {
    [self toggleMenuTool];
}

- (void)closeButtonTapped:(UIButton *)sender {
    self.currentMode = FLEXExplorerModeDefault;
    [self.delegate explorerViewControllerDidFinish:self];
}

- (void)updateButtonStates {
    FLEXExplorerToolbar *toolbar = self.explorerToolbar;

    toolbar.selectItem.selected = self.currentMode == FLEXExplorerModeSelect;

    // Move only enabled when an object is selected.
    const BOOL hasSelectedObject = self.selectedView != nil;
    toolbar.moveItem.enabled = hasSelectedObject;
    toolbar.moveItem.selected = self.currentMode == FLEXExplorerModeMove;

    // Recent only enabled when we have a last active tab
    if (!self.presentedViewController) {
        toolbar.recentItem.enabled = FLEXTabList.sharedList.activeTab != nil;
    } else {
        toolbar.recentItem.enabled = NO;
    }
}


#pragma mark - Toolbar Dragging

- (void)setupToolbarGestures {
    FLEXExplorerToolbar *toolbar = self.explorerToolbar;

    // Pan gesture for dragging the toolbar with UIKit Dynamics.
    self.toolbarPanGR = [[UIPanGestureRecognizer alloc]
        initWithTarget:self action:@selector(handleToolbarPanGesture:)
    ];
    self.toolbarPanGR.delegate = self;
    [toolbar.dragHandle addGestureRecognizer:self.toolbarPanGR];

    // Tap gesture for restoring the toolbar when it's stashed against an edge.
    // Only begins while stashed (see -gestureRecognizerShouldBegin:), so it
    // doesn't swallow taps on the toolbar's buttons during normal use.
    self.toolbarUnstashTapGR = [[UITapGestureRecognizer alloc]
        initWithTarget:self action:@selector(handleToolbarUnstashTapGesture:)
    ];
    self.toolbarUnstashTapGR.delegate = self;
    [toolbar.dragHandle addGestureRecognizer:self.toolbarUnstashTapGR];

    // Tap gesture for showing additional details
    self.detailsTapGR = [[UITapGestureRecognizer alloc]
        initWithTarget:self action:@selector(handleToolbarDetailsTapGesture:)
    ];
    [toolbar.selectedViewDescriptionContainer addGestureRecognizer:self.detailsTapGR];

    // Swipe gestures for selecting deeper / higher views at a point
    self.changeSelectedViewPanGR = [[UIPanGestureRecognizer alloc]
        initWithTarget:self action:@selector(handleChangeViewAtPointGesture:)
    ];
    self.changeSelectedViewPanGR.delegate = self;
    [toolbar.selectedViewDescriptionContainer addGestureRecognizer:self.changeSelectedViewPanGR];

    // Long press gesture to present tabs manager
    [toolbar.globalsItem addGestureRecognizer:[[UILongPressGestureRecognizer alloc]
        initWithTarget:self action:@selector(handleToolbarShowTabsGesture:)
    ]];

    // Long press gesture to present window manager
    [toolbar.selectItem addGestureRecognizer:[[UILongPressGestureRecognizer alloc]
        initWithTarget:self action:@selector(handleToolbarWindowManagerGesture:)
    ]];

    // Long press gesture to present view controllers at tap
    [toolbar.hierarchyItem addGestureRecognizer:[[UILongPressGestureRecognizer alloc]
        initWithTarget:self action:@selector(handleToolbarShowViewControllersGesture:)
    ]];
}

- (void)handleToolbarPanGesture:(UIPanGestureRecognizer *)panGR {
    CGPoint touchLocation = [panGR locationInView:self.view];

    switch (panGR.state) {
        case UIGestureRecognizerStateBegan: {
            self.toolbarDraggingPastEdge = YES;
            // Catch an in-flight stash/restore tuck so the drag continues from
            // wherever it had reached, instead of fighting the running spring.
            [self interruptToolbarStashAnimator];
            [self.toolbarAnimator removeAllBehaviors];

            // Dragging a stashed toolbar pulls it back out. Clear the *committed*
            // stash so the drag follows the finger, but leave the chevron to the
            // live >50% affordance below — clearing it here would flash the content
            // in while the pill is still mostly off-screen, then snap back.
            if (self.toolbarStashEdge != FLEXToolbarStashEdgeNone) {
                self.toolbarStashEdge = FLEXToolbarStashEdgeNone;
            }

            CGPoint toolbarCenter = self.explorerToolbar.center;
            self.toolbarDragOffset = UIOffsetMake(
                touchLocation.x - toolbarCenter.x,
                touchLocation.y - toolbarCenter.y
            );
            break;
        }

        case UIGestureRecognizerStateChanged: {
            [self updateToolbarPositionWithUnconstrainedFrame:[self toolbarFrameForTouchLocation:touchLocation]];

            // Once the pill is >50% past an edge, cross-fade in the chevron to signal
            // "release to stash" (and back out if dragged below the threshold).
            const CGRect safeArea = [self viewSafeArea];
            FLEXToolbarStashEdge candidate = FLEXToolbarDragStashEdge(
                self.explorerToolbar.frame, CGRectGetMinX(safeArea), CGRectGetMaxX(safeArea),
                kToolbarStashDragCommitFraction
            );
            if (candidate != self.explorerToolbar.stashEdge) {
                [self.explorerToolbar setStashEdge:candidate animated:YES];
            }
            break;
        }

        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled: {
            self.toolbarDraggingPastEdge = NO;

            const CGPoint velocity = [panGR velocityInView:self.view];
            const CGRect frame = self.explorerToolbar.frame;
            const CGRect safeArea = [self viewSafeArea];
            const CGFloat minX = CGRectGetMinX(safeArea);
            const CGFloat maxX = CGRectGetMaxX(safeArea);

            // Past a left/right edge → a stash is possible. Out of bounds on ANY
            // edge (incl. top/bottom, which never stash) → spring back in.
            const BOOL pastSide = CGRectGetMinX(frame) < minX || CGRectGetMaxX(frame) > maxX;
            const CGRect inBoundsFrame = [self constrainedToolbarFrame:frame];
            const BOOL outOfBounds = !CGRectEqualToRect(inBoundsFrame, frame);

            FLEXToolbarStashEdge edge = FLEXToolbarStashEdgeNone;
            if (pastSide) {
                // Commit if the PROJECTED frame is still >50% past a side edge
                // (so a hard flick from, say, 40% off still commits).
                CGRect projected = frame;
                projected.origin.x += velocity.x * kToolbarStashProjectionDeceleration;
                edge = FLEXToolbarDragStashEdge(projected, minX, maxX, kToolbarStashDragCommitFraction);
            } else if (!outOfBounds) {
                // Fully in bounds → the existing band-based, mostly-horizontal flick.
                edge = [self stashEdgeForReleaseWithVelocity:velocity];
            }

            if (edge != FLEXToolbarStashEdgeNone) {
                [self stashToolbarToEdge:edge withVelocity:velocity];
            } else if (outOfBounds) {
                // Past an edge but not stashing (under threshold, or top/bottom) → spring back.
                [self.explorerToolbar setStashEdge:FLEXToolbarStashEdgeNone animated:YES];
                [self animateToolbarToFrame:inBoundsFrame withVelocity:CGPointZero];
            } else {
                // In bounds, no stash → free-float (Dynamics bounce).
                [self.explorerToolbar setStashEdge:FLEXToolbarStashEdgeNone animated:YES];
                [self applyToolbarMomentumWithVelocity:velocity];
            }
            break;
        }

        default:
            break;
    }
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer == self.toolbarUnstashTapGR) {
        // Only intercept taps to restore the toolbar while it's stashed; otherwise
        // let taps fall through to the toolbar's buttons.
        return self.toolbarStashEdge != FLEXToolbarStashEdgeNone;
    }

    if (gestureRecognizer == self.changeSelectedViewPanGR) {
        CGPoint velocity = [(UIPanGestureRecognizer *)gestureRecognizer velocityInView:self.view];
        return fabs(velocity.x) > fabs(velocity.y);
    }

    if (gestureRecognizer == self.toolbarPanGR) {
        CGPoint velocity = [(UIPanGestureRecognizer *)gestureRecognizer velocityInView:self.view];
        if ([self toolbarPanTouchesSelectedViewDescription:gestureRecognizer]) {
            return fabs(velocity.y) >= fabs(velocity.x);
        }

        return YES;
    }

    return YES;
}

- (BOOL)toolbarPanTouchesSelectedViewDescription:(UIGestureRecognizer *)gestureRecognizer {
    CGPoint location = [gestureRecognizer locationInView:self.explorerToolbar];
    UIView *touchedView = [self.explorerToolbar hitTest:location withEvent:nil];
    return touchedView == self.explorerToolbar.selectedViewDescriptionContainer ||
        [touchedView isDescendantOfView:self.explorerToolbar.selectedViewDescriptionContainer];
}

- (CGRect)toolbarFrameForTouchLocation:(CGPoint)touchLocation {
    CGPoint targetCenter = CGPointMake(
        touchLocation.x - self.toolbarDragOffset.horizontal,
        touchLocation.y - self.toolbarDragOffset.vertical
    );
    CGRect frame = self.explorerToolbar.frame;
    frame.origin.x = FLEXFloor(targetCenter.x - frame.size.width / 2.0);
    frame.origin.y = FLEXFloor(targetCenter.y - frame.size.height / 2.0);
    return frame;
}

- (void)applyToolbarMomentumWithVelocity:(CGPoint)velocity {
    CGFloat speed = hypot(velocity.x, velocity.y);
    if (speed <= 100) return;

    UIDynamicItemBehavior *momentum = [[UIDynamicItemBehavior alloc]
        initWithItems:@[self.explorerToolbar]
    ];
    [momentum addLinearVelocity:velocity forItem:self.explorerToolbar];
    momentum.resistance = 6.0;
    momentum.elasticity = 0.3;
    momentum.allowsRotation = NO;

    UICollisionBehavior *collision = [[UICollisionBehavior alloc]
        initWithItems:@[self.explorerToolbar]
    ];
    CGRect boundary = CGRectInset([self viewSafeArea], kToolbarSafeAreaPadding, kToolbarSafeAreaPadding);
    [collision addBoundaryWithIdentifier:@"safeArea"
        forPath:[UIBezierPath bezierPathWithRect:boundary]];

    UIDynamicItemBehavior *noRotation = [[UIDynamicItemBehavior alloc]
        initWithItems:@[self.explorerToolbar]
    ];
    noRotation.allowsRotation = NO;

    __weak typeof(self) weakSelf = self;
    momentum.action = ^{
        [weakSelf persistToolbarPosition];
    };

    [self.toolbarAnimator addBehavior:momentum];
    [self.toolbarAnimator addBehavior:collision];
    [self.toolbarAnimator addBehavior:noRotation];
}

- (void)updateToolbarPositionWithUnconstrainedFrame:(CGRect)unconstrainedFrame {
    self.explorerToolbar.frame = [self constrainedToolbarFrame:unconstrainedFrame];
    [self persistToolbarPosition];
}

- (void)persistToolbarPosition {
    const CGRect frame = self.explorerToolbar.frame;
    // The toolbar always relaunches on-screen and un-stashed, so never persist an
    // off-screen X (from a stash or a mid-drag) — clamp it to the on-screen range.
    const CGRect safeArea = [self viewSafeArea];
    const CGFloat minX = CGRectGetMinX(safeArea) + kToolbarSafeAreaPadding;
    const CGFloat maxX = CGRectGetMaxX(safeArea) - frame.size.width - kToolbarSafeAreaPadding;
    CGFloat originX = frame.origin.x;
    if (maxX >= minX) {
        originX = MAX(minX, MIN(maxX, originX));
    }
    NSUserDefaults.standardUserDefaults.flex_toolbarTopMargin = frame.origin.y;
    NSUserDefaults.standardUserDefaults.flex_toolbarLeftMargin = originX;
}

- (CGRect)constrainedToolbarFrame:(CGRect)unconstrainedFrame {
    CGRect safeArea = [self viewSafeArea];

    unconstrainedFrame.size.width = MIN(
        unconstrainedFrame.size.width,
        MAX(0, CGRectGetWidth(safeArea) - kToolbarSafeAreaPadding * 2.0)
    );
    unconstrainedFrame.size.height = MIN(
        unconstrainedFrame.size.height,
        MAX(0, CGRectGetHeight(safeArea) - kToolbarSafeAreaPadding * 2.0)
    );

    // While actively dragging, let the pill follow the finger off ANY edge
    // (top/bottom included, no rubber-band); the release springs it back in or
    // commits a side-stash. Only width/height are constrained mid-drag.
    if (self.toolbarDraggingPastEdge) {
        return unconstrainedFrame;
    }

    const CGFloat minY = CGRectGetMinY(safeArea) + kToolbarSafeAreaPadding;
    const CGFloat maxY = CGRectGetMaxY(safeArea) - unconstrainedFrame.size.height - kToolbarSafeAreaPadding;
    if (maxY < minY) {
        unconstrainedFrame.origin.y = FLEXFloor(CGRectGetMidY(safeArea) - unconstrainedFrame.size.height / 2.0);
    } else if (unconstrainedFrame.origin.y < minY) {
        unconstrainedFrame.origin.y = minY;
    } else if (unconstrainedFrame.origin.y > maxY) {
        unconstrainedFrame.origin.y = maxY;
    }

    // While stashed, the toolbar deliberately hangs off the edge with only a
    // sliver visible, so bypass the normal on-screen horizontal clamp.
    if (self.toolbarStashEdge != FLEXToolbarStashEdgeNone) {
        unconstrainedFrame.origin.x = [self stashedOriginXForEdge:self.toolbarStashEdge
                                                            width:unconstrainedFrame.size.width];
        return unconstrainedFrame;
    }

    const CGFloat minX = CGRectGetMinX(safeArea) + kToolbarSafeAreaPadding;
    const CGFloat maxX = CGRectGetMaxX(safeArea) - unconstrainedFrame.size.width - kToolbarSafeAreaPadding;
    if (maxX < minX) {
        unconstrainedFrame.origin.x = FLEXFloor(CGRectGetMidX(safeArea) - unconstrainedFrame.size.width / 2.0);
    } else if (unconstrainedFrame.origin.x < minX) {
        unconstrainedFrame.origin.x = minX;
    } else if (unconstrainedFrame.origin.x > maxX) {
        unconstrainedFrame.origin.x = maxX;
    }

    return unconstrainedFrame;
}

#pragma mark - Toolbar Stashing

/// The off-screen origin X that leaves only the toolbar's stash sliver of a
/// toolbar of the given width peeking out from the given edge.
- (CGFloat)stashedOriginXForEdge:(FLEXToolbarStashEdge)edge width:(CGFloat)width {
    const CGRect safeArea = [self viewSafeArea];
    const CGFloat visibleWidth = FLEXExplorerToolbar.stashVisibleWidth;
    if (edge == FLEXToolbarStashEdgeLeft) {
        return FLEXFloor(CGRectGetMinX(safeArea) - (width - visibleWidth));
    }
    // FLEXToolbarStashEdgeRight
    return FLEXFloor(CGRectGetMaxX(safeArea) - visibleWidth);
}

/// Returns the frame for the toolbar stashed against \c edge, preserving the
/// vertical position of \c frame (the Y clamp is applied by -constrainedToolbarFrame:).
- (CGRect)stashedToolbarFrameForEdge:(FLEXToolbarStashEdge)edge fromFrame:(CGRect)frame {
    frame.origin.x = [self stashedOriginXForEdge:edge width:frame.size.width];
    return frame;
}

/// Decides whether a pan release should stash the toolbar, and against which edge,
/// by projecting the release velocity under linear decay: stashes if the projected
/// center lands within the edge band of a side. A predominantly-vertical flick never stashes.
- (FLEXToolbarStashEdge)stashEdgeForReleaseWithVelocity:(CGPoint)velocity {
    const CGRect safeArea = [self viewSafeArea];
    // Raw screen edges (not padded): we're deciding about the screen edge the pill
    // would coast to, not the on-screen padded boundary.
    return FLEXStashEdgeForRelease(
        velocity,
        CGRectGetMidX(self.explorerToolbar.frame),
        CGRectGetMinX(safeArea),
        CGRectGetMaxX(safeArea),
        kToolbarStashEdgeBand,
        kToolbarStashProjectionDeceleration
    );
}

/// Stops any in-flight stash/restore spring so a new interaction — a drag, or a
/// new tuck — takes over cleanly instead of fighting the running animation.
/// Safe to call when nothing is animating.
- (void)interruptToolbarStashAnimator {
    // The isRunning guard also keeps -stopAnimation: exception-safe: it throws
    // only in the inactive state, and isRunning is YES only while active.
    if (self.toolbarStashAnimator.isRunning) {
        [self.toolbarStashAnimator stopAnimation:YES];
    }
    self.toolbarStashAnimator = nil;
}

/// Springs the toolbar to `target`, seeding the spring's initial velocity from
/// the release velocity (PiP-style continuity). Retains the animator so a new
/// touch can interrupt it, and clears + persists on completion.
- (void)animateToolbarToFrame:(CGRect)target withVelocity:(CGPoint)velocity {
    // Never run two tucks at once: stop any in-flight one first. (Also means a
    // finished animator's completion can never nil a newer, running animator.)
    [self interruptToolbarStashAnimator];

    const CGFloat dx = target.origin.x - self.explorerToolbar.frame.origin.x;
    const CGFloat dy = target.origin.y - self.explorerToolbar.frame.origin.y;
    const CGFloat relVx = FLEXRelativeSpringVelocity(velocity.x, dx, kToolbarStashMaxRelativeVelocity);
    const CGFloat relVy = FLEXRelativeSpringVelocity(velocity.y, dy, kToolbarStashMaxRelativeVelocity);

    UISpringTimingParameters *spring = [[UISpringTimingParameters alloc]
        initWithDampingRatio:0.8 initialVelocity:CGVectorMake(relVx, relVy)
    ];
    // Duration is nominal: with spring timing parameters the spring's own
    // settling time governs the animation, not this value.
    UIViewPropertyAnimator *animator = [[UIViewPropertyAnimator alloc]
        initWithDuration:0.5 timingParameters:spring
    ];

    // weakSelf in BOTH blocks: self retains the animator (via the
    // toolbarStashAnimator property), so a strong self capture here would form a
    // self<->animator retain cycle that only breaks on completion.
    __weak typeof(self) weakSelf = self;
    [animator addAnimations:^{
        weakSelf.explorerToolbar.frame = target;
    }];
    [animator addCompletion:^(UIViewAnimatingPosition finalPosition) {
        weakSelf.toolbarStashAnimator = nil;
        [weakSelf persistToolbarPosition];
    }];

    self.toolbarStashAnimator = animator;
    [animator startAnimation];
}

- (void)stashToolbarToEdge:(FLEXToolbarStashEdge)edge withVelocity:(CGPoint)velocity {
    [self.toolbarAnimator removeAllBehaviors];

    CGRect target = [self stashedToolbarFrameForEdge:edge fromFrame:self.explorerToolbar.frame];

    // PiP Y-glide: while tucking to the edge, drift toward where the flick was
    // heading vertically, clamped so the peek sliver stays fully on-screen.
    const CGRect safeArea = [self viewSafeArea];
    const CGFloat minCenterY = CGRectGetMinY(safeArea) + kToolbarSafeAreaPadding + target.size.height / 2.0;
    // Unlike the draggable area, the stash also clears the bottom inset (home
    // indicator) so the sliver can always be tapped/dragged back out.
    const CGFloat maxCenterY = CGRectGetMaxY(safeArea) - self.view.safeAreaInsets.bottom
        - kToolbarSafeAreaPadding - target.size.height / 2.0;
    const CGFloat targetCenterY = FLEXProjectedStashCenterY(
        CGRectGetMidY(self.explorerToolbar.frame), velocity.y,
        kToolbarStashProjectionDeceleration, minCenterY, maxCenterY
    );
    target.origin.y = FLEXFloor(targetCenterY - target.size.height / 2.0);

    self.toolbarStashEdge = edge;
    [self.explorerToolbar setStashEdge:edge animated:YES];

    [self animateToolbarToFrame:target withVelocity:velocity];
}

- (void)restoreStashedToolbarAnimated:(BOOL)animated {
    const FLEXToolbarStashEdge previousEdge = self.toolbarStashEdge;
    if (previousEdge == FLEXToolbarStashEdgeNone) {
        return;
    }

    self.toolbarStashEdge = FLEXToolbarStashEdgeNone;
    [self.explorerToolbar setStashEdge:FLEXToolbarStashEdgeNone animated:animated];

    // Slide the pill fully back inside the edge it came from.
    const CGRect safeArea = [self viewSafeArea];
    CGRect target = self.explorerToolbar.frame;
    if (previousEdge == FLEXToolbarStashEdgeLeft) {
        target.origin.x = CGRectGetMinX(safeArea) + kToolbarSafeAreaPadding;
    } else {
        target.origin.x = CGRectGetMaxX(safeArea) - target.size.width - kToolbarSafeAreaPadding;
    }
    target = [self constrainedToolbarFrame:target];

    if (animated) {
        [self animateToolbarToFrame:target withVelocity:CGPointZero];
    } else {
        self.explorerToolbar.frame = target;
        [self persistToolbarPosition];
    }
}

- (void)handleToolbarUnstashTapGesture:(UITapGestureRecognizer *)tapGR {
    if (tapGR.state == UIGestureRecognizerStateRecognized &&
        self.toolbarStashEdge != FLEXToolbarStashEdgeNone) {
        [self.toolbarAnimator removeAllBehaviors];
        [self restoreStashedToolbarAnimated:YES];
    }
}

- (void)handleToolbarDetailsTapGesture:(UITapGestureRecognizer *)tapGR {
    if (tapGR.state == UIGestureRecognizerStateRecognized && self.selectedView) {
        UIViewController *topStackVC = [FLEXObjectExplorerFactory explorerViewControllerForObject:self.selectedView];
        [self presentViewController:
            [FLEXNavigationController withRootViewController:topStackVC]
        animated:YES completion:nil];
    }
}

- (void)handleToolbarShowTabsGesture:(UILongPressGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        // Don't use FLEXNavigationController because the tab viewer itself is not a tab
        [super presentViewController:[[UINavigationController alloc]
            initWithRootViewController:[FLEXTabsViewController new]
        ] animated:YES completion:nil];
    }
}

- (void)handleToolbarWindowManagerGesture:(UILongPressGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        [super presentViewController:[FLEXNavigationController
            withRootViewController:[FLEXWindowManagerController new]
        ] animated:YES completion:nil];
    }
}

- (void)handleToolbarShowViewControllersGesture:(UILongPressGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan && self.viewsAtTapPoint.count) {
        UIViewController *list = [FLEXViewControllersViewController
            controllersForViews:self.viewsAtTapPoint
        ];
        [self presentViewController:
            [FLEXNavigationController withRootViewController:list
        ] animated:YES completion:nil];
    }
}


#pragma mark - View Selection

- (void)handleSelectionTap:(UITapGestureRecognizer *)tapGR {
    // Only if we're in selection mode
    if (self.currentMode == FLEXExplorerModeSelect && tapGR.state == UIGestureRecognizerStateRecognized) {
        // Note that [tapGR locationInView:nil] is broken in iOS 8,
        // so we have to do a two step conversion to window coordinates.
        // Thanks to @lascorbe for finding this: https://github.com/Flipboard/FLEX/pull/31
        CGPoint tapPointInView = [tapGR locationInView:self.view];
        CGPoint tapPointInWindow = [self.view convertPoint:tapPointInView toView:nil];

        [self updateOutlineViewsForSelectionPoint:tapPointInWindow];
        self.lastTapPoint = tapPointInWindow;
    }
}

- (void)handleChangeViewAtPointGesture:(UIPanGestureRecognizer *)sender {
    const NSInteger max = self.viewsAtTapPoint.count - 1;
    const NSInteger currentIdx = [self.viewsAtTapPoint indexOfObject:self.selectedView];
    const CGFloat locationX = [sender locationInView:self.view].x;

    // Track the pan gesture: every N points we move along the X axis,
    // actuate some haptic feedback and move up or down the hierarchy.
    // We only store the "last" location when we've met the threshold.
    // We only change the view and actuate feedback if the view selection
    // changes; that is, as long as we don't go outside or under the array.
    switch (sender.state) {
        case UIGestureRecognizerStateBegan: {
            self.selectedViewLastPanX = locationX;
            break;
        }
        case UIGestureRecognizerStateChanged: {
            static CGFloat kNextLevelThreshold = 20.f;
            CGFloat lastX = self.selectedViewLastPanX;
            NSInteger newSelection = currentIdx;

            // Left, go down the hierarchy
            if (locationX < lastX && (lastX - locationX) >= kNextLevelThreshold) {
                // Choose a new view index up to the max index
                newSelection = MIN(max, currentIdx + 1);
                self.selectedViewLastPanX = locationX;
            }
            // Right, go up the hierarchy
            else if (lastX < locationX && (locationX - lastX) >= kNextLevelThreshold) {
                // Choose a new view index down to the min index
                newSelection = MAX(0, currentIdx - 1);
                self.selectedViewLastPanX = locationX;
            }

            if (currentIdx != newSelection) {
                self.selectedView = self.viewsAtTapPoint[newSelection];
                [self actuateSelectionChangedFeedback];
            }

            break;
        }

        default: break;
    }
}

- (void)actuateSelectionChangedFeedback {
    [self.selectionFBG selectionChanged];
}

- (void)updateOutlineViewsForSelectionPoint:(CGPoint)selectionPointInWindow {
    [self removeAndClearOutlineViews];

    // Include hidden views in the "viewsAtTapPoint" array so we can show them in the hierarchy list.
    self.viewsAtTapPoint = [self viewsAtPoint:selectionPointInWindow skipHiddenViews:NO];

    // For outlined views and the selected view, only use visible views.
    // Outlining hidden views adds clutter and makes the selection behavior confusing.
    NSArray<UIView *> *visibleViewsAtTapPoint = [self viewsAtPoint:selectionPointInWindow skipHiddenViews:YES];
    NSMutableDictionary<NSValue *, UIView *> *newOutlineViewsForVisibleViews = [NSMutableDictionary new];
    for (UIView *view in visibleViewsAtTapPoint) {
        UIView *outlineView = [self outlineViewForView:view];
        [self.view addSubview:outlineView];
        NSValue *key = [NSValue valueWithNonretainedObject:view];
        [newOutlineViewsForVisibleViews setObject:outlineView forKey:key];
    }
    self.outlineViewsForVisibleViews = newOutlineViewsForVisibleViews;
    self.selectedView = [self viewForSelectionAtPoint:selectionPointInWindow];

    // Make sure the explorer toolbar doesn't end up behind the newly added outline views.
    [self.view bringSubviewToFront:self.explorerToolbar];

    [self updateButtonStates];
}

- (UIView *)outlineViewForView:(UIView *)view {
    CGRect outlineFrame = [self frameInLocalCoordinatesForView:view];
    UIView *outlineView = [[UIView alloc] initWithFrame:outlineFrame];
    outlineView.backgroundColor = UIColor.clearColor;
    outlineView.layer.borderColor = [FLEXUtility consistentRandomColorForObject:view].CGColor;
    outlineView.layer.borderWidth = 1.0;
    return outlineView;
}

- (void)removeAndClearOutlineViews {
    for (NSValue *key in self.outlineViewsForVisibleViews) {
        UIView *outlineView = self.outlineViewsForVisibleViews[key];
        [outlineView removeFromSuperview];
    }
    self.outlineViewsForVisibleViews = nil;
}

- (NSArray<UIView *> *)viewsAtPoint:(CGPoint)tapPointInWindow skipHiddenViews:(BOOL)skipHidden {
    NSMutableArray<UIView *> *views = [NSMutableArray new];
    for (UIWindow *window in FLEXUtility.allWindows) {
        // Don't include the explorer's own window or subviews.
        if (window != self.view.window && [window pointInside:tapPointInWindow withEvent:nil]) {
            [views addObject:window];
            [views addObjectsFromArray:[self
                recursiveSubviewsAtPoint:tapPointInWindow inView:window skipHiddenViews:skipHidden
            ]];
        }
    }
    return views;
}

- (UIView *)viewForSelectionAtPoint:(CGPoint)tapPointInWindow {
    // Select in the window that would handle the touch, but don't just use the result of
    // hitTest:withEvent: so we can still select views with interaction disabled.
    // Default to the the application's key window if none of the windows want the touch.
    UIWindow *windowForSelection = UIApplication.sharedApplication.keyWindow;
    for (UIWindow *window in FLEXUtility.allWindows.reverseObjectEnumerator) {
        // Ignore the explorer's own window.
        if (window != self.view.window) {
            if ([window hitTest:tapPointInWindow withEvent:nil]) {
                windowForSelection = window;
                break;
            }
        }
    }

    NSArray<UIView *> *const visibleViews = [self recursiveSubviewsAtPoint:tapPointInWindow inView:windowForSelection skipHiddenViews:YES];
    if (visibleViews.count == 0) {
        return nil;
    }

    // If this is a same-point re-tap and the currently selected view is in
    // the fresh visible views, cycle to the next view up the hierarchy.
    // Using the selected view reference instead of a cached index means we
    // always work with the current view hierarchy, not stale state.
    static const CGFloat kSamePointThreshold = 10.0;
    const CGFloat dx = tapPointInWindow.x - self.lastTapPoint.x;
    const CGFloat dy = tapPointInWindow.y - self.lastTapPoint.y;
    const BOOL isSamePoint = (dx * dx + dy * dy) <= (kSamePointThreshold * kSamePointThreshold);

    if (isSamePoint && self.selectedView) {
        const NSUInteger currentIdx = [visibleViews indexOfObjectIdenticalTo:self.selectedView];
        if (currentIdx != NSNotFound) {
            // Move up the hierarchy; wrap around to the deepest view
            return currentIdx > 0 ? visibleViews[currentIdx - 1] : visibleViews.lastObject;
        }
    }

    // New point or no current selection: select the deepest view
    return visibleViews.lastObject;
}

/// iOS 26 introduced several system overlay views (floating bars, context menus,
/// passthrough containers) that sit above app content in the view hierarchy.
/// These are almost never the views a developer wants to inspect, yet they
/// dominate tap-to-select results — often requiring many taps to reach the
/// actual app view underneath. Skip them by default on iOS 26+.
static BOOL FLEXIsDefaultSkippedView(UIView *view) {
    if (@available(iOS 26, *)) {
        static NSSet<NSString *> *skippedSubstrings;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            skippedSubstrings = [NSSet setWithArray:@[
                @"FloatingBarHostingView",
                @"FloatingBarContainerView",
                @"_UITabBarContainerView",
                @"_UITouchPassthroughView",
                @"_UIContextMenuContainerView",
                @"_UIContextMenuPlatterTransitionView",
            ]];
        });
        NSString *const className = NSStringFromClass([view class]);
        for (NSString *substring in skippedSubstrings) {
            if ([className containsString:substring]) {
                return YES;
            }
        }
    }
    return NO;
}

- (NSArray<UIView *> *)recursiveSubviewsAtPoint:(CGPoint)pointInView
                                         inView:(UIView *)view
                                skipHiddenViews:(BOOL)skipHidden {
    NSMutableArray<UIView *> *subviewsAtPoint = [NSMutableArray new];
    BOOL (^skippedPredicate)(UIView *) = self.skippedViewPredicate;
    for (UIView *subview in view.subviews) {
        BOOL isHidden = subview.hidden || subview.alpha < 0.01;
        if (skipHidden && isHidden) {
            continue;
        }

        BOOL subviewContainsPoint = CGRectContainsPoint(subview.frame, pointInView);

        if (FLEXIsDefaultSkippedView(subview) || (skippedPredicate && skippedPredicate(subview))) {
            // Skip adding this view but still recurse into its subviews
            if (subviewContainsPoint || !subview.clipsToBounds) {
                const CGPoint pointInSubview = [view convertPoint:pointInView toView:subview];
                [subviewsAtPoint addObjectsFromArray:[self
                    recursiveSubviewsAtPoint:pointInSubview inView:subview skipHiddenViews:skipHidden
                ]];
            }
            continue;
        }

        if (subviewContainsPoint) {
            [subviewsAtPoint addObject:subview];
        }
        
        // If this view doesn't clip to its bounds, we need to check its subviews even if it
        // doesn't contain the selection point. They may be visible and contain the selection point.
        if (subviewContainsPoint || !subview.clipsToBounds) {
            CGPoint pointInSubview = [view convertPoint:pointInView toView:subview];
            [subviewsAtPoint addObjectsFromArray:[self
                recursiveSubviewsAtPoint:pointInSubview inView:subview skipHiddenViews:skipHidden
            ]];
        }
    }
    return subviewsAtPoint;
}


#pragma mark - Selected View Moving

- (void)handleMovePan:(UIPanGestureRecognizer *)movePanGR {
    switch (movePanGR.state) {
        case UIGestureRecognizerStateBegan:
            self.selectedViewFrameBeforeDragging = self.selectedView.frame;
            [self updateSelectedViewPositionWithDragGesture:movePanGR];
            break;

        case UIGestureRecognizerStateChanged:
        case UIGestureRecognizerStateEnded:
            [self updateSelectedViewPositionWithDragGesture:movePanGR];
            break;

        default:
            break;
    }
}

- (void)updateSelectedViewPositionWithDragGesture:(UIPanGestureRecognizer *)movePanGR {
    CGPoint translation = [movePanGR translationInView:self.selectedView.superview];
    CGRect newSelectedViewFrame = self.selectedViewFrameBeforeDragging;
    newSelectedViewFrame.origin.x = FLEXFloor(newSelectedViewFrame.origin.x + translation.x);
    newSelectedViewFrame.origin.y = FLEXFloor(newSelectedViewFrame.origin.y + translation.y);
    self.selectedView.frame = newSelectedViewFrame;
}


#pragma mark - Safe Area Handling

- (CGRect)viewSafeArea {
    // The general draggable area insets only the top (status bar / notch): the
    // toolbar may drag and free-float all the way down to the bottom edge. Only
    // *stashing* keeps clear of the home indicator (see -stashToolbarToEdge:…),
    // so the draggable region can sit lower than the stashable region.
    const CGFloat topInset = self.view.safeAreaInsets.top;
    const UIEdgeInsets safeAreaInsets = UIEdgeInsetsMake(topInset, 0.0, 0.0, 0.0);
    return UIEdgeInsetsInsetRect(self.view.bounds, safeAreaInsets);
}

- (void)viewSafeAreaInsetsDidChange {
    [super viewSafeAreaInsetsDidChange];
    [self.toolbarAnimator removeAllBehaviors];

    CGRect safeArea = [self viewSafeArea];
    CGSize toolbarSize = [self.explorerToolbar sizeThatFits:CGSizeMake(
        CGRectGetWidth(safeArea), CGRectGetHeight(safeArea)
    )];
    [self updateToolbarPositionWithUnconstrainedFrame:CGRectMake(
        CGRectGetMinX(self.explorerToolbar.frame),
        CGRectGetMinY(self.explorerToolbar.frame),
        toolbarSize.width,
        toolbarSize.height)
    ];
}


#pragma mark - Touch Handling

- (BOOL)shouldReceiveTouchAtWindowPoint:(CGPoint)pointInWindowCoordinates {
    CGPoint pointInLocalCoordinates = [self.view convertPoint:pointInWindowCoordinates fromView:nil];

    // If we have a modal presented, is it in the modal?
    if (self.presentedViewController) {
        UIView *presentedView = self.presentedViewController.view;
        CGPoint pipvc = [presentedView convertPoint:pointInLocalCoordinates fromView:self.view];
        UIView *hit = [presentedView hitTest:pipvc withEvent:nil];
        if (hit != nil) {
            return YES;
        }
    }

    // If the touch lands on a view matched by the skipped-view predicate
    // or the built-in iOS 26+ default skip list, let it pass through so
    // the view remains interactive during select/move mode.
    {
        UIWindow *const appKeyWindow = [FLEXUtility appKeyWindow];
        if (appKeyWindow) {
            const CGPoint pointInWindow = [appKeyWindow convertPoint:pointInWindowCoordinates fromView:nil];
            UIView *const hitView = [appKeyWindow hitTest:pointInWindow withEvent:nil];
            // ...but a touch that's actually on our toolbar (e.g. a stashed
            // sliver parked over a skipped app view) is always ours — never pass
            // it through, or the sliver becomes impossible to grab back.
            const BOOL onToolbar = CGRectContainsPoint(self.explorerToolbar.frame, pointInLocalCoordinates);
            if (hitView && !onToolbar && (FLEXIsDefaultSkippedView(hitView) ||
                            (self.skippedViewPredicate && self.skippedViewPredicate(hitView)))) {
                return NO;
            }
        }
    }

    // Always if we're in selection mode
    if (self.currentMode == FLEXExplorerModeSelect) {
        return YES;
    }
    
    // Always in move mode too
    if (self.currentMode == FLEXExplorerModeMove) {
        return YES;
    }
    
    // Always if it's on the toolbar
    if (CGRectContainsPoint(self.explorerToolbar.frame, pointInLocalCoordinates)) {
        return YES;
    }
    
    return NO;
}


#pragma mark - FLEXHierarchyDelegate

- (void)viewHierarchyDidDismiss:(UIView *)selectedView {
    // Note that we need to wait until the view controller is dismissed to calculate the frame
    // of the outline view, otherwise the coordinate conversion doesn't give the correct result.
    [self toggleViewsToolWithCompletion:^{
        // If the selected view is outside of the tap point array (selected from "Full Hierarchy"),
        // then clear out the tap point array and remove all the outline views.
        if (![self.viewsAtTapPoint containsObject:selectedView]) {
            self.viewsAtTapPoint = nil;
            [self removeAndClearOutlineViews];
        }

        // If we now have a selected view and we didn't have one previously, go to "select" mode.
        if (self.currentMode == FLEXExplorerModeDefault && selectedView) {
            self.currentMode = FLEXExplorerModeSelect;
        }

        // The selected view setter will also update the selected view overlay appropriately.
        self.selectedView = selectedView;
    }];
}


#pragma mark - Modal Presentation and Window Management

- (void)presentViewController:(UIViewController *)toPresent
                               animated:(BOOL)animated
                             completion:(void (^)(void))completion {
    // Make our window key to correctly handle input.
    [self.view.window makeKeyWindow];


    [self updateButtonStates];

    // Show the view controller
    [super presentViewController:toPresent animated:animated completion:^{
        [self updateButtonStates];

        if (completion) completion();
    }];
}

- (void)dismissViewControllerAnimated:(BOOL)animated completion:(void (^)(void))completion {    
    UIWindow *appWindow = self.window.previousKeyWindow;
    [appWindow makeKeyWindow];
    [appWindow.rootViewController setNeedsStatusBarAppearanceUpdate];

    // Restore the status bar window's normal window level.
    // We want it above FLEX while a modal is presented for
    // scroll to top, but below FLEX otherwise for exploration.
    [self statusWindow].windowLevel = UIWindowLevelStatusBar;

    [self updateButtonStates];

    [super dismissViewControllerAnimated:animated completion:^{
        [self updateButtonStates];

        if (completion) completion();
    }];
}

- (BOOL)wantsWindowToBecomeKey {
    return self.window.previousKeyWindow != nil;
}

- (void)toggleToolWithViewControllerProvider:(UINavigationController *(^)(void))future
                                  completion:(void (^_Nullable)(void))completion {
    if (self.presentedViewController) {
        // We do NOT want to present the future; this is
        // a convenience method for toggling the SAME TOOL
        [self dismissViewControllerAnimated:YES completion:completion];
    } else if (future) {
        [self presentViewController:future() animated:YES completion:completion];
    }
}

- (void)presentTool:(UINavigationController *(^)(void))future
         completion:(void (^_Nullable)(void))completion {
    if (self.presentedViewController) {
        // If a tool is already presented, dismiss it first
        [self dismissViewControllerAnimated:YES completion:^{
            [self presentViewController:future() animated:YES completion:completion];
        }];
    } else if (future) {
        [self presentViewController:future() animated:YES completion:completion];
    }
}

- (FLEXWindow *)window {
    return (id)self.view.window;
}


#pragma mark - Keyboard Shortcut Helpers

- (void)toggleSelectTool {
    if (self.currentMode == FLEXExplorerModeSelect) {
        self.currentMode = FLEXExplorerModeDefault;
    } else {
        self.currentMode = FLEXExplorerModeSelect;
    }
}

- (void)toggleMoveTool {
    if (self.currentMode == FLEXExplorerModeMove) {
        self.currentMode = FLEXExplorerModeSelect;
    } else if (self.currentMode == FLEXExplorerModeSelect && self.selectedView) {
        self.currentMode = FLEXExplorerModeMove;
    }
}

- (void)toggleViewsTool {
    [self toggleViewsToolWithCompletion:nil];
}

- (void)toggleViewsToolWithCompletion:(void(^)(void))completion {
    [self toggleToolWithViewControllerProvider:^UINavigationController *{
        if (self.selectedView) {
            return [FLEXHierarchyViewController
                delegate:self
                viewsAtTap:self.viewsAtTapPoint
                selectedView:self.selectedView
            ];
        } else {
            return [FLEXHierarchyViewController delegate:self];
        }
    } completion:completion];
}

- (void)toggleMenuTool {
    [self toggleToolWithViewControllerProvider:^UINavigationController *{
        return [FLEXNavigationController withRootViewController:[FLEXGlobalsViewController new]];
    } completion:nil];
}

- (BOOL)handleDownArrowKeyPressed {
    if (self.currentMode == FLEXExplorerModeMove) {
        CGRect frame = self.selectedView.frame;
        frame.origin.y += 1.0 / self.traitCollection.displayScale;
        self.selectedView.frame = frame;
    } else if (self.currentMode == FLEXExplorerModeSelect && self.viewsAtTapPoint.count > 0) {
        NSInteger selectedViewIndex = [self.viewsAtTapPoint indexOfObject:self.selectedView];
        if (selectedViewIndex > 0) {
            self.selectedView = [self.viewsAtTapPoint objectAtIndex:selectedViewIndex - 1];
        }
    } else {
        return NO;
    }

    return YES;
}

- (BOOL)handleUpArrowKeyPressed {
    if (self.currentMode == FLEXExplorerModeMove) {
        CGRect frame = self.selectedView.frame;
        frame.origin.y -= 1.0 / self.traitCollection.displayScale;
        self.selectedView.frame = frame;
    } else if (self.currentMode == FLEXExplorerModeSelect && self.viewsAtTapPoint.count > 0) {
        NSInteger selectedViewIndex = [self.viewsAtTapPoint indexOfObject:self.selectedView];
        if (selectedViewIndex < self.viewsAtTapPoint.count - 1) {
            self.selectedView = [self.viewsAtTapPoint objectAtIndex:selectedViewIndex + 1];
        }
    } else {
        return NO;
    }

    return YES;
}

- (BOOL)handleRightArrowKeyPressed {
    if (self.currentMode == FLEXExplorerModeMove) {
        CGRect frame = self.selectedView.frame;
        frame.origin.x += 1.0 / self.traitCollection.displayScale;
        self.selectedView.frame = frame;
        return YES;
    }

    return NO;
}

- (BOOL)handleLeftArrowKeyPressed {
    if (self.currentMode == FLEXExplorerModeMove) {
        CGRect frame = self.selectedView.frame;
        frame.origin.x -= 1.0 / self.traitCollection.displayScale;
        self.selectedView.frame = frame;
        return YES;
    }

    return NO;
}

@end
