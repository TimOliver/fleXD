//
//  FLEXSystemLogMessage.m
//  FLEX
//
//  Created by Ryan Olson on 1/25/15.
//  Copyright (c) 2020 FLEX Team. All rights reserved.
//

#import "FLEXSystemLogMessage.h"

@implementation FLEXSystemLogMessage

+ (instancetype)logMessageFromDate:(NSDate *)date text:(NSString *)text {
    return [[self alloc] initWithDate:date sender:nil text:text messageID:0];
}

- (id)initWithDate:(NSDate *)date sender:(NSString *)sender text:(NSString *)text messageID:(long long)identifier {
    self = [super init];
    if (self) {
        _date = date;
        _sender = sender;
        _messageText = text;
        _messageID = identifier;
    }

    return self;
}

- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[self class]]) {
        if (self.messageID) {
            // Only ASL uses messageID, otherwise it is 0
            return self.messageID == [object messageID];
        } else {
            // Test message texts and dates for OS Log
            return [self.messageText isEqual:[object messageText]] &&
                    [self.date isEqualToDate:[object date]];
        }
    }
    
    return NO;
}

- (NSUInteger)hash {
    return (NSUInteger)self.messageID;
}

- (NSString *)description {
    NSString *escaped = [self.messageText stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
    return [NSString stringWithFormat:@"(%@) %@", @(self.messageText.length), escaped];
}

@end
