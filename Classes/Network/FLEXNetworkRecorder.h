//
//  FLEXNetworkRecorder.h
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

#import <Foundation/Foundation.h>

// Notifications posted when the record is updated
extern NSString *const kFLEXNetworkRecorderNewTransactionNotification;
extern NSString *const kFLEXNetworkRecorderTransactionUpdatedNotification;
extern NSString *const kFLEXNetworkRecorderUserInfoTransactionKey;
extern NSString *const kFLEXNetworkRecorderTransactionsClearedNotification;

@class FLEXNetworkTransaction, FLEXHTTPTransaction, FLEXWebsocketTransaction, FLEXFirebaseTransaction;
@class FIRQuery, FIRDocumentReference, FIRCollectionReference, FIRDocumentSnapshot, FIRQuerySnapshot;

typedef NS_ENUM(NSUInteger, FLEXNetworkTransactionKind) {
    FLEXNetworkTransactionKindFirebase = 0,
    FLEXNetworkTransactionKindREST,
    FLEXNetworkTransactionKindWebsockets,
};

@interface FLEXNetworkRecorder : NSObject

/// In general, it only makes sense to have one recorder for the entire application.
@property (nonatomic, readonly, class) FLEXNetworkRecorder *defaultRecorder;

/// Defaults to 25 MB if never set. Values set here are persisted across launches of the app.
@property (nonatomic) NSUInteger responseCacheByteLimit;

/// If NO, the recorder not cache will not cache response for content types
/// with an "image", "video", or "audio" prefix.
@property (nonatomic) BOOL shouldCacheMediaResponses;
@property (nonatomic) NSMutableArray<NSString *> *hostDenylist;

/// Call this after adding to or setting the `hostDenylist` to remove excluded transactions
- (void)clearExcludedTransactions;

/// Call this to save the denylist to the disk to be loaded next time
- (void)synchronizeDenylist;


#pragma mark Accessing recorded network activity

/// Array of FLEXHTTPTransaction objects ordered by start time with the newest first.
@property (nonatomic, readonly) NSArray<FLEXHTTPTransaction *> *HTTPTransactions;

/// Array of FLEXWebsocketTransaction objects ordered by start time with the newest first.
@property (nonatomic, readonly) NSArray<FLEXWebsocketTransaction *> *websocketTransactions;

/// Array of FLEXFirebaseTransaction objects ordered by start time with the newest first.
@property (nonatomic, readonly) NSArray<FLEXFirebaseTransaction *> *firebaseTransactions;

/// The full response data IFF it hasn't been purged due to memory pressure.
- (NSData *)cachedResponseBodyForTransaction:(FLEXHTTPTransaction *)transaction;

/// Dumps all network transactions and cached response bodies.
- (void)clearRecordedActivity;

/// Clear only transactions matching the given query.
- (void)clearRecordedActivity:(FLEXNetworkTransactionKind)kind matching:(NSString *)query;


#pragma mark Recording network activity

/// Call when app is about to send HTTP request.
- (void)recordRequestWillBeSentWithRequestID:(NSString *)requestID
                                     request:(NSURLRequest *)request
                            redirectResponse:(NSURLResponse *)redirectResponse;

/// Call when HTTP response is available.
- (void)recordResponseReceivedWithRequestID:(NSString *)requestID response:(NSURLResponse *)response;

/// Call when data chunk is received over the network.
- (void)recordDataReceivedWithRequestID:(NSString *)requestID dataLength:(int64_t)dataLength;

/// Call when HTTP request has finished loading.
- (void)recordLoadingFinishedWithRequestID:(NSString *)requestID responseBody:(NSData *)responseBody;

/// Call when HTTP request has failed to load.
- (void)recordLoadingFailedWithRequestID:(NSString *)requestID error:(NSError *)error;

/// Call to set the request mechanism anytime after recordRequestWillBeSent... has been called.
/// This string can be set to anything useful about the API used to make the request.
- (void)recordMechanism:(NSString *)mechanism forRequestID:(NSString *)requestID;

- (void)recordWebsocketMessageSend:(NSURLSessionWebSocketMessage *)message
                              task:(NSURLSessionWebSocketTask *)task;
- (void)recordWebsocketMessageSendCompletion:(NSURLSessionWebSocketMessage *)message
                                       error:(NSError *)error;

- (void)recordWebsocketMessageReceived:(NSURLSessionWebSocketMessage *)message
                                  task:(NSURLSessionWebSocketTask *)task;

- (void)recordFIRQueryWillFetch:(FIRQuery *)query withTransactionID:(NSString *)transactionID;
- (void)recordFIRDocumentWillFetch:(FIRDocumentReference *)document withTransactionID:(NSString *)transactionID;

- (void)recordFIRQueryDidFetch:(FIRQuerySnapshot *)response error:(NSError *)error
                 transactionID:(NSString *)transactionID;
- (void)recordFIRDocumentDidFetch:(FIRDocumentSnapshot *)response error:(NSError *)error
                    transactionID:(NSString *)transactionID;

- (void)recordFIRWillSetData:(FIRDocumentReference *)doc
                        data:(NSDictionary *)documentData
                       merge:(NSNumber *)yesorno
                 mergeFields:(NSArray *)fields
               transactionID:(NSString *)transactionID;
- (void)recordFIRWillUpdateData:(FIRDocumentReference *)doc fields:(NSDictionary *)fields
                  transactionID:(NSString *)transactionID;
- (void)recordFIRWillDeleteDocument:(FIRDocumentReference *)doc transactionID:(NSString *)transactionID;
- (void)recordFIRWillAddDocument:(FIRCollectionReference *)initiator
                            document:(FIRDocumentReference *)doc
                   transactionID:(NSString *)transactionID;

- (void)recordFIRDidSetData:(NSError *)error transactionID:(NSString *)transactionID;
- (void)recordFIRDidUpdateData:(NSError *)error transactionID:(NSString *)transactionID;
- (void)recordFIRDidDeleteDocument:(NSError *)error transactionID:(NSString *)transactionID;
- (void)recordFIRDidAddDocument:(NSError *)error transactionID:(NSString *)transactionID;

@end
