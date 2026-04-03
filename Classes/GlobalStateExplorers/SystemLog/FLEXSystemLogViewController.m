//
//  FLEXSystemLogViewController.m
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

#import "FLEXSystemLogViewController.h"
#import "FLEXOSLogController.h"
#import "FLEXSystemLogCell.h"
#import "FLEXMutableListSection.h"
#import "FLEXUtility.h"
#import "FLEXColor.h"
#import "FLEXResources.h"
#import "UIBarButtonItem+FLEX.h"
#import "NSUserDefaults+FLEX.h"

@interface FLEXSystemLogViewController ()

@property (nonatomic, readonly) FLEXMutableListSection<FLEXSystemLogMessage *> *logMessages;
@property (nonatomic, readonly) id<FLEXLogController> logController;

@end

@implementation FLEXSystemLogViewController

#pragma mark - Initialization

- (id)init {
    return [super initWithStyle:UITableViewStylePlain];
}


#pragma mark - Overrides

- (void)viewDidLoad {
    [super viewDidLoad];

    self.showsSearchBar = YES;
    self.pinSearchBar = YES;

    weakify(self)
    id logHandler = ^(NSArray<FLEXSystemLogMessage *> *newMessages) { strongify(self)
        [self handleUpdateWithNewMessages:newMessages];
    };

    _logController = [FLEXOSLogController withUpdateHandler:logHandler];

    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.title = @"Waiting for Logs...";

    // Toolbar buttons //

    UIImage *scrollToTopIcon = [UIImage imageWithCGImage:FLEXResources.scrollToBottomIcon.CGImage
                                                   scale:FLEXResources.scrollToBottomIcon.scale
                                             orientation:UIImageOrientationDown];
    UIBarButtonItem *scrollDown = [UIBarButtonItem
        flex_itemWithImage:scrollToTopIcon
        target:self
        action:@selector(scrollToFirstRow)
    ];
    UIBarButtonItem *settings = [UIBarButtonItem
        flex_itemWithImage:FLEXResources.gearIcon
        target:self
        action:@selector(showLogSettings)
    ];

    [self addToolbarItems:@[scrollDown, settings]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self.logController startMonitoring];
}

- (NSArray<FLEXTableViewSection *> *)makeSections { weakify(self)
    _logMessages = [FLEXMutableListSection list:@[]
        cellConfiguration:^(FLEXSystemLogCell *cell, FLEXSystemLogMessage *message, NSInteger row) {
            strongify(self)

            cell.logMessage = message;
            cell.highlightedText = self.filterText;

            if (row % 2 == 0) {
                cell.backgroundColor = FLEXColor.primaryBackgroundColor;
            } else {
                cell.backgroundColor = FLEXColor.secondaryBackgroundColor;
            }
        } filterMatcher:^BOOL(NSString *filterText, FLEXSystemLogMessage *message) {
            NSString *displayedText = [FLEXSystemLogCell displayedTextForLogMessage:message];
            return [displayedText localizedCaseInsensitiveContainsString:filterText];
        }
    ];

    self.logMessages.cellRegistrationMapping = @{
        kFLEXSystemLogCellIdentifier : [FLEXSystemLogCell class]
    };

    return @[self.logMessages];
}

- (NSArray<FLEXTableViewSection *> *)nonemptySections {
    return @[self.logMessages];
}


#pragma mark - Private

- (void)handleUpdateWithNewMessages:(NSArray<FLEXSystemLogMessage *> *)newMessages {
    self.title = [self.class globalsEntryTitle:FLEXGlobalsRowSystemLog];

    [self.logMessages mutate:^(NSMutableArray *list) {
        NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, newMessages.count)];
        [list insertObjects:newMessages atIndexes:indexes];
    }];

    // Re-filter messages to filter against new messages
    if (self.filterText.length) {
        [self updateSearchResults:self.filterText];
    }

    [self reloadData];
}

- (void)scrollToFirstRow {
    if ([self.tableView numberOfRowsInSection:0] > 0) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                              atScrollPosition:UITableViewScrollPositionTop
                                      animated:YES];
    }
}

- (void)showLogSettings {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    BOOL persistent = defaults.flex_cacheOSLogMessages;

    NSString *persistence = persistent ? @"Disable persistent logging" : @"Enable persistent logging";

    NSString * const title = @"System Log Settings";
    NSString * const body = @"Logs must be collected manually at launch and stored. "
    "You should only enable persistent logging when you need it.";

    FLEXOSLogController *logController = (FLEXOSLogController *)self.logController;

    [FLEXAlert makeAlert:^(FLEXAlert *make) {
        make.title(title).message(body);
        make.button(persistence).handler(^(NSArray<NSString *> *strings) {
            [defaults flex_toggleBoolForKey:kFLEXDefaultsiOSPersistentOSLogKey];
            logController.persistent = !persistent;
            [logController.messages addObjectsFromArray:self.logMessages.list];
        });
        make.button(@"Dismiss").cancelStyle();
    } showFrom:self];
}


#pragma mark - FLEXGlobalsEntry

+ (NSString *)globalsEntryTitle:(FLEXGlobalsRow)row {
    return @"System Log";
}

+ (UIViewController *)globalsEntryViewController:(FLEXGlobalsRow)row {
    return [self new];
}


#pragma mark - Table view data source

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    FLEXSystemLogMessage *logMessage = self.logMessages.filteredList[indexPath.row];
    return [FLEXSystemLogCell preferredHeightForLogMessage:logMessage inWidth:self.tableView.bounds.size.width];
}


#pragma mark - Copy on long press

- (UIContextMenuConfiguration *)tableView:(UITableView *)tableView
contextMenuConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath
                                    point:(CGPoint)point {
    weakify(self)
    return [UIContextMenuConfiguration configurationWithIdentifier:nil previewProvider:nil
        actionProvider:^UIMenu *(NSArray<UIMenuElement *> *suggestedActions) {
            UIAction *copy = [UIAction actionWithTitle:@"Copy"
                                                 image:nil
                                            identifier:@"Copy"
                                               handler:^(UIAction *action) { strongify(self)
                // We usually only want to copy the log message itself, not any metadata associated with it.
                UIPasteboard.generalPasteboard.string = self.logMessages.filteredList[indexPath.row].messageText ?: @"";
            }];
            return [UIMenu menuWithTitle:@"" image:nil identifier:nil options:UIMenuOptionsDisplayInline children:@[copy]];
        }
    ];
}

@end
