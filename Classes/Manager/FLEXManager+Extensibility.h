//
//  FLEXManager+Extensibility.h
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

#import "FLEXManager.h"
#import "FLEXGlobalsEntry.h"

NS_ASSUME_NONNULL_BEGIN

@interface FLEXManager (Extensibility)

#pragma mark - Globals Screen Entries

/// Adds an entry at the top of the list of Global State items.
/// Call this method before this view controller is displayed.
/// @param entryName The string to be displayed in the cell.
/// @param objectFutureBlock When you tap on the row, information about the object returned
/// by this block will be displayed. Passing a block that returns an object allows you to display
/// information about an object whose actual pointer may change at runtime (e.g. +currentUser)
/// @note This method must be called from the main thread.
/// The objectFutureBlock will be invoked from the main thread and may return nil.
/// @note The passed block will be copied and retained for the duration of the application.
/// You may want to use __weak references.
- (void)registerGlobalEntryWithName:(NSString *)entryName objectFutureBlock:(id (^)(void))objectFutureBlock;

/// Adds an entry at the top of the list of Global State items.
/// Call this method before this view controller is displayed.
/// @param entryName The string to be displayed in the cell.
/// @param viewControllerFutureBlock When you tap on the row, view controller returned
/// by this block will be pushed on the navigation controller stack.
/// @note This method must be called from the main thread.
/// The viewControllerFutureBlock will be invoked from the main thread and may not return nil.
/// @note The passed block will be copied and retained for the duration of the application.
/// You may want to use __weak references as needed.
- (void)registerGlobalEntryWithName:(NSString *)entryName
          viewControllerFutureBlock:(UIViewController * (^)(void))viewControllerFutureBlock;

/// Adds an entry at the top of the list of Global State items.
/// @param entryName The string to be displayed in the cell.
/// @param rowSelectedAction When you tap on the row, this block will be invoked
/// with the host table view view controller. Use it to deselect the row or present an alert.
/// @note This method must be called from the main thread.
/// The rowSelectedAction will be invoked from the main thread.
/// @note The passed block will be copied and retained for the duration of the application.
/// You may want to use __weak references as needed.
- (void)registerGlobalEntryWithName:(NSString *)entryName action:(FLEXGlobalsEntryRowAction)rowSelectedAction;

/// Removes all registered global entries.
- (void)clearGlobalEntries;

#pragma mark - Editing

/// Enable displaying ivar names for custom struct types
+ (void)registerFieldNames:(NSArray<NSString *> *)names forTypeEncoding:(NSString *)typeEncoding;

#pragma mark - View Skipping

/// A predicate block that returns YES if the given view should be excluded
/// from FLEX's tap-to-select view picking. Use this to filter out overlay
/// views, system containers, or any views you don't want selectable.
///
/// Example — exclude views whose class name contains certain substrings:
/// @code
/// [FLEXManager setSkippedViewPredicate:^BOOL(UIView *view) {
///     NSString *className = NSStringFromClass([view class]);
///     return [className containsString:@"FloatingBarHostingView"]
///         || [className containsString:@"_UITabBarContainerView"];
/// }];
/// @endcode
typedef BOOL(^FLEXViewFilterPredicate)(UIView *view);

/// Set a predicate that determines which views are excluded from tap-to-select.
/// The predicate is called for each candidate view; return YES to exclude it.
+ (void)setSkippedViewPredicate:(nullable FLEXViewFilterPredicate)predicate;

/// Returns the current skipped-view predicate, or nil if none is set.
+ (nullable FLEXViewFilterPredicate)skippedViewPredicate;

#pragma mark - Simulator Shortcuts

/// Simulator keyboard shortcuts are enabled by default.
/// The shortcuts will not fire when there is an active text field, text view, or other responder
/// accepting key input. You can disable keyboard shortcuts if you have existing keyboard shortcuts
/// that conflict with FLEX, or if you like doing things the hard way ;)
/// Keyboard shortcuts are always disabled (and support is #if'd out) in non-simulator builds
@property (nonatomic) BOOL simulatorShortcutsEnabled;

/// Adds an action to run when the specified key & modifier combination is pressed
/// @param key A single character string matching a key on the keyboard
/// @param modifiers Modifier keys such as shift, command, or alt/option
/// @param action The block to run on the main thread when the key & modifier combination is recognized.
/// @param description Shown in the keyboard shortcut help menu, which is accessed via the '?' key.
/// @note The action block will be retained for the duration of the application. You may want to use weak references.
/// @note FLEX registers several default keyboard shortcuts. Use the '?' key to see a list of shortcuts.
- (void)registerSimulatorShortcutWithKey:(NSString *)key
                               modifiers:(UIKeyModifierFlags)modifiers
                                  action:(dispatch_block_t)action
                             description:(NSString *)description;

@end

NS_ASSUME_NONNULL_END
