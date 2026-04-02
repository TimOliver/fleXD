//
//  FLEXDefaultsContentSection.m
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

#import "FLEXDefaultsContentSection.h"
#import "FLEXDefaultEditorViewController.h"
#import "FLEXUtility.h"

@interface FLEXDefaultsContentSection ()
@property (nonatomic) NSUserDefaults *defaults;
@property (nonatomic) NSArray *keys;
@property (nonatomic, readonly) NSDictionary *unexcludedDefaults;
@end

@implementation FLEXDefaultsContentSection
@synthesize keys = _keys;

#pragma mark Initialization

+ (instancetype)forObject:(id)object {
    return [self forDefaults:object];
}

+ (instancetype)standard {
    return [self forDefaults:NSUserDefaults.standardUserDefaults];
}

+ (instancetype)forDefaults:(NSUserDefaults *)userDefaults {
    FLEXDefaultsContentSection *section = [self forReusableFuture:^id(FLEXDefaultsContentSection *section) {
        section.defaults = userDefaults;
        section.onlyShowKeysForAppPrefs = YES;
        return section.unexcludedDefaults;
    }];
    return section;
}

#pragma mark - Overrides

- (NSString *)title {
    return @"Defaults";
}

- (void (^)(__kindof UIViewController *))didPressInfoButtonAction:(NSInteger)row {
    return ^(UIViewController *host) {
        if ([FLEXDefaultEditorViewController canEditDefaultWithValue:[self objectForRow:row]]) {
            // We use titleForRow: to get the key because self.keys is not
            // necessarily in the same order as the keys being displayed
            FLEXVariableEditorViewController *controller = [FLEXDefaultEditorViewController
                target:self.defaults key:[self titleForRow:row] commitHandler:^{
                    [self reloadData:YES];
                }
            ];
            [host.navigationController pushViewController:controller animated:YES];
        } else {
            [FLEXAlert showAlert:@"Oh No…" message:@"We can't edit this entry :(" from:host];
        }
    };
}

- (UITableViewCellAccessoryType)accessoryTypeForRow:(NSInteger)row {
    return UITableViewCellAccessoryDetailDisclosureButton;
}

#pragma mark - Private

- (NSArray *)keys {
    if (!_keys) {
        if (self.onlyShowKeysForAppPrefs) {
            // Read keys from preferences file
            NSString *bundle = NSBundle.mainBundle.bundleIdentifier;
            NSString *prefsPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Preferences"];
            NSString *filePath = [NSString stringWithFormat:@"%@/%@.plist", prefsPath, bundle];
            self.keys = [NSDictionary dictionaryWithContentsOfFile:filePath].allKeys;
        } else {
            self.keys = self.defaults.dictionaryRepresentation.allKeys;
        }
    }

    return _keys;
}

- (void)setKeys:(NSArray *)keys {
    _keys = [keys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
}

- (NSDictionary *)unexcludedDefaults {
    // Case: no excluding
    if (!self.onlyShowKeysForAppPrefs) {
        return self.defaults.dictionaryRepresentation;
    }

    // Always regenerate key allowlist when this method is called
    _keys = nil;

    // Generate new dictionary from unexcluded keys
    NSArray *values = [self.defaults.dictionaryRepresentation
        objectsForKeys:self.keys notFoundMarker:NSNull.null
    ];
    return [NSDictionary dictionaryWithObjects:values forKeys:self.keys];
}

#pragma mark - Public

- (void)setOnlyShowKeysForAppPrefs:(BOOL)onlyShowKeysForAppPrefs {
    if (onlyShowKeysForAppPrefs) {
        // This property only applies if we're using standardUserDefaults
        if (self.defaults != NSUserDefaults.standardUserDefaults) return;
    }

    _onlyShowKeysForAppPrefs = onlyShowKeysForAppPrefs;
}

@end
