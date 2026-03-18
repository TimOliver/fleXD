//
//  NSDateFormatter+FLEX.h
//  FLEX
//
//  Created by Tanner Bennett on 7/24/22.
//  Copyright © 2022 FLEX Team. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, FLEXDateFormat) {
    /// Formats the date as "hour:minute AM/PM".
    FLEXDateFormatClock,
    /// Formats the date as "hour:minute:second AM/PM".
    FLEXDateFormatPreciseClock,
    /// Formats the date as "year-month-day hour:minute:second.millisecond".
    FLEXDateFormatVerbose,
};

@interface NSDateFormatter (FLEX)

/// Returns a string representation of the given date using the specified format.
+ (NSString *)flex_stringFrom:(NSDate *)date format:(FLEXDateFormat)format;

@end

NS_ASSUME_NONNULL_END
