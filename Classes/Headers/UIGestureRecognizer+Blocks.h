//
//  UIGestureRecognizer+Blocks.h
//  FLEX
//
//  Created by Tanner Bennett on 12/20/19.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^GestureBlock)(UIGestureRecognizer *gesture);

@interface UIGestureRecognizer (Blocks)

/// Creates a new gesture recognizer with the given action block.
+ (instancetype)flex_action:(GestureBlock)action;

/// The block invoked when the gesture recognizer fires.
@property (nonatomic, setter=flex_setAction:) GestureBlock flex_action;

@end

NS_ASSUME_NONNULL_END
