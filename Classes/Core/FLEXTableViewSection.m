//
//  FLEXTableViewSection.m
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

#import "FLEXTableViewSection.h"
#import "FLEXTableView.h"
#import "FLEXUtility.h"
#import "UIMenu+FLEX.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincomplete-implementation"

@implementation FLEXTableViewSection

- (NSInteger)numberOfRows {
    return 0;
}

- (void)reloadData { }

- (void)reloadData:(BOOL)updateTable {
    [self reloadData];
    if (updateTable) {
        NSIndexSet *index = [NSIndexSet indexSetWithIndex:_sectionIndex];
        [_tableView reloadSections:index withRowAnimation:UITableViewRowAnimationNone];
    }
}

- (void)setTable:(UITableView *)tableView section:(NSInteger)index {
    _tableView = tableView;
    _sectionIndex = index;
}

- (NSDictionary<NSString *,Class> *)cellRegistrationMapping {
    return nil;
}

- (BOOL)canSelectRow:(NSInteger)row { return NO; }

- (void (^)(__kindof UIViewController *))didSelectRowAction:(NSInteger)row {
    UIViewController *toPush = [self viewControllerToPushForRow:row];
    if (toPush) {
        return ^(UIViewController *host) {
            [host.navigationController pushViewController:toPush animated:YES];
        };
    }

    return nil;
}

- (UIViewController *)viewControllerToPushForRow:(NSInteger)row {
    return nil;
}

- (void (^)(__kindof UIViewController *))didPressInfoButtonAction:(NSInteger)row {
    return nil;
}

- (NSString *)reuseIdentifierForRow:(NSInteger)row {
    return kFLEXDefaultCell;
}

- (NSString *)menuTitleForRow:(NSInteger)row {
    NSString *title = [self titleForRow:row];
    NSString *subtitle = [self menuSubtitleForRow:row];

    if (subtitle.length) {
        return [NSString stringWithFormat:@"%@\n\n%@", title, subtitle];
    }

    return title;
}

- (NSString *)menuSubtitleForRow:(NSInteger)row {
    return @"";
}

- (NSArray<UIMenuElement *> *)menuItemsForRow:(NSInteger)row sender:(UIViewController *)sender {
    NSArray<NSString *> *copyItems = [self copyMenuItemsForRow:row];
    NSAssert(copyItems.count % 2 == 0, @"copyMenuItemsForRow: should return an even list");

    if (copyItems.count) {
        NSInteger numberOfActions = copyItems.count / 2;
        BOOL collapseMenu = numberOfActions > 4;
        UIImage *copyIcon = [UIImage systemImageNamed:@"doc.on.doc"];

        NSMutableArray *actions = [NSMutableArray new];

        for (NSInteger i = 0; i < copyItems.count; i += 2) {
            NSString *key = copyItems[i], *value = copyItems[i+1];
            NSString *title = collapseMenu ? key : [@"Copy " stringByAppendingString:key];

            UIAction *copy = [UIAction
                actionWithTitle:title
                image:copyIcon
                identifier:nil
                handler:^(__kindof UIAction *action) {
                    UIPasteboard.generalPasteboard.string = value;
                }
            ];
            if (!value.length) {
                copy.attributes = UIMenuElementAttributesDisabled;
            }

            [actions addObject:copy];
        }

        UIMenu *copyMenu = [UIMenu
            flex_inlineMenuWithTitle:@"Copy…" 
            image:copyIcon
            children:actions
        ];

        if (collapseMenu) {
            return @[[copyMenu flex_collapsed]];
        } else {
            return @[copyMenu];
        }
    }

    return @[];
}

- (NSArray<NSString *> *)copyMenuItemsForRow:(NSInteger)row {
    return nil;
}

- (NSString *)titleForRow:(NSInteger)row { return nil; }
- (NSString *)subtitleForRow:(NSInteger)row { return nil; }

@end

#pragma clang diagnostic pop
