//
//  FLEXKeychain.m
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

#import "FLEXKeychain.h"
#import "FLEXKeychainQuery.h"

NSString * const kFLEXKeychainErrorDomain = @"com.flipboard.flex";
NSString * const kFLEXKeychainAccountKey = @"acct";
NSString * const kFLEXKeychainCreatedAtKey = @"cdat";
NSString * const kFLEXKeychainClassKey = @"labl";
NSString * const kFLEXKeychainDescriptionKey = @"desc";
NSString * const kFLEXKeychainGroupKey = @"agrp";
NSString * const kFLEXKeychainLabelKey = @"labl";
NSString * const kFLEXKeychainLastModifiedKey = @"mdat";
NSString * const kFLEXKeychainWhereKey = @"svce";

#if __IPHONE_4_0 && TARGET_OS_IPHONE
static CFTypeRef FLEXKeychainAccessibilityType = NULL;
#endif

@implementation FLEXKeychain

+ (NSString *)passwordForService:(NSString *)serviceName account:(NSString *)account {
    return [self passwordForService:serviceName account:account error:nil];
}

+ (NSString *)passwordForService:(NSString *)serviceName account:(NSString *)account error:(NSError *__autoreleasing *)error {
    FLEXKeychainQuery *query = [FLEXKeychainQuery new];
    query.service = serviceName;
    query.account = account;
    [query fetch:error];
    return query.password;
}

+ (NSData *)passwordDataForService:(NSString *)serviceName account:(NSString *)account {
    return [self passwordDataForService:serviceName account:account error:nil];
}

+ (NSData *)passwordDataForService:(NSString *)serviceName account:(NSString *)account error:(NSError **)error {
    FLEXKeychainQuery *query = [FLEXKeychainQuery new];
    query.service = serviceName;
    query.account = account;
    [query fetch:error];

    return query.passwordData;
}

+ (BOOL)deletePasswordForService:(NSString *)serviceName account:(NSString *)account {
    return [self deletePasswordForService:serviceName account:account error:nil];
}

+ (BOOL)deletePasswordForService:(NSString *)serviceName account:(NSString *)account error:(NSError *__autoreleasing *)error {
    FLEXKeychainQuery *query = [FLEXKeychainQuery new];
    query.service = serviceName;
    query.account = account;
    return [query deleteItem:error];
}

+ (BOOL)setPassword:(NSString *)password forService:(NSString *)serviceName account:(NSString *)account {
    return [self setPassword:password forService:serviceName account:account error:nil];
}

+ (BOOL)setPassword:(NSString *)password forService:(NSString *)serviceName account:(NSString *)account error:(NSError *__autoreleasing *)error {
    FLEXKeychainQuery *query = [FLEXKeychainQuery new];
    query.service = serviceName;
    query.account = account;
    query.password = password;
    return [query save:error];
}

+ (BOOL)setPasswordData:(NSData *)password forService:(NSString *)serviceName account:(NSString *)account {
    return [self setPasswordData:password forService:serviceName account:account error:nil];
}

+ (BOOL)setPasswordData:(NSData *)password forService:(NSString *)serviceName account:(NSString *)account error:(NSError **)error {
    FLEXKeychainQuery *query = [FLEXKeychainQuery new];
    query.service = serviceName;
    query.account = account;
    query.passwordData = password;
    return [query save:error];
}

+ (NSArray *)allAccounts {
    return [self allAccounts:nil] ?: @[];
}

+ (NSArray *)allAccounts:(NSError *__autoreleasing *)error {
    return [self accountsForService:nil error:error];
}

+ (NSArray *)accountsForService:(NSString *)serviceName {
    return [self accountsForService:serviceName error:nil];
}

+ (NSArray *)accountsForService:(NSString *)serviceName error:(NSError *__autoreleasing *)error {
    FLEXKeychainQuery *query = [FLEXKeychainQuery new];
    query.service = serviceName;
    return [query fetchAll:error];
}

#if __IPHONE_4_0 && TARGET_OS_IPHONE
+ (CFTypeRef)accessibilityType {
    return FLEXKeychainAccessibilityType;
}

+ (void)setAccessibilityType:(CFTypeRef)accessibilityType {
    CFRetain(accessibilityType);
    if (FLEXKeychainAccessibilityType) {
        CFRelease(FLEXKeychainAccessibilityType);
    }
    FLEXKeychainAccessibilityType = accessibilityType;
}
#endif

@end
