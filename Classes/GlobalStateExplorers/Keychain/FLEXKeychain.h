//
//  FLEXKeychain.h
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

/// Error code specific to FLEXKeychain that can be returned in NSError objects.
/// For codes returned by the operating system, refer to SecBase.h for your
/// platform.
typedef NS_ENUM(OSStatus, FLEXKeychainErrorCode) {
    /// Some of the arguments were invalid.
    FLEXKeychainErrorBadArguments = -1001,
};

/// FLEXKeychain error domain
extern NSString *const kFLEXKeychainErrorDomain;

/// Account name.
extern NSString *const kFLEXKeychainAccountKey;

/// Time the item was created.
///
/// The value will be a string.
extern NSString *const kFLEXKeychainCreatedAtKey;

/// Item class.
extern NSString *const kFLEXKeychainClassKey;

/// Item description.
extern NSString *const kFLEXKeychainDescriptionKey;

/// Item group.
extern NSString *const kFLEXKeychainGroupKey;

/// Item label.
extern NSString *const kFLEXKeychainLabelKey;

/// Time the item was last modified.
///
/// The value will be a string.
extern NSString *const kFLEXKeychainLastModifiedKey;

/// Where the item was created.
extern NSString *const kFLEXKeychainWhereKey;

/// A simple wrapper for accessing accounts, getting passwords,
/// setting passwords, and deleting passwords using the system Keychain.
@interface FLEXKeychain : NSObject

#pragma mark - Classic methods

/// @param serviceName The service for which to return the corresponding password.
/// @param account The account for which to return the corresponding password.
/// @return Returns a string containing the password for a given account and service,
/// or `nil` if the Keychain doesn't have a password for the given parameters.
+ (NSString *)passwordForService:(NSString *)serviceName account:(NSString *)account;
+ (NSString *)passwordForService:(NSString *)serviceName account:(NSString *)account error:(NSError **)error;

/// Returns a nsdata containing the password for a given account and service,
/// or `nil` if the Keychain doesn't have a password for the given parameters.
///
/// @param serviceName The service for which to return the corresponding password.
/// @param account The account for which to return the corresponding password.
/// @return Returns a nsdata containing the password for a given account and service,
/// or `nil` if the Keychain doesn't have a password for the given parameters.
+ (NSData *)passwordDataForService:(NSString *)serviceName account:(NSString *)account;
+ (NSData *)passwordDataForService:(NSString *)serviceName account:(NSString *)account error:(NSError **)error;


/// Deletes a password from the Keychain.
///
/// @param serviceName The service for which to delete the corresponding password.
/// @param account The account for which to delete the corresponding password.
/// @return Returns `YES` on success, or `NO` on failure.
+ (BOOL)deletePasswordForService:(NSString *)serviceName account:(NSString *)account;
+ (BOOL)deletePasswordForService:(NSString *)serviceName account:(NSString *)account error:(NSError **)error;


/// Sets a password in the Keychain.
///
/// @param password The password to store in the Keychain.
/// @param serviceName The service for which to set the corresponding password.
/// @param account The account for which to set the corresponding password.
/// @return Returns `YES` on success, or `NO` on failure.
+ (BOOL)setPassword:(NSString *)password forService:(NSString *)serviceName account:(NSString *)account;
+ (BOOL)setPassword:(NSString *)password forService:(NSString *)serviceName account:(NSString *)account error:(NSError **)error;

/// Sets a password in the Keychain.
///
/// @param password The password to store in the Keychain.
/// @param serviceName The service for which to set the corresponding password.
/// @param account The account for which to set the corresponding password.
/// @return Returns `YES` on success, or `NO` on failure.
+ (BOOL)setPasswordData:(NSData *)password forService:(NSString *)serviceName account:(NSString *)account;
+ (BOOL)setPasswordData:(NSData *)password forService:(NSString *)serviceName account:(NSString *)account error:(NSError **)error;

/// @return An array of dictionaries containing the Keychain's accounts, or `nil` if
/// the Keychain doesn't have any accounts. The order of the objects in the array isn't defined.
///
/// @note See the `NSString` constants declared in FLEXKeychain.h for a list of keys that
/// can be used when accessing the dictionaries returned by this method.
+ (NSArray<NSDictionary<NSString *, id> *> *)allAccounts;
+ (NSArray<NSDictionary<NSString *, id> *> *)allAccounts:(NSError *__autoreleasing *)error;

/// @param serviceName The service for which to return the corresponding accounts.
/// @return An array of dictionaries containing the Keychain's accounts for a given `serviceName`,
/// or `nil` if the Keychain doesn't have any accounts for the given `serviceName`.
/// The order of the objects in the array isn't defined.
///
/// @note See the `NSString` constants declared in FLEXKeychain.h for a list of keys that
/// can be used when accessing the dictionaries returned by this method.
+ (NSArray<NSDictionary<NSString *, id> *> *)accountsForService:(NSString *)serviceName;
+ (NSArray<NSDictionary<NSString *, id> *> *)accountsForService:(NSString *)serviceName error:(NSError *__autoreleasing *)error;


#pragma mark - Configuration

#if __IPHONE_4_0 && TARGET_OS_IPHONE
/// Returns the accessibility type for all future passwords saved to the Keychain.
///
/// @return `NULL` or one of the "Keychain Item Accessibility
/// Constants" used for determining when a keychain item should be readable.
+ (CFTypeRef)accessibilityType;

/// Sets the accessibility type for all future passwords saved to the Keychain.
///
/// @param accessibilityType One of the "Keychain Item Accessibility Constants"
/// used for determining when a keychain item should be readable.
/// If the value is `NULL` (the default), the Keychain default will be used which
/// is highly insecure. You really should use at least `kSecAttrAccessibleAfterFirstUnlock`
/// for background applications or `kSecAttrAccessibleWhenUnlocked` for all
/// other applications.
///
/// @note See Security/SecItem.h
+ (void)setAccessibilityType:(CFTypeRef)accessibilityType;
#endif

@end

