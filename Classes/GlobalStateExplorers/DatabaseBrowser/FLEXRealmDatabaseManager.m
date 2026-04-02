//
//  FLEXRealmDatabaseManager.m
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

#import "FLEXRealmDatabaseManager.h"
#import "NSArray+FLEX.h"
#import "FLEXSQLResult.h"

#if __has_include(<Realm/Realm.h>)
#import <Realm/Realm.h>
#import <Realm/RLMRealm_Dynamic.h>
#else
#import "FLEXRealmDefines.h"
#endif

@interface FLEXRealmDatabaseManager ()

@property (nonatomic, copy) NSString *path;
@property (nonatomic) RLMRealm *realm;

@end

@implementation FLEXRealmDatabaseManager
static Class RLMRealmClass = nil;

+ (void)load {
    RLMRealmClass = NSClassFromString(@"RLMRealm");
}

+ (instancetype)managerForDatabase:(NSString *)path {
    return [[self alloc] initWithPath:path];
}

- (instancetype)initWithPath:(NSString *)path {
    if (!RLMRealmClass) {
        return nil;
    }

    self = [super init];
    if (self) {
        _path = path;

        if (![self open]) {
            return nil;
        }
    }

    return self;
}

- (BOOL)open {
    Class configurationClass = NSClassFromString(@"RLMRealmConfiguration");
    if (!RLMRealmClass || !configurationClass) {
        return NO;
    }

    NSError *error = nil;
    id configuration = [configurationClass new];
    [(RLMRealmConfiguration *)configuration setFileURL:[NSURL fileURLWithPath:self.path]];
    self.realm = [RLMRealmClass realmWithConfiguration:configuration error:&error];

    return (error == nil);
}

- (NSArray<NSString *> *)queryAllTables {
    // Map each schema to its name
    NSArray<NSString *> *tableNames = [self.realm.schema.objectSchema flex_mapped:^id(RLMObjectSchema *schema, NSUInteger idx) {
        return schema.className ?: nil;
    }];

    return [tableNames sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
}

- (NSArray<NSString *> *)queryAllColumnsOfTable:(NSString *)tableName {
    RLMObjectSchema *objectSchema = [self.realm.schema schemaForClassName:tableName];
    // Map each column to its name
    return [objectSchema.properties flex_mapped:^id(RLMProperty *property, NSUInteger idx) {
        return property.name;
    }];
}

- (NSArray<NSArray *> *)queryAllDataInTable:(NSString *)tableName {
    RLMObjectSchema *objectSchema = [self.realm.schema schemaForClassName:tableName];
    RLMResults *results = [self.realm allObjects:tableName];
    if (results.count == 0 || !objectSchema) {
        return nil;
    }

    // Map results to an array of rows
    return [NSArray flex_mapped:results block:^id(RLMObject *result, NSUInteger idx) {
        // Map each row to an array of the values of its properties 
        return [objectSchema.properties flex_mapped:^id(RLMProperty *property, NSUInteger idx) {
            return [result valueForKey:property.name] ?: NSNull.null;
        }];
    }];
}

@end
