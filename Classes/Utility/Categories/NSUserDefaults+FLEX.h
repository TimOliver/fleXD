//
//  NSUserDefaults+FLEX.h
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

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// Raw keys, for use when the typed accessors are insufficient.
extern NSString * const kFLEXDefaultsToolbarTopMarginKey;
extern NSString * const kFLEXDefaultsToolbarLeftMarginKey;
extern NSString * const kFLEXDefaultsiOSPersistentOSLogKey;
extern NSString * const kFLEXDefaultsHidePropertyIvarsKey;
extern NSString * const kFLEXDefaultsHidePropertyMethodsKey;
extern NSString * const kFLEXDefaultsHidePrivateMethodsKey;
extern NSString * const kFLEXDefaultsShowMethodOverridesKey;
extern NSString * const kFLEXDefaultsHideVariablePreviewsKey;
extern NSString * const kFLEXDefaultsNetworkObserverEnabledKey;
extern NSString * const kFLEXDefaultsNetworkHostDenylistKey;
extern NSString * const kFLEXDefaultsAPNSCaptureEnabledKey;
extern NSString * const kFLEXDefaultsRegisterJSONExplorerKey;

/// Typed accessors for FLEX's user defaults preferences.
/// All `BOOL` preferences default to `NO`
@interface NSUserDefaults (FLEX)

/// Toggles the boolean value stored for the given key.
- (void)flex_toggleBoolForKey:(NSString *)key;

/// The vertical offset of the FLEX explorer toolbar from the top of the screen.
@property (nonatomic) double flex_toolbarTopMargin;

/// The horizontal offset of the FLEX explorer toolbar from the left of the screen.
/// A value of -1 indicates the toolbar has not been positioned yet and should be centered.
@property (nonatomic) double flex_toolbarLeftMargin;

/// Whether network request observation is enabled.
@property (nonatomic) BOOL flex_networkObserverEnabled;

/// The list of network hosts whose requests are excluded from logging.
/// @note Not stored in user defaults; persisted to a separate file on disk.
@property (nonatomic) NSArray<NSString *> *flex_networkHostDenylist;

/// Whether to register the object explorer as a JSON viewer on launch.
@property (nonatomic) BOOL flex_registerDictionaryJSONViewerOnLaunch;

/// The index of the last selected screen in the network observer.
@property (nonatomic) NSInteger flex_lastNetworkObserverMode;

/// Whether to cache `os_log` messages for display in the system log viewer.
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
