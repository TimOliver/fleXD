//
//  FLEXMutableListSection.h
//  FLEX
//
//  Created by Tanner on 3/9/20.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

#import "FLEXCollectionContentSection.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^FLEXMutableListCellForElement)(__kindof UITableViewCell *cell, id element, NSInteger row);

/// A flexible, general-purpose table view section for displaying a list of objects.
///
/// Use this when you need to display a growing or static list of rows within a single
/// section, without the overhead of creating a dedicated section subclass.
///
/// To support editing or inserting rows, implement the appropriate table view delegate
/// methods in your view controller and call \c mutate: or \c setList: before updating
/// the table view.
///
/// By default, no section title is shown. Assign one using the \c customTitle property.
///
/// By default, \c kFLEXDetailCell is used as the reuse identifier. To use multiple reuse
/// identifiers within a single section, dequeue and configure cells yourself in
/// \c -tableView:cellForRowAtIndexPath: and call \c -configureCell:forRow: on this section.
@interface FLEXMutableListSection<__covariant ObjectType> : FLEXCollectionContentSection

/// Creates a section with the given list, cell configuration block, and filter matcher.
+ (instancetype)list:(NSArray<ObjectType> *)list
   cellConfiguration:(FLEXMutableListCellForElement)configurationBlock
       filterMatcher:(BOOL(^)(NSString *filterText, id element))filterBlock;

/// An optional handler invoked when a row is selected. Rows are not selectable by default.
@property (nonatomic, copy) void (^selectionHandler)(__kindof UIViewController *host, ObjectType element);

/// The full, unfiltered list of objects in this section.
@property (nonatomic) NSArray<ObjectType> *list;
/// The subset of \c list that passes the current filter, if any.
@property (nonatomic, readonly) NSArray<ObjectType> *filteredList;

/// The cell registration mapping for this section.
///
/// Expects exactly one entry. Raises an exception if more than one entry is supplied.
/// If your section requires multiple reuse identifiers, consider a custom section subclass.
@property (nonatomic, readwrite) NSDictionary<NSString *, Class> *cellRegistrationMapping;

/// Mutates the full list and updates \c filteredList accordingly.
- (void)mutate:(void(^)(NSMutableArray *list))block;

@end

NS_ASSUME_NONNULL_END
