//
//  FLEXOSLogController.h
//  FLEX
//
//  Created by Tanner on 12/19/18.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

#import "FLEXLogController.h"

/// The system log controller backed by OSLogStore.
@interface FLEXOSLogController : NSObject <FLEXLogController>

+ (instancetype)withUpdateHandler:(void(^)(NSArray<FLEXSystemLogMessage *> *newMessages))newMessagesHandler;

- (BOOL)startMonitoring;

/// Whether log messages are to be recorded and kept in-memory in the background.
/// You do not need to initialize this value, only change it.
@property (nonatomic) BOOL persistent;
/// Used mostly internally, but also used by the log VC to persist messages
/// that were created prior to enabling persistence.
@property (nonatomic) NSMutableArray<FLEXSystemLogMessage *> *messages;

@end
