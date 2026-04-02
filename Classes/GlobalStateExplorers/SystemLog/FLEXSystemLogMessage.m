//
//  FLEXSystemLogMessage.m
//
//  Copyright (c) Flipboard (2014-2016); FLEX Team (2020-2026).
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without modification,
//  are permitted provided that the following conditions are met:
//
//  * Redistributions of source code must retain the above copyright notice, this
//    list of conditions and the following disclaimer.
//
//  * Redistributions in binary form must reproduce the above copyright notice, this
//    list of conditions and the following disclaimer in the documentation and/or
//    other materials provided with the distribution.
//
//  * Neither the name of Flipboard nor the names of its
//    contributors may be used to endorse or promote products derived from
//    this software without specific prior written permission.
//
//  * You must NOT include this project in an application to be submitted
//    to the App Store™, as this project uses too many private APIs.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
//  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
//  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
//  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
//  ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

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
