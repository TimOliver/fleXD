//
//  FLEXSingleRowSection.m
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

#import "FLEXSingleRowSection.h"
#import "FLEXTableView.h"

@interface FLEXSingleRowSection ()
@property (nonatomic, readonly) NSString *reuseIdentifier;
@property (nonatomic, readonly) void (^cellConfiguration)(__kindof UITableViewCell *cell);

@property (nonatomic) NSString *lastTitle;
@property (nonatomic) NSString *lastSubitle;
@end

@implementation FLEXSingleRowSection

#pragma mark - Public

+ (instancetype)title:(NSString *)title
                reuse:(NSString *)reuse
                 cell:(void (^)(__kindof UITableViewCell *))config {
    return [[self alloc] initWithTitle:title reuse:reuse cell:config];
}

- (id)initWithTitle:(NSString *)sectionTitle
              reuse:(NSString *)reuseIdentifier
               cell:(void (^)(__kindof UITableViewCell *))cellConfiguration {
    NSParameterAssert(cellConfiguration);

    self = [super init];
    if (self) {
        _title = sectionTitle;
        _reuseIdentifier = reuseIdentifier ?: kFLEXDefaultCell;
        _cellConfiguration = cellConfiguration;
    }

    return self;
}

#pragma mark - Overrides

- (NSInteger)numberOfRows {
    if (self.filterMatcher && self.filterText.length) {
        return self.filterMatcher(self.filterText) ? 1 : 0;
    }

    return 1;
}

- (BOOL)canSelectRow:(NSInteger)row {
    return self.pushOnSelection || self.selectionAction;
}

- (void (^)(__kindof UIViewController *))didSelectRowAction:(NSInteger)row {
    return self.selectionAction;
}

- (UIViewController *)viewControllerToPushForRow:(NSInteger)row {
    return self.pushOnSelection;
}

- (NSString *)reuseIdentifierForRow:(NSInteger)row {
    return self.reuseIdentifier;
}

- (void)configureCell:(__kindof UITableViewCell *)cell forRow:(NSInteger)row {
    cell.textLabel.text = nil;
    cell.detailTextLabel.text = nil;
    cell.accessoryType = UITableViewCellAccessoryNone;

    self.cellConfiguration(cell);
    self.lastTitle = cell.textLabel.text;
    self.lastSubitle = cell.detailTextLabel.text;
}

- (NSString *)titleForRow:(NSInteger)row {
    return self.lastTitle;
}

- (NSString *)subtitleForRow:(NSInteger)row {
    return self.lastSubitle;
}

- (NSArray<NSString *> *)copyMenuItemsForRow:(NSInteger)row {
    NSString *const text = [self titleForRow:row];
    if (text.length) {
        return @[@"Text", text];
    }
    return nil;
}

@end
