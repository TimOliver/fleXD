//
//  NSUserDefaults+FLEX.h
//  FLEX
//
//  Created by Tanner on 3/10/20.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// Raw keys, for use when the typed accessors are insufficient.
extern NSString * const kFLEXDefaultsToolbarTopMarginKey;
extern NSString * const kFLEXDefaultsiOSPersistentOSLogKey;
extern NSString * const kFLEXDefaultsHidePropertyIvarsKey;
extern NSString * const kFLEXDefaultsHidePropertyMethodsKey;
extern NSString * const kFLEXDefaultsHidePrivateMethodsKey;
extern NSString * const kFLEXDefaultsShowMethodOverridesKey;
extern NSString * const kFLEXDefaultsHideVariablePreviewsKey;
extern NSString * const kFLEXDefaultsNetworkObserverEnabledKey;
extern NSString * const kFLEXDefaultsNetworkHostDenylistKey;
extern NSString * const kFLEXDefaultsDisableOSLogForceASLKey;
extern NSString * const kFLEXDefaultsAPNSCaptureEnabledKey;
extern NSString * const kFLEXDefaultsRegisterJSONExplorerKey;

/// Typed accessors for FLEX's user defaults preferences.
/// All \c BOOL preferences default to \c NO.
@interface NSUserDefaults (FLEX)

/// Toggles the boolean value stored for the given key.
- (void)flex_toggleBoolForKey:(NSString *)key;

/// The vertical offset of the FLEX explorer toolbar from the top of the screen.
@property (nonatomic) double flex_toolbarTopMargin;

/// Whether network request observation is enabled.
@property (nonatomic) BOOL flex_networkObserverEnabled;

/// The list of network hosts whose requests are excluded from logging.
/// @note Not stored in user defaults; persisted to a separate file on disk.
@property (nonatomic) NSArray<NSString *> *flex_networkHostDenylist;

/// Whether to register the object explorer as a JSON viewer on launch.
@property (nonatomic) BOOL flex_registerDictionaryJSONViewerOnLaunch;

/// The index of the last selected screen in the network observer.
@property (nonatomic) NSInteger flex_lastNetworkObserverMode;

/// Whether to disable \c os_log and re-enable ASL. May affect Console.app output.
@property (nonatomic) BOOL flex_disableOSLog;
/// Whether to cache \c os_log messages for display in the system log viewer.
@property (nonatomic) BOOL flex_cacheOSLogMessages;

/// Whether APNS push notification capture is enabled.
@property (nonatomic) BOOL flex_enableAPNSCapture;

/// Whether the object explorer hides backing ivars for properties.
@property (nonatomic) BOOL flex_explorerHidesPropertyIvars;
/// Whether the object explorer hides getter/setter methods for properties.
@property (nonatomic) BOOL flex_explorerHidesPropertyMethods;
/// Whether the object explorer hides methods whose names begin with an underscore.
@property (nonatomic) BOOL flex_explorerHidesPrivateMethods;
/// Whether the object explorer shows which methods override a superclass implementation.
@property (nonatomic) BOOL flex_explorerShowsMethodOverrides;
/// Whether the object explorer hides live value previews for properties and ivars.
@property (nonatomic) BOOL flex_explorerHidesVariablePreviews;

@end

NS_ASSUME_NONNULL_END
