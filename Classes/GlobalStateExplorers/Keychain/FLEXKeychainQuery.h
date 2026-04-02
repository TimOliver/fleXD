//
//  FLEXKeychainQuery.h
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
#import <Security/Security.h>

#if __IPHONE_7_0 || __MAC_10_9
// Keychain synchronization available at compile time
#define FLEXKEYCHAIN_SYNCHRONIZATION_AVAILABLE 1
#endif

#if __IPHONE_3_0 || __MAC_10_9
// Keychain access group available at compile time
#define FLEXKEYCHAIN_ACCESS_GROUP_AVAILABLE 1
#endif

#ifdef FLEXKEYCHAIN_SYNCHRONIZATION_AVAILABLE
typedef NS_ENUM(NSUInteger, FLEXKeychainQuerySynchronizationMode) {
    FLEXKeychainQuerySynchronizationModeAny,
    FLEXKeychainQuerySynchronizationModeNo,
    FLEXKeychainQuerySynchronizationModeYes
};
#endif

/// Simple interface for querying or modifying keychain items.
@interface FLEXKeychainQuery : NSObject

/// kSecAttrAccount
@property (nonatomic, copy) NSString *account;

/// kSecAttrService
@property (nonatomic, copy) NSString *service;

/// kSecAttrLabel
@property (nonatomic, copy) NSString *label;

#ifdef FLEXKEYCHAIN_ACCESS_GROUP_AVAILABLE
/// kSecAttrAccessGroup (only used on iOS)
@property (nonatomic, copy) NSString *accessGroup;
#endif

#ifdef FLEXKEYCHAIN_SYNCHRONIZATION_AVAILABLE
/// kSecAttrSynchronizable
@property (nonatomic) FLEXKeychainQuerySynchronizationMode synchronizationMode;
#endif

/// Root storage for password information
@property (nonatomic, copy) NSData *passwordData;

/// This property automatically transitions between an object and the value of
/// `passwordData` using NSKeyedArchiver and NSKeyedUnarchiver.
@property (nonatomic, copy) id<NSCoding> passwordObject;

/// Convenience accessor for setting and getting a password string. Passes through
/// to `passwordData` using UTF-8 string encoding.
@property (nonatomic, copy) NSString *password;


#pragma mark Saving & Deleting

/// Save the receiver's attributes as a keychain item. Existing items with the
/// given account, service, and access group will first be deleted.
///
/// @param error Populated should an error occur.
/// @return `YES` if saving was successful, `NO` otherwise.
- (BOOL)save:(NSError **)error;

/// Delete keychain items that match the given account, service, and access group.
///
/// @param error Populated should an error occur.
/// @return `YES` if saving was successful, `NO` otherwise.
- (BOOL)deleteItem:(NSError **)error;


#pragma mark Fetching

/// Fetch all keychain items that match the given account, service, and access
/// group. The values of `password` and `passwordData` are ignored when fetching.
///
/// @param error Populated should an error occur.
/// @return An array of dictionaries that represent all matching keychain items,
/// or `nil` should an error occur. The order of the items is not determined.
- (NSArray<NSDictionary<NSString *, id> *> *)fetchAll:(NSError **)error;

/// Fetch the keychain item that matches the given account, service, and access
/// group. The `password` and `passwordData` properties will be populated unless
/// an error occurs. The values of `password` and `passwordData` are ignored when
/// fetching.
///
/// @param error Populated should an error occur.
/// @return `YES` if fetching was successful, `NO` otherwise.
- (BOOL)fetch:(NSError **)error;


#pragma mark Synchronization Status

#ifdef FLEXKEYCHAIN_SYNCHRONIZATION_AVAILABLE
/// Returns a boolean indicating if keychain synchronization is available on the device at runtime.
/// The #define FLEXKEYCHAIN_SYNCHRONIZATION_AVAILABLE is only for compile time.
/// If you are checking for the presence of synchronization, you should use this method.
///
/// @return A value indicating if keychain synchronization is available
+ (BOOL)isSynchronizationAvailable;
#endif

@end
