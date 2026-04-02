//
//  FLEXMutableListSection.m
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

#import "FLEXMutableListSection.h"
#import "FLEXMacros.h"

@interface FLEXMutableListSection ()
@property (nonatomic, readonly) FLEXMutableListCellForElement configureCell;
@end

@implementation FLEXMutableListSection
@synthesize cellRegistrationMapping = _cellRegistrationMapping;

#pragma mark - Initialization

+ (instancetype)list:(NSArray *)list
   cellConfiguration:(FLEXMutableListCellForElement)cellConfig
       filterMatcher:(BOOL(^)(NSString *, id))filterBlock {
    return [[self alloc] initWithList:list configurationBlock:cellConfig filterMatcher:filterBlock];
}

- (id)initWithList:(NSArray *)list
configurationBlock:(FLEXMutableListCellForElement)cellConfig
     filterMatcher:(BOOL(^)(NSString *, id))filterBlock {
    self = [super init];
    if (self) {
        _configureCell = cellConfig;

        self.list = list.mutableCopy;
        self.customFilter = filterBlock;
        self.hideSectionTitle = YES;
    }

    return self;
}


#pragma mark - Public

- (NSArray *)list {
    return (id)_collection;
}

- (void)setList:(NSMutableArray *)list {
    NSParameterAssert(list);
    _collection = (id)list;

    [self reloadData];
}

- (NSArray *)filteredList {
    return (id)_cachedCollection;
}

- (void)mutate:(void (^)(NSMutableArray *))block {
    block((NSMutableArray *)_collection);
    [self reloadData];
}


#pragma mark - Overrides

- (void)setCustomTitle:(NSString *)customTitle {
    super.customTitle = customTitle;
    self.hideSectionTitle = customTitle == nil;
}

- (BOOL)canSelectRow:(NSInteger)row {
    return self.selectionHandler != nil;
}

- (UIViewController *)viewControllerToPushForRow:(NSInteger)row {
    return nil;
}

- (void (^)(__kindof UIViewController *))didSelectRowAction:(NSInteger)row {
    if (self.selectionHandler) { weakify(self)
        return ^(UIViewController *host) { strongify(self)
            if (self) {
                self.selectionHandler(host, self.filteredList[row]);
            }
        };
    }

    return nil;
}

- (void)configureCell:(__kindof UITableViewCell *)cell forRow:(NSInteger)row {
    self.configureCell(cell, self.filteredList[row], row);
}

- (NSString *)reuseIdentifierForRow:(NSInteger)row {
    if (self.cellRegistrationMapping.count) {
        return self.cellRegistrationMapping.allKeys.firstObject;
    }

    return [super reuseIdentifierForRow:row];
}

- (void)setCellRegistrationMapping:(NSDictionary<NSString *,Class> *)cellRegistrationMapping {
    NSParameterAssert(cellRegistrationMapping.count <= 1);
    _cellRegistrationMapping = cellRegistrationMapping;
}

@end
