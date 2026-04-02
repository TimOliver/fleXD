//
//  FLEXVariableEditorViewController.h
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

#import <UIKit/UIKit.h>

@class FLEXFieldEditorView;
@class FLEXArgumentInputView;

NS_ASSUME_NONNULL_BEGIN

/// An abstract screen for editing or configuring one or more variables.
/// "Target" is the target of the edit operation, and "data" is the data
/// you want to mutate or pass to the target when the action is performed.
/// The action may be something like calling a method, setting an ivar, etc.
@interface FLEXVariableEditorViewController : UIViewController {
    @protected
    id _target;
    _Nullable id _data;
    void (^_Nullable _commitHandler)(void);
}

/// @param target The target of the operation
/// @param data The data associated with the operation
/// @param onCommit An action to perform when the data changes 
+ (instancetype)target:(id)target data:(nullable id)data commitHandler:(void(^_Nullable)(void))onCommit;
/// @param target The target of the operation
/// @param data The data associated with the operation
/// @param onCommit An action to perform when the data changes 
- (id)initWithTarget:(id)target data:(nullable id)data commitHandler:(void(^_Nullable)(void))onCommit;

@property (nonatomic, readonly) id target;

/// Convenience accessor since many subclasses only use one input view
@property (nonatomic, readonly, nullable) FLEXArgumentInputView *firstInputView;
@property (nonatomic, readonly) FLEXFieldEditorView *fieldEditorView;

/// Subclasses can change the button title via the button's `title` property
@property (nonatomic, readonly) UIBarButtonItem *actionButton;

/// Subclasses should override to provide "set" functionality.
/// The commit handler--if present--is called here.
- (void)actionButtonPressed:(nullable id)sender;

/// Pushes an explorer view controller for the given object
/// or pops the current view controller.
- (void)exploreObjectOrPopViewController:(nullable id)objectOrNil;

@end

NS_ASSUME_NONNULL_END
