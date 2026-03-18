//
//  FLEXDefaultsContentSection.h
//  FLEX
//
//  Created by Tanner Bennett on 8/28/19.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

#import "FLEXCollectionContentSection.h"
#import "FLEXObjectInfoSection.h"

NS_ASSUME_NONNULL_BEGIN

/// A collection section for browsing the contents of an \c NSUserDefaults suite.
@interface FLEXDefaultsContentSection : FLEXCollectionContentSection <FLEXObjectInfoSection>

/// Creates a section backed by \c NSUserDefaults.standardUserDefaults.
+ (instancetype)standard;

/// Creates a section backed by the given \c NSUserDefaults suite.
+ (instancetype)forDefaults:(NSUserDefaults *)userDefaults;

/// Whether to filter out keys not present in the app's own defaults file.
///
/// When enabled, system-injected keys that appear in every app's user defaults
/// but are never written by the app itself are hidden.
/// Only applies to instances using \c NSUserDefaults.standardUserDefaults.
/// Enabled by default for \c standard instances; opt out explicitly if needed.
@property (nonatomic) BOOL onlyShowKeysForAppPrefs;

@end

NS_ASSUME_NONNULL_END
