//
//  PTTableListViewController.m
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

#import "FLEXTableListViewController.h"
#import "FLEXDatabaseManager.h"
#import "FLEXSQLiteDatabaseManager.h"
#import "FLEXRealmDatabaseManager.h"
#import "FLEXTableContentViewController.h"
#import "FLEXMutableListSection.h"
#import "NSArray+FLEX.h"
#import "FLEXAlert.h"
#import "FLEXMacros.h"

@interface FLEXTableListViewController ()
@property (nonatomic, readonly) id<FLEXDatabaseManager> dbm;
@property (nonatomic, readonly) NSString *path;

@property (nonatomic, readonly) FLEXMutableListSection<NSString *> *tables;

+ (NSArray<NSString *> *)supportedSQLiteExtensions;
+ (NSArray<NSString *> *)supportedRealmExtensions;

@end

@implementation FLEXTableListViewController

- (instancetype)initWithPath:(NSString *)path {
    self = [super initWithStyle:UITableViewStyleInsetGrouped];
    if (self) {
        _path = path.copy;
        _dbm = [self databaseManagerForFileAtPath:path];
    }

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.showsSearchBar = YES;

    // Compose query button //

    UIBarButtonItem *composeQuery = [[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemCompose
        target:self
        action:@selector(queryButtonPressed)
    ];
    // Cannot run custom queries on realm databases
    composeQuery.enabled = [self.dbm
        respondsToSelector:@selector(executeStatement:)
    ];

    [self addToolbarItems:@[composeQuery]];
}

- (NSArray<FLEXTableViewSection *> *)makeSections {
    _tables = [FLEXMutableListSection list:[self.dbm queryAllTables]
        cellConfiguration:^(__kindof UITableViewCell *cell, NSString *tableName, NSInteger row) {
            cell.textLabel.text = tableName;
        } filterMatcher:^BOOL(NSString *filterText, NSString *tableName) {
            return [tableName localizedCaseInsensitiveContainsString:filterText];
        }
    ];

    self.tables.selectionHandler = ^(FLEXTableListViewController *host, NSString *tableName) {
        NSArray *rows = [host.dbm queryAllDataInTable:tableName];
        NSArray *columns = [host.dbm queryAllColumnsOfTable:tableName];
        NSArray *rowIDs = nil;
        if ([host.dbm respondsToSelector:@selector(queryRowIDsInTable:)]) {        
            rowIDs = [host.dbm queryRowIDsInTable:tableName];
        }
        UIViewController *resultsScreen = [FLEXTableContentViewController
            columns:columns rows:rows rowIDs:rowIDs tableName:tableName database:host.dbm
        ];
        [host.navigationController pushViewController:resultsScreen animated:YES];
    };

    return @[self.tables];
}

- (void)reloadData {
    self.tables.customTitle = [NSString
        stringWithFormat:@"Tables (%@)", @(self.tables.filteredList.count)
    ];

    [super reloadData];
}

- (void)queryButtonPressed {
    [self showQueryInput:nil];
}

- (void)showQueryInput:(NSString *)prefillQuery {
    FLEXSQLiteDatabaseManager *database = self.dbm;

    [FLEXAlert makeAlert:^(FLEXAlert *make) {
        make.title(@"Execute an SQL query");
        make.configuredTextField(^(UITextField *textField) {
            textField.text = prefillQuery;
        });

        make.button(@"Run").handler(^(NSArray<NSString *> *strings) {
            NSString *query = strings[0];
            FLEXSQLResult *result = [database executeStatement:query];

            if (result.message) {
                // Allow users to edit their last query if it had an error
                if ([result.message containsString:@"error"]) {
                    [FLEXAlert makeAlert:^(FLEXAlert *make) {
                        make.title(@"Error").message(result.message);
                        make.button(@"Edit Query").preferred().handler(^(NSArray<NSString *> *_) {
                            // Show query editor again with our last input
                            [self showQueryInput:query];
                        });

                        make.button(@"Cancel").cancelStyle();
                    } showFrom:self];
                } else {
                    [FLEXAlert showAlert:@"Message" message:result.message from:self];
                }
            } else {
                UIViewController *resultsScreen = [FLEXTableContentViewController
                    columns:result.columns rows:result.rows
                ];

                [self.navigationController pushViewController:resultsScreen animated:YES];
            }
        });
        make.button(@"Cancel").cancelStyle();
    } showFrom:self];
}

- (id<FLEXDatabaseManager>)databaseManagerForFileAtPath:(NSString *)path {
    NSString *pathExtension = path.pathExtension.lowercaseString;

    NSArray<NSString *> *sqliteExtensions = FLEXTableListViewController.supportedSQLiteExtensions;
    if ([sqliteExtensions indexOfObject:pathExtension] != NSNotFound) {
        return [FLEXSQLiteDatabaseManager managerForDatabase:path];
    }

    NSArray<NSString *> *realmExtensions = FLEXTableListViewController.supportedRealmExtensions;
    if (realmExtensions != nil && [realmExtensions indexOfObject:pathExtension] != NSNotFound) {
        return [FLEXRealmDatabaseManager managerForDatabase:path];
    }

    return nil;
}


#pragma mark - FLEXTableListViewController

+ (BOOL)supportsExtension:(NSString *)extension {
    extension = extension.lowercaseString;

    NSArray<NSString *> *sqliteExtensions = FLEXTableListViewController.supportedSQLiteExtensions;
    if (sqliteExtensions.count > 0 && [sqliteExtensions indexOfObject:extension] != NSNotFound) {
        return YES;
    }

    NSArray<NSString *> *realmExtensions = FLEXTableListViewController.supportedRealmExtensions;
    if (realmExtensions.count > 0 && [realmExtensions indexOfObject:extension] != NSNotFound) {
        return YES;
    }

    return NO;
}

+ (NSArray<NSString *> *)supportedSQLiteExtensions {
    return @[@"db", @"sqlite", @"sqlite3"];
}

+ (NSArray<NSString *> *)supportedRealmExtensions {
    if (NSClassFromString(@"RLMRealm") == nil) {
        return nil;
    }

    return @[@"realm"];
}

@end
