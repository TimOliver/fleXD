//
//  FLEXMultilineTableViewCell.h
//  FLEX
//
//  Created by Ryan Olson on 2/13/15.
//  Copyright (c) 2020 FLEX Team. All rights reserved.
//

#import "FLEXTableViewCell.h"

NS_ASSUME_NONNULL_BEGIN

/// A table view cell with both labels configured for multi-line text display.
@interface FLEXMultilineTableViewCell : FLEXTableViewCell

/// Computes the preferred cell height for the given attributed text and layout constraints.
/// @param attributedText The text that the cell's title label will display.
/// @param contentViewWidth The available width of the cell's content view.
/// @param style The style of the enclosing table view, used to account for insets.
/// @param showsAccessory Whether the cell will display an accessory view.
+ (CGFloat)preferredHeightWithAttributedText:(NSAttributedString *)attributedText
                                    maxWidth:(CGFloat)contentViewWidth
                                       style:(UITableViewStyle)style
                              showsAccessory:(BOOL)showsAccessory;

@end

/// A `FLEXMultilineTableViewCell` initialized with `UITableViewCellStyleSubtitle`
@interface FLEXMultilineDetailTableViewCell : FLEXMultilineTableViewCell

@end

NS_ASSUME_NONNULL_END
