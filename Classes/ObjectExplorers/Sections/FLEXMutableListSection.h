//
//  FLEXMutableListSection.h
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

#import "FLEXCollectionContentSection.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^FLEXMutableListCellForElement)(__kindof UITableViewCell *cell, id element, NSInteger row);

/// A flexible, general-purpose table view section for displaying a list of objects.
///
/// Use this when you need to display a growing or static list of rows within a single
/// section, without the overhead of creating a dedicated section subclass.
///
/// To support editing or inserting rows, implement the appropriate table view delegate
/// methods in your view controller and call `mutate:` or `setList:` before updating
/// the table view.
///
/// By default, no section title is shown. Assign one using the `customTitle` property.
///
/// By default, `kFLEXDetailCell` is used as the reuse identifier. To use multiple reuse
/// identifiers within a single section, dequeue and configure cells yourself in
/// `-tableView:cellForRowAtIndexPath:` and call `-configureCell:forRow:` on this section.
@interface FLEXMutableListSection<__covariant ObjectType> : FLEXCollectionContentSection

/// Creates a section with the given list, cell configuration block, and filter matcher.
+ (instancetype)list:(NSArray<ObjectType> *)list
   cellConfiguration:(FLEXMutableListCellForElement)configurationBlock
       filterMatcher:(BOOL(^)(NSString *filterText, id element))filterBlock;

/// An optional handler invoked when a row is selected. Rows are not selectable by default.
@property (nonatomic, copy) void (^selectionHandler)(__kindof UIViewController *host, ObjectType element);

/// The full, unfiltered list of objects in this section.
@property (nonatomic) NSArray<ObjectType> *list;

/// The subset of `list` that passes the current filter, if any.
@property (nonatomic, readonly) NSArray<ObjectType> *filteredList;

/// The cell registration mapping for this section.
///
/// Expects exactly one entry. Raises an exception if more than one entry is supplied.
/// If your section requires multiple reuse identifiers, consider a custom section subclass.
@property (nonatomic, readwrite) NSDictionary<NSString *, Class> *cellRegistrationMapping;

/// Mutates the full list and updates `filteredList` accordingly.
- (void)mutate:(void(^)(NSMutableArray *list))block;

@end

NS_ASSUME_NONNULL_END
