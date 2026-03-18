//
//  FLEXExplorerViewController.h
//  Flipboard
//
//  Created by Ryan Olson on 4/4/14.
//  Copyright (c) 2020 FLEX Team. All rights reserved.
//

#import "FLEXExplorerToolbar.h"

@class FLEXWindow;
@class FLEXExplorerViewController;

@protocol FLEXExplorerViewControllerDelegate <NSObject>
- (void)explorerViewControllerDidFinish:(FLEXExplorerViewController *)explorerViewController;
@end

/// A view controller that manages the FLEX toolbar.
@interface FLEXExplorerViewController : UIViewController

/// The delegate that is notified when the explorer finishes.
@property (nonatomic, weak) id <FLEXExplorerViewControllerDelegate> delegate;
/// Whether the FLEX window should become the key window while the explorer is active.
@property (nonatomic, readonly) BOOL wantsWindowToBecomeKey;
/// The floating toolbar managed by this view controller.
@property (nonatomic, readonly) FLEXExplorerToolbar *explorerToolbar;

/// Returns whether the explorer should receive a touch at the given point in window coordinates.
- (BOOL)shouldReceiveTouchAtWindowPoint:(CGPoint)pointInWindowCoordinates;

/// Toggles a modal tool on or off.
///
/// If a tool is already presented, it is dismissed and the completion block is called.
/// If no tool is presented, `future()` is invoked and the resulting controller is presented.
///
/// @param future A block returning the navigation controller to present.
/// @param completion Called after dismissal or presentation completes.
- (void)toggleToolWithViewControllerProvider:(UINavigationController *(^)(void))future
                                  completion:(void (^)(void))completion;

/// Presents a modal tool, dismissing any currently presented tool first.
///
/// The completion block is called once the new tool has been fully presented.
///
/// @param future A block returning the navigation controller to present.
/// @param completion Called after the tool has been presented.
- (void)presentTool:(UINavigationController *(^)(void))future
         completion:(void (^)(void))completion;

// Keyboard shortcut helpers

- (void)toggleSelectTool;
- (void)toggleMoveTool;
- (void)toggleViewsTool;
- (void)toggleMenuTool;

/// @return YES if the explorer used the key press to perform an action, NO otherwise
- (BOOL)handleDownArrowKeyPressed;
/// @return YES if the explorer used the key press to perform an action, NO otherwise
- (BOOL)handleUpArrowKeyPressed;
/// @return YES if the explorer used the key press to perform an action, NO otherwise
- (BOOL)handleRightArrowKeyPressed;
/// @return YES if the explorer used the key press to perform an action, NO otherwise
- (BOOL)handleLeftArrowKeyPressed;

@end

