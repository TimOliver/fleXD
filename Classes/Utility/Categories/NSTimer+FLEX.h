//
//  NSTimer+FLEX.h
//  FLEX
//
//  Created by Tanner on 3/23/17.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^VoidBlock)(void);

@interface NSTimer (Blocks)

/// Schedules a one-shot timer that fires the given block after the specified delay.
+ (instancetype)flex_fireSecondsFromNow:(NSTimeInterval)delay block:(VoidBlock)block;

@end

NS_ASSUME_NONNULL_END
