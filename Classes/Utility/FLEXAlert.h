//
//  FLEXAlert.h
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

NS_ASSUME_NONNULL_BEGIN

@class FLEXAlert, FLEXAlertAction;

typedef void (^FLEXAlertReveal)(void);
typedef void (^FLEXAlertBuilder)(FLEXAlert *make);
typedef FLEXAlert * _Nonnull (^FLEXAlertStringProperty)(NSString * _Nullable);
typedef FLEXAlert * _Nonnull (^FLEXAlertStringArg)(NSString * _Nullable);
typedef FLEXAlert * _Nonnull (^FLEXAlertTextField)(void(^configurationHandler)(UITextField *textField));
typedef FLEXAlertAction * _Nonnull (^FLEXAlertAddAction)(NSString *title);
typedef FLEXAlertAction * _Nonnull (^FLEXAlertActionStringProperty)(NSString * _Nullable);
typedef FLEXAlertAction * _Nonnull (^FLEXAlertActionProperty)(void);
typedef FLEXAlertAction * _Nonnull (^FLEXAlertActionBOOLProperty)(BOOL);
typedef FLEXAlertAction * _Nonnull (^FLEXAlertActionHandler)(void(^handler)(NSArray<NSString *> *strings));

/// A builder-pattern wrapper around `UIAlertController`
///
/// Use the block-based factory methods to construct and present alerts,
/// chaining property accesses to set the title, message, buttons, and text fields.
@interface FLEXAlert : NSObject

/// Shows a simple alert with one button which says "Dismiss"
+ (void)showAlert:(NSString * _Nullable)title message:(NSString * _Nullable)message from:(UIViewController *)viewController;

/// Shows a simple alert with no buttons and only a title, for half a second
+ (void)showQuickAlert:(NSString *)title from:(UIViewController *)viewController;

/// Construct and display an alert
+ (void)makeAlert:(FLEXAlertBuilder)block showFrom:(UIViewController *)viewController;
/// Construct and display an action sheet-style alert
+ (void)makeSheet:(FLEXAlertBuilder)block
         showFrom:(UIViewController *)viewController
           source:(id)viewOrBarItem;

/// Construct an alert
+ (UIAlertController *)makeAlert:(FLEXAlertBuilder)block;
/// Construct an action sheet-style alert
+ (UIAlertController *)makeSheet:(FLEXAlertBuilder)block;

/// Set the alert's title.
///
/// Call in succession to append strings to the title.
@property (nonatomic, readonly) FLEXAlertStringProperty title;
/// Set the alert's message.
///
/// Call in succession to append strings to the message.
@property (nonatomic, readonly) FLEXAlertStringProperty message;
/// Add a button with a given title with the default style and no action.
@property (nonatomic, readonly) FLEXAlertAddAction button;
/// Add a text field with the given (optional) placeholder text.
@property (nonatomic, readonly) FLEXAlertStringArg textField;
/// Add and configure the given text field.
///
/// Use this if you need to more than set the placeholder, such as
/// supply a delegate, make it secure entry, or change other attributes.
@property (nonatomic, readonly) FLEXAlertTextField configuredTextField;

@end

@interface FLEXAlertAction : NSObject

/// Set the action's title.
///
/// Call in succession to append strings to the title.
@property (nonatomic, readonly) FLEXAlertActionStringProperty title;
/// Make the action destructive. It appears with red text.
@property (nonatomic, readonly) FLEXAlertActionProperty destructiveStyle;
/// Make the action cancel-style. It sometimes appears with a bolder font.
@property (nonatomic, readonly) FLEXAlertActionProperty cancelStyle;
/// Make the action the preferred action. It appears with a bolder font.
/// The first action that is set as preferred will be used as the preferred action.
@property (nonatomic, readonly) FLEXAlertActionProperty preferred;
/// Enable or disable the action. Enabled by default.
@property (nonatomic, readonly) FLEXAlertActionBOOLProperty enabled;
/// Give the button an action. The action takes an array of text field strings.
@property (nonatomic, readonly) FLEXAlertActionHandler handler;
/// Access the underlying UIAlertAction, should you need to change it while
/// the encompassing alert is being displayed. For example, you may want to
/// enable or disable a button based on the input of some text fields in the alert.
/// Do not call this more than once per instance.
@property (nonatomic, readonly) UIAlertAction *action;

@end

NS_ASSUME_NONNULL_END
