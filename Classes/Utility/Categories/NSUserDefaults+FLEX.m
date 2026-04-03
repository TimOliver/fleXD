//
//  NSUserDefaults+FLEX.m
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

#import "NSUserDefaults+FLEX.h"

NSString * const kFLEXDefaultsToolbarTopMarginKey = @"com.flex.FLEXToolbar.topMargin";
NSString * const kFLEXDefaultsToolbarLeftMarginKey = @"com.flex.FLEXToolbar.leftMargin";
NSString * const kFLEXDefaultsiOSPersistentOSLogKey = @"com.flipborad.flex.enable_persistent_os_log";
NSString * const kFLEXDefaultsHidePropertyIvarsKey = @"com.flipboard.FLEX.hide_property_ivars";
NSString * const kFLEXDefaultsHidePropertyMethodsKey = @"com.flipboard.FLEX.hide_property_methods";
NSString * const kFLEXDefaultsHidePrivateMethodsKey = @"com.flipboard.FLEX.hide_private_or_namespaced_methods";
NSString * const kFLEXDefaultsShowMethodOverridesKey = @"com.flipboard.FLEX.show_method_overrides";
NSString * const kFLEXDefaultsHideVariablePreviewsKey = @"com.flipboard.FLEX.hide_variable_previews";
NSString * const kFLEXDefaultsNetworkObserverEnabledKey = @"com.flex.FLEXNetworkObserver.enableOnLaunch";
NSString * const kFLEXDefaultsNetworkObserverLastModeKey = @"com.flex.FLEXNetworkObserver.lastMode";
NSString * const kFLEXDefaultsNetworkHostDenylistKey = @"com.flipboard.FLEX.network_host_denylist";
NSString * const kFLEXDefaultsAPNSCaptureEnabledKey = @"com.flipboard.FLEX.capture_apns";
NSString * const kFLEXDefaultsRegisterJSONExplorerKey = @"com.flipboard.FLEX.view_json_as_object";

#define FLEXDefaultsPathForFile(name) ({ \
    NSArray *paths = NSSearchPathForDirectoriesInDomains( \
        NSLibraryDirectory, NSUserDomainMask, YES \
    ); \
    [paths[0] stringByAppendingPathComponent:@"Preferences"]; \
})

@implementation NSUserDefaults (FLEX)

#pragma mark Internal

/// @param filename the name of a plist file without any extension
- (NSString *)flex_defaultsPathForFile:(NSString *)filename {
    filename = [filename stringByAppendingPathExtension:@"plist"];

    NSArray<NSString *> *paths = NSSearchPathForDirectoriesInDomains(
        NSLibraryDirectory, NSUserDomainMask, YES
    );
    NSString *preferences = [paths[0] stringByAppendingPathComponent:@"Preferences"];
    return [preferences stringByAppendingPathComponent:filename];
}

#pragma mark Helper

- (void)flex_toggleBoolForKey:(NSString *)key {
    [self setBool:![self boolForKey:key] forKey:key];
    [NSNotificationCenter.defaultCenter postNotificationName:key object:nil];
}

#pragma mark Misc

- (double)flex_toolbarTopMargin {
    if ([self objectForKey:kFLEXDefaultsToolbarTopMarginKey]) {
        return [self doubleForKey:kFLEXDefaultsToolbarTopMarginKey];
    }

    return 100;
}

- (void)setFlex_toolbarTopMargin:(double)margin {
    [self setDouble:margin forKey:kFLEXDefaultsToolbarTopMarginKey];
}

- (double)flex_toolbarLeftMargin {
    if ([self objectForKey:kFLEXDefaultsToolbarLeftMarginKey]) {
        return [self doubleForKey:kFLEXDefaultsToolbarLeftMarginKey];
    }

    return -1;
}

- (void)setFlex_toolbarLeftMargin:(double)margin {
    [self setDouble:margin forKey:kFLEXDefaultsToolbarLeftMarginKey];
}

- (BOOL)flex_networkObserverEnabled {
    return [self boolForKey:kFLEXDefaultsNetworkObserverEnabledKey];
}

- (void)setFlex_networkObserverEnabled:(BOOL)enabled {
    [self setBool:enabled forKey:kFLEXDefaultsNetworkObserverEnabledKey];
}

- (NSArray<NSString *> *)flex_networkHostDenylist {
    return [NSArray arrayWithContentsOfFile:[
        self flex_defaultsPathForFile:kFLEXDefaultsNetworkHostDenylistKey
    ]] ?: @[];
}

