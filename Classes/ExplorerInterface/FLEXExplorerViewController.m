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
/// Gesture recognizer for cycling through views under the selection point.
@property (nonatomic) UIPanGestureRecognizer *changeSelectedViewPanGR;

/// Only valid while a move pan gesture is in progress.
@property (nonatomic) CGRect selectedViewFrameBeforeDragging;

/// The touch offset from the toolbar's center when drag begins.
@property (nonatomic) UIOffset toolbarDragOffset;

/// UIKit Dynamics animator for toolbar momentum after release.
@property (nonatomic) UIDynamicAnimator *toolbarAnimator;

/// Only valid while a selected view pan gesture is in progress.
@property (nonatomic) CGFloat selectedViewLastPanX;

/// Borders of all the visible views in the hierarchy at the selection point.
/// The keys are NSValues with the corresponding view (nonretained).
@property (nonatomic) NSDictionary<NSValue *, UIView *> *outlineViewsForVisibleViews;

/// The actual views at the selection point with the deepest view last.
@property (nonatomic) NSArray<UIView *> *viewsAtTapPoint;

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
            [self.toolbarAnimator removeAllBehaviors];

            CGPoint toolbarCenter = self.explorerToolbar.center;
            self.toolbarDragOffset = UIOffsetMake(
                touchLocation.x - toolbarCenter.x,
                touchLocation.y - toolbarCenter.y
            );
            break;
        }

        case UIGestureRecognizerStateChanged: {
            [self updateToolbarPositionWithUnconstrainedFrame:[self toolbarFrameForTouchLocation:touchLocation]];
            break;
        }

        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
            [self updateToolbarPositionWithUnconstrainedFrame:[self toolbarFrameForTouchLocation:touchLocation]];
            [self applyToolbarMomentumWithVelocity:[panGR velocityInView:self.view]];
            break;

        default:
            break;
    }
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
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
    CGRect frame = self.explorerToolbar.frame;
    NSUserDefaults.standardUserDefaults.flex_toolbarTopMargin = frame.origin.y;
    NSUserDefaults.standardUserDefaults.flex_toolbarLeftMargin = frame.origin.x;
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

    const CGFloat minY = CGRectGetMinY(safeArea) + kToolbarSafeAreaPadding;
    const CGFloat maxY = CGRectGetMaxY(safeArea) - unconstrainedFrame.size.height - kToolbarSafeAreaPadding;
    if (maxY < minY) {
        unconstrainedFrame.origin.y = FLEXFloor(CGRectGetMidY(safeArea) - unconstrainedFrame.size.height / 2.0);
    } else if (unconstrainedFrame.origin.y < minY) {
        unconstrainedFrame.origin.y = minY;
    } else if (unconstrainedFrame.origin.y > maxY) {
        unconstrainedFrame.origin.y = maxY;
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
    UIWindow *windowForSelection = FLEXUtility.appKeyWindow;
    for (UIWindow *window in FLEXUtility.allWindows.reverseObjectEnumerator) {
        // Ignore the explorer's own window.
        if (window != self.view.window) {
            if ([window hitTest:tapPointInWindow withEvent:nil]) {
                windowForSelection = window;
                break;
            }
        }
    }

    // Select the deepest visible view at the tap point. This generally corresponds to what the user wants to select.
    return [self recursiveSubviewsAtPoint:tapPointInWindow inView:windowForSelection skipHiddenViews:YES].lastObject;
}

- (NSArray<UIView *> *)recursiveSubviewsAtPoint:(CGPoint)pointInView
                                         inView:(UIView *)view
                                skipHiddenViews:(BOOL)skipHidden {
    NSMutableArray<UIView *> *subviewsAtPoint = [NSMutableArray new];
    for (UIView *subview in view.subviews) {
        const BOOL isHidden = subview.hidden || subview.alpha < 0.01;
        if (skipHidden && isHidden) {
            continue;
        }

        const BOOL subviewContainsPoint = CGRectContainsPoint(subview.frame, pointInView);
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
    UIEdgeInsets insets = self.view.safeAreaInsets;
    insets.bottom = 0.0f;
    return UIEdgeInsetsInsetRect(self.view.bounds, insets);
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

    // Always if we're in selection mode
    if (self.currentMode == FLEXExplorerModeSelect) {
        return YES;
    }

    // Always in move mode too
    if (self.currentMode == FLEXExplorerModeMove) {
        return YES;
    }

    // Always if it's on the toolbar (use pointInside: to include the overhanging close button)
    CGPoint pointInToolbar = [self.explorerToolbar convertPoint:pointInLocalCoordinates fromView:self.view];
    if ([self.explorerToolbar pointInside:pointInToolbar withEvent:nil]) {
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
                                  completion:(void (^)(void))completion {
    if (self.presentedViewController) {
        // We do NOT want to present the future; this is
        // a convenience method for toggling the SAME TOOL
        [self dismissViewControllerAnimated:YES completion:completion];
    } else if (future) {
        [self presentViewController:future() animated:YES completion:completion];
    }
}

- (void)presentTool:(UINavigationController *(^)(void))future
         completion:(void (^)(void))completion {
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
