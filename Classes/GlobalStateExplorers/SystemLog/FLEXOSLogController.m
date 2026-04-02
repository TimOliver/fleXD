//
//  FLEXOSLogController.m
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

#import "FLEXOSLogController.h"
#import "NSUserDefaults+FLEX.h"
#import <OSLog/OSLog.h>

#if TARGET_IPHONE_SIMULATOR
    #define updateInterval 5.0
#else
    #define updateInterval 0.5
#endif

@interface FLEXOSLogController ()

+ (FLEXOSLogController *)sharedLogController;

@property (nonatomic) void (^updateHandler)(NSArray<FLEXSystemLogMessage *> *);
@property (nonatomic) NSTimer *logUpdateTimer;
@property (nonatomic) NSDate *lastMessageDate;
@property (nonatomic) OSLogStore *logStore;

@end

@implementation FLEXOSLogController

+ (void)load {
    // Persist logs at launch if the user has background caching enabled
    if (NSUserDefaults.standardUserDefaults.flex_cacheOSLogMessages) {
        [self sharedLogController].persistent = YES;
        [[self sharedLogController] startMonitoring];
    }
}

+ (instancetype)sharedLogController {
    static FLEXOSLogController *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [self new];
    });
    return shared;
}

+ (instancetype)withUpdateHandler:(void(^)(NSArray<FLEXSystemLogMessage *> *newMessages))newMessagesHandler {
    FLEXOSLogController *shared = [self sharedLogController];
    shared.updateHandler = newMessagesHandler;
    return shared;
}

- (id)init {
    self = [super init];
    if (self) {
        NSError *error = nil;
        _logStore = [OSLogStore storeWithScope:OSLogStoreCurrentProcessIdentifier error:&error];
        if (!_logStore) {
            NSLog(@"FLEX: Failed to open OSLogStore: %@", error);
        }
    }
    return self;
}

- (void)dealloc {
    [self.logUpdateTimer invalidate];
}

- (void)setPersistent:(BOOL)persistent {
    if (_persistent == persistent) return;

    _persistent = persistent;
    self.messages = persistent ? [NSMutableArray new] : nil;
}

- (BOOL)startMonitoring {
    if (!self.logStore) return NO;

    // Already monitoring — just replay any accumulated messages to the new handler
    if (self.logUpdateTimer) {
        if (self.updateHandler && self.messages.count) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.updateHandler(self.messages);
            });
        }
        return YES;
    }

    self.logUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:updateInterval
                                                           target:self
                                                         selector:@selector(updateLogMessages)
                                                         userInfo:nil
                                                          repeats:YES];
    [self.logUpdateTimer fire];
    return YES;
}

- (void)updateLogMessages {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray<FLEXSystemLogMessage *> *newMessages = [self newLogMessagesForCurrentProcess];
        if (!newMessages.count) return;

        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.persistent) {
                [self.messages addObjectsFromArray:newMessages];
            }
            if (self.updateHandler) {
                self.updateHandler(newMessages);
            }
        });
    });
}

- (NSArray<FLEXSystemLogMessage *> *)newLogMessagesForCurrentProcess {
    NSError *error = nil;
    NSDate *startDate = self.lastMessageDate ?: [NSDate distantPast];
    OSLogPosition *position = [self.logStore positionWithDate:startDate];

    NSEnumerator<OSLogEntry *> *entries = [self.logStore
        entriesEnumeratorWithOptions:0
        position:position
        predicate:nil
        error:&error
    ];

    if (!entries) return @[];

    NSMutableArray<FLEXSystemLogMessage *> *messages = [NSMutableArray new];
    for (OSLogEntry *entry in entries) {
        if (![entry isKindOfClass:[OSLogEntryLog class]]) continue;
        // positionWithDate: is inclusive, so skip entries already delivered
        if (self.lastMessageDate && [entry.date compare:self.lastMessageDate] != NSOrderedDescending) continue;

        OSLogEntryLog *logEntry = (OSLogEntryLog *)entry;
        [messages addObject:[FLEXSystemLogMessage logMessageFromDate:logEntry.date text:logEntry.composedMessage]];
    }

    if (messages.count) {
        self.lastMessageDate = messages.lastObject.date;
    }

    return messages;
}

@end