- (void)setFlex_networkHostDenylist:(NSArray<NSString *> *)denylist {
    NSParameterAssert(denylist);
    [denylist writeToFile:[
        self flex_defaultsPathForFile:kFLEXDefaultsNetworkHostDenylistKey
    ] atomically:YES];
}

- (BOOL)flex_registerDictionaryJSONViewerOnLaunch {
    return [self boolForKey:kFLEXDefaultsRegisterJSONExplorerKey];
}

- (void)setFlex_registerDictionaryJSONViewerOnLaunch:(BOOL)enable {
    [self setBool:enable forKey:kFLEXDefaultsRegisterJSONExplorerKey];
}

- (NSInteger)flex_lastNetworkObserverMode {
    return [self integerForKey:kFLEXDefaultsNetworkObserverLastModeKey];
}

- (void)setFlex_lastNetworkObserverMode:(NSInteger)mode {
    [self setInteger:mode forKey:kFLEXDefaultsNetworkObserverLastModeKey];
}

#pragma mark System Log

- (BOOL)flex_cacheOSLogMessages {
    return [self boolForKey:kFLEXDefaultsiOSPersistentOSLogKey];
}

- (void)setFlex_cacheOSLogMessages:(BOOL)cache {
    [self setBool:cache forKey:kFLEXDefaultsiOSPersistentOSLogKey];
    [NSNotificationCenter.defaultCenter
        postNotificationName:kFLEXDefaultsiOSPersistentOSLogKey
        object:nil
    ];
}

#pragma mark Push Notifications

- (BOOL)flex_enableAPNSCapture {
    return [self boolForKey:kFLEXDefaultsAPNSCaptureEnabledKey];
}

- (void)setFlex_enableAPNSCapture:(BOOL)enable {
    [self setBool:enable forKey:kFLEXDefaultsAPNSCaptureEnabledKey];
}

#pragma mark Object Explorer

- (BOOL)flex_explorerHidesPropertyIvars {
    return [self boolForKey:kFLEXDefaultsHidePropertyIvarsKey];
}

- (void)setFlex_explorerHidesPropertyIvars:(BOOL)hide {
    [self setBool:hide forKey:kFLEXDefaultsHidePropertyIvarsKey];
    [NSNotificationCenter.defaultCenter
        postNotificationName:kFLEXDefaultsHidePropertyIvarsKey
        object:nil
    ];
}

- (BOOL)flex_explorerHidesPropertyMethods {
    return [self boolForKey:kFLEXDefaultsHidePropertyMethodsKey];
}

- (void)setFlex_explorerHidesPropertyMethods:(BOOL)hide {
    [self setBool:hide forKey:kFLEXDefaultsHidePropertyMethodsKey];
    [NSNotificationCenter.defaultCenter
        postNotificationName:kFLEXDefaultsHidePropertyMethodsKey
        object:nil
    ];
}

- (BOOL)flex_explorerHidesPrivateMethods {
    return [self boolForKey:kFLEXDefaultsHidePrivateMethodsKey];
}

- (void)setFlex_explorerHidesPrivateMethods:(BOOL)show {
    [self setBool:show forKey:kFLEXDefaultsHidePrivateMethodsKey];
    [NSNotificationCenter.defaultCenter
     postNotificationName:kFLEXDefaultsHidePrivateMethodsKey
        object:nil
    ];
}

- (BOOL)flex_explorerShowsMethodOverrides {
    return [self boolForKey:kFLEXDefaultsShowMethodOverridesKey];
}

- (void)setFlex_explorerShowsMethodOverrides:(BOOL)show {
    [self setBool:show forKey:kFLEXDefaultsShowMethodOverridesKey];
    [NSNotificationCenter.defaultCenter
     postNotificationName:kFLEXDefaultsShowMethodOverridesKey
        object:nil
    ];
}

- (BOOL)flex_explorerHidesVariablePreviews {
    return [self boolForKey:kFLEXDefaultsHideVariablePreviewsKey];
}

- (void)setFlex_explorerHidesVariablePreviews:(BOOL)hide {
    [self setBool:hide forKey:kFLEXDefaultsHideVariablePreviewsKey];
    [NSNotificationCenter.defaultCenter
        postNotificationName:kFLEXDefaultsHideVariablePreviewsKey
        object:nil
    ];
}

@end
