//
//  FLEXGlobalsSection.m
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

#import "FLEXGlobalsSection.h"
#import "NSArray+FLEX.h"
#import "UIFont+FLEX.h"

@interface FLEXGlobalsSection ()
/// Filtered rows
@property (nonatomic) NSArray<FLEXGlobalsEntry *> *rows;
/// Unfiltered rows
@property (nonatomic) NSArray<FLEXGlobalsEntry *> *allRows;
@end
@implementation FLEXGlobalsSection

#pragma mark - Initialization

+ (instancetype)title:(NSString *)title rows:(NSArray<FLEXGlobalsEntry *> *)rows {
    FLEXGlobalsSection *s = [self new];
    s->_title = title;
    s.allRows = rows;

    return s;
}

- (void)setAllRows:(NSArray<FLEXGlobalsEntry *> *)allRows {
    _allRows = allRows.copy;
    [self reloadData];
}

#pragma mark - Overrides

- (NSInteger)numberOfRows {
    return self.rows.count;
}

- (void)setFilterText:(NSString *)filterText {
    super.filterText = filterText;
    [self reloadData];
}

- (void)reloadData {
    NSString *filterText = self.filterText;

    if (filterText.length) {
        self.rows = [self.allRows flex_filtered:^BOOL(FLEXGlobalsEntry *entry, NSUInteger idx) {
            return [entry.entryNameFuture() localizedCaseInsensitiveContainsString:filterText];
        }];
    } else {
        self.rows = self.allRows;
    }
}

- (BOOL)canSelectRow:(NSInteger)row {
    return YES;
}

- (void (^)(__kindof UIViewController *))didSelectRowAction:(NSInteger)row {
    return (id)self.rows[row].rowAction;
}

- (UIViewController *)viewControllerToPushForRow:(NSInteger)row {
    return self.rows[row].viewControllerFuture ? self.rows[row].viewControllerFuture() : nil;
}

- (void)configureCell:(__kindof UITableViewCell *)cell forRow:(NSInteger)row {
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.textLabel.font = UIFont.flex_defaultTableCellFont;
    cell.textLabel.text = self.rows[row].entryNameFuture();
}

@end


@implementation FLEXGlobalsSection (Subscripting)

- (id)objectAtIndexedSubscript:(NSUInteger)idx {
    return self.rows[idx];
}

@end
