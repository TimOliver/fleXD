//
//  FLEXTableView.m
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

#import "FLEXTableView.h"
#import "FLEXUtility.h"
#import "FLEXSubtitleTableViewCell.h"
#import "FLEXMultilineTableViewCell.h"
#import "FLEXKeyValueTableViewCell.h"
#import "FLEXCodeFontCell.h"

FLEXTableViewCellReuseIdentifier const kFLEXDefaultCell = @"kFLEXDefaultCell";
FLEXTableViewCellReuseIdentifier const kFLEXDetailCell = @"kFLEXDetailCell";
FLEXTableViewCellReuseIdentifier const kFLEXMultilineCell = @"kFLEXMultilineCell";
FLEXTableViewCellReuseIdentifier const kFLEXMultilineDetailCell = @"kFLEXMultilineDetailCell";
FLEXTableViewCellReuseIdentifier const kFLEXKeyValueCell = @"kFLEXKeyValueCell";
FLEXTableViewCellReuseIdentifier const kFLEXCodeFontCell = @"kFLEXCodeFontCell";

#pragma mark Private

@interface UITableView (Private)
- (CGFloat)_heightForHeaderInSection:(NSInteger)section;
- (NSString *)_titleForHeaderInSection:(NSInteger)section;
@end

@implementation FLEXTableView

+ (instancetype)flexDefaultTableView {
    return [[self alloc] initWithFrame:CGRectZero style:UITableViewStyleInsetGrouped];
}

#pragma mark - Initialization

+ (id)groupedTableView {
    return [[self alloc] initWithFrame:CGRectZero style:UITableViewStyleInsetGrouped];
}

+ (id)plainTableView {
    return [[self alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
}

+ (id)style:(UITableViewStyle)style {
    return [[self alloc] initWithFrame:CGRectZero style:style];
}

- (id)initWithFrame:(CGRect)frame style:(UITableViewStyle)style {
    self = [super initWithFrame:frame style:style];
    if (self) {
        [self registerCells:@{
            kFLEXDefaultCell : [FLEXTableViewCell class],
            kFLEXDetailCell : [FLEXSubtitleTableViewCell class],
            kFLEXMultilineCell : [FLEXMultilineTableViewCell class],
            kFLEXMultilineDetailCell : [FLEXMultilineDetailTableViewCell class],
            kFLEXKeyValueCell : [FLEXKeyValueTableViewCell class],
            kFLEXCodeFontCell : [FLEXCodeFontCell class],
        }];
    }

    return self;
}


#pragma mark - Public

- (void)registerCells:(NSDictionary<NSString*, Class> *)registrationMapping {
    [registrationMapping enumerateKeysAndObjectsUsingBlock:^(NSString *identifier, Class cellClass, BOOL *stop) {
        [self registerClass:cellClass forCellReuseIdentifier:identifier];
    }];
}

@end
