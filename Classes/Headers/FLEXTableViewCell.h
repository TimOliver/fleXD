//
//  FLEXTableViewCell.h
//  FLEX
//
//  Created by Tanner on 4/17/19.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// The base table view cell class used throughout FLEX.
///
/// Provides `titleLabel` and `subtitleLabel` as non-deprecated replacements
/// for `UITableViewCell's` `textLabel` and `detailTextLabel`
@interface FLEXTableViewCell : UITableViewCell

/// The primary label of the cell. Use instead of `textLabel`
@property (nonatomic, readonly) UILabel *titleLabel;
/// The secondary label of the cell. Use instead of `detailTextLabel`
@property (nonatomic, readonly) UILabel *subtitleLabel;

/// Called after initialization to allow subclasses to perform additional setup
/// without overriding designated initializers. Always call `super`
- (void)postInit;

@end

NS_ASSUME_NONNULL_END
