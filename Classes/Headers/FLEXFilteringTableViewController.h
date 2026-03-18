//
//  FLEXFilteringTableViewController.h
//  FLEX
//
//  Created by Tanner on 3/9/20.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

#import "FLEXTableViewController.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - FLEXTableViewFiltering
@protocol FLEXTableViewFiltering <FLEXSearchResultsUpdating>

/// An array of visible, "filtered" sections. For example,
/// if you have 3 sections in `allSections` and the user searches
/// for something that matches rows in only one section, then
/// this property would only contain that on matching section.
@property (nonatomic, copy) NSArray<FLEXTableViewSection *> *sections;
/// An array of all possible sections. Empty sections are to be removed
/// and the resulting array stored in the `section` property. Setting
/// this property should immediately set `sections` to `nonemptySections` 
///
/// Do not manually initialize this property, it will be
/// initialized for you using the result of `makeSections`
@property (nonatomic, copy) NSArray<FLEXTableViewSection *> *allSections;

/// This computed property should filter `allSections` for assignment to `sections`
@property (nonatomic, readonly, copy) NSArray<FLEXTableViewSection *> *nonemptySections;

/// This should be able to re-initialize `allSections`
- (NSArray<FLEXTableViewSection *> *)makeSections;

@end


#pragma mark - FLEXFilteringTableViewController
/// A table view which implements `UITableView*` methods using arrays of
/// `FLEXTableViewSection` objects provided by a special delegate.
@interface FLEXFilteringTableViewController : FLEXTableViewController <FLEXTableViewFiltering>

/// Stores the current search query.
@property (nonatomic, copy) NSString *filterText;

/// This property is set to `self` by default.
///
/// This property is used to power almost all of the table view's data source
/// and delegate methods automatically, including row and section filtering
/// when the user searches, 3D Touch context menus, row selection, etc.
///
/// Setting this property will also set `searchDelegate` to that object.
@property (nonatomic, weak) id<FLEXTableViewFiltering> filterDelegate;

/// Defaults to `NO` If enabled, all filtering will be done by calling
/// `onBackgroundQueue:thenOnMainQueue:` with the UI updated on the main queue.
@property (nonatomic) BOOL filterInBackground;

/// Defaults to `NO` If enabled, one • will be supplied as an index title for each section.
@property (nonatomic) BOOL wantsSectionIndexTitles;

/// Recalculates the non-empty sections and reloads the table view.
///
/// Subclasses may override to perform additional reloading logic,
/// such as calling `-reloadSections` if needed. Be sure to call
/// `super` after any logic that would affect the appearance of 
/// the table view, since the table view is reloaded last.
///
/// Called at the end of this class's implementation of `updateSearchResults:`
- (void)reloadData;

/// Invoke this method to call `-reloadData` on each section
/// in `self.filterDelegate.allSections`
- (void)reloadSections;

#pragma mark FLEXTableViewFiltering

@property (nonatomic, copy) NSArray<FLEXTableViewSection *> *sections;
@property (nonatomic, copy) NSArray<FLEXTableViewSection *> *allSections;

/// Subclasses can override to hide specific sections under certain conditions
/// if using `self` as the `filterDelegate` as is the default.
///
/// For example, the object explorer hides the description section when searching.
@property (nonatomic, readonly, copy) NSArray<FLEXTableViewSection *> *nonemptySections;

/// If using `self` as the `filterDelegate` as is the default,
/// subclasses should override to provide the sections for the table view.
- (NSArray<FLEXTableViewSection *> *)makeSections;

@end

NS_ASSUME_NONNULL_END
