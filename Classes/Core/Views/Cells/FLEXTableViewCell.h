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
/// Provides \c titleLabel and \c subtitleLabel as non-deprecated replacements
/// for \c UITableViewCell's \c textLabel and \c detailTextLabel.
@interface FLEXTableViewCell : UITableViewCell

/// The primary label of the cell. Use instead of \c textLabel.
@property (nonatomic, readonly) UILabel *titleLabel;
/// The secondary label of the cell. Use instead of \c detailTextLabel.
@property (nonatomic, readonly) UILabel *subtitleLabel;

/// Called after initialization to allow subclasses to perform additional setup
/// without overriding designated initializers. Always call \c super.
- (void)postInit;

@end

NS_ASSUME_NONNULL_END
