//
//  UIPasteboard+FLEX.h
//  FLEX
//
//  Created by Tanner Bennett on 12/9/19.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIPasteboard (FLEX)

/// Copies the given object to the pasteboard.
/// Handles \c NSString, \c NSData, and \c NSNumber values appropriately.
- (void)flex_copy:(id)unknownType;

@end

NS_ASSUME_NONNULL_END
