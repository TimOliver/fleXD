//
//  FLEXOSLogController.m
//  FLEX
//
//  Created by Tanner on 12/19/18.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

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
