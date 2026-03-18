//
//  UITextField+Range.h
//  FLEX
//
//  Created by Tanner on 6/13/17.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UITextField (Range)

/// The currently selected character range of the text field, as an \c NSRange.
@property (nonatomic, readonly) NSRange flex_selectedRange;

@end

NS_ASSUME_NONNULL_END
