//
//  FLEXGlobalsEntry.h
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

typedef NS_ENUM(NSUInteger, FLEXGlobalsRow) {
    FLEXGlobalsRowProcessInfo,
    FLEXGlobalsRowNetworkHistory,
    FLEXGlobalsRowSystemLog,
    FLEXGlobalsRowLiveObjects,
    FLEXGlobalsRowAddressInspector,
    FLEXGlobalsRowCookies,
    FLEXGlobalsRowBrowseRuntime,
    FLEXGlobalsRowAppKeychainItems,
    FLEXGlobalsRowPushNotifications,
    FLEXGlobalsRowAppDelegate,
    FLEXGlobalsRowRootViewController,
    FLEXGlobalsRowUserDefaults,
    FLEXGlobalsRowMainBundle,
    FLEXGlobalsRowBrowseBundle,
    FLEXGlobalsRowBrowseContainer,
    FLEXGlobalsRowApplication,
    FLEXGlobalsRowKeyWindow,
    FLEXGlobalsRowMainScreen,
    FLEXGlobalsRowCurrentDevice,
    FLEXGlobalsRowPasteboard,
    FLEXGlobalsRowURLSession,
    FLEXGlobalsRowURLCache,
    FLEXGlobalsRowNotificationCenter,
    FLEXGlobalsRowFileManager,
    FLEXGlobalsRowTimeZone,
    FLEXGlobalsRowLocale,
    FLEXGlobalsRowCalendar,
    FLEXGlobalsRowMainRunLoop,
    FLEXGlobalsRowMainThread,
    FLEXGlobalsRowOperationQueue,
    FLEXGlobalsRowCount
};

typedef NSString * _Nonnull (^FLEXGlobalsEntryNameFuture)(void);
/// Simply return a view controller to be pushed on the navigation stack
typedef UIViewController * _Nullable (^FLEXGlobalsEntryViewControllerFuture)(void);
/// Do something like present an alert, then use the host
/// view controller to present or push another view controller.
typedef void (^FLEXGlobalsEntryRowAction)(__kindof UITableViewController * _Nonnull host);

/// For view controllers to conform to to indicate they support being used
/// in the globals table view controller. These methods help create concrete entries.
///
/// Previously, the concrete entries relied on "futures" for the view controller and title.
/// With this protocol, the conforming class itself can act as a future, since the methods
/// will not be invoked until the title and view controller / row action are needed.
///
/// Entries can implement `globalsEntryViewController:` to unconditionally provide a
/// view controller, or `globalsEntryRowAction:` to conditionally provide one and
/// perform some action (such as present an alert) if no view controller is available,
/// or both if there is a mix of rows where some are guaranteed to work and some are not.
/// Where both are implemented, `globalsEntryRowAction:` takes precedence; if it returns
/// an action for the requested row, that will be used instead of `globalsEntryViewController:`
@protocol FLEXGlobalsEntry <NSObject>

+ (NSString *)globalsEntryTitle:(FLEXGlobalsRow)row;

/// Must respond to at least one of the following.
/// If both are implemented, `globalsEntryRowAction:` takes precedence.
@optional

+ (nullable UIViewController *)globalsEntryViewController:(FLEXGlobalsRow)row;
+ (nullable FLEXGlobalsEntryRowAction)globalsEntryRowAction:(FLEXGlobalsRow)row;

@end

@interface FLEXGlobalsEntry : NSObject

@property (nonatomic, readonly, nonnull) FLEXGlobalsEntryNameFuture entryNameFuture;
@property (nonatomic, readonly, nullable) FLEXGlobalsEntryViewControllerFuture viewControllerFuture;
@property (nonatomic, readonly, nullable) FLEXGlobalsEntryRowAction rowAction;

+ (instancetype)entryWithEntry:(Class<FLEXGlobalsEntry>)entry row:(FLEXGlobalsRow)row;

+ (instancetype)entryWithNameFuture:(FLEXGlobalsEntryNameFuture)nameFuture
               viewControllerFuture:(FLEXGlobalsEntryViewControllerFuture)viewControllerFuture;

+ (instancetype)entryWithNameFuture:(FLEXGlobalsEntryNameFuture)nameFuture
                             action:(FLEXGlobalsEntryRowAction)rowSelectedAction;

@end


@interface NSObject (FLEXGlobalsEntry)

/// @return The result of passing self to +[FLEXGlobalsEntry entryWithEntry:]
/// if the class conforms to FLEXGlobalsEntry, else, nil.
+ (nullable FLEXGlobalsEntry *)flex_concreteGlobalsEntry:(FLEXGlobalsRow)row;

@end

NS_ASSUME_NONNULL_END
