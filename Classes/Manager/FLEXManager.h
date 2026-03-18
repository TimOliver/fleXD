//
//  FLEXManager.h
//  FLEX
//
//  Created by Ryan Olson on 4/4/14.
//  Copyright (c) 2020 FLEX Team. All rights reserved.
//

#import "FLEXExplorerToolbar.h"

NS_ASSUME_NONNULL_BEGIN

/// A block that creates and returns a view controller for displaying
/// custom content of the given type, or `nil` if the content cannot be displayed.
typedef UIViewController * _Nullable (^FLEXCustomContentViewerFuture)(NSData *data);

/// The primary interface for configuring and controlling FLEX.
@interface FLEXManager : NSObject

/// The shared FLEX manager instance.
@property (nonatomic, readonly, class) FLEXManager *sharedManager;

/// Whether the FLEX explorer toolbar is currently hidden.
@property (nonatomic, readonly) BOOL isHidden;

/// The FLEX explorer toolbar. Visible whenever FLEX is shown.
@property (nonatomic, readonly) FLEXExplorerToolbar *toolbar;

#pragma mark - Showing and Hiding

/// Shows the FLEX explorer toolbar.
- (void)showExplorer;
/// Hides the FLEX explorer toolbar and dismisses any presented tools.
- (void)hideExplorer;
/// Toggles the visibility of the FLEX explorer toolbar.
- (void)toggleExplorer;

/// Presents the FLEX explorer in the specified scene.
///
/// Use this when the scene FLEX would select by default is not the one
/// you want it to appear in.
- (void)showExplorerFromScene:(UIWindowScene *)scene;

#pragma mark - Presenting Tools

/// Programmatically dismisses anything currently presented by FLEX,
/// leaving only the explorer toolbar visible.
- (void)dismissAnyPresentedTools:(void (^_Nullable)(void))completion;

/// Presents a custom navigation controller on top of the FLEX toolbar.
///
/// Any currently presented tool is automatically dismissed first,
/// so you do not need to call `dismissAnyPresentedTools:` beforehand.
- (void)presentTool:(UINavigationController *(^)(void))viewControllerFuture
         completion:(void (^_Nullable)(void))completion;

/// Wraps the given view controller in a navigation controller and presents it
/// on top of the FLEX toolbar. The completion block receives the new navigation controller.
- (void)presentEmbeddedTool:(UIViewController *)viewController
                 completion:(void (^_Nullable)(UINavigationController *))completion;

/// Presents an object explorer for the given object on top of the FLEX toolbar.
/// The completion block receives the new navigation controller.
- (void)presentObjectExplorer:(id)object
                   completion:(void (^_Nullable)(UINavigationController *))completion;

#pragma mark - Miscellaneous

/// The password used when opening SQLite databases. Defaults to `nil`
@property (copy, nonatomic) NSString *defaultSqliteDatabasePassword;

@end

NS_ASSUME_NONNULL_END
