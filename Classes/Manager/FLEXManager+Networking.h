//
//  FLEXManager+Networking.h
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

#import "FLEXManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface FLEXManager (Networking)

/// If this property is set to YES, FLEX will swizzle NSURLSession*Delegate methods
/// on classes that conform to the protocol. This allows you to view network activity history from the main FLEX menu.
/// Full responses are kept temporarily in a size-limited cache and may be pruned under memory pressure.
@property (nonatomic, getter=isNetworkDebuggingEnabled) BOOL networkDebuggingEnabled;

/// Defaults to 25 MB if never set. Values set here are persisted across launches of the app.
/// The response cache uses an NSCache, so it may purge prior to hitting the limit when the app is under memory pressure.
@property (nonatomic) NSUInteger networkResponseCacheByteLimit;

/// Requests whose host ends with one of the excluded entries in this array will be not be recorded (eg. google.com).
/// Wildcard or subdomain entries are not required (eg. google.com will match any subdomain under google.com).
/// Useful to remove requests that are typically noisy, such as analytics requests that you aren't interested in tracking.
@property (nonatomic) NSMutableArray<NSString *> *networkRequestHostDenylist;

/// Sets custom viewer for specific content type.
/// @param contentType Mime type like application/json
/// @param viewControllerFutureBlock Viewer (view controller) creation block
/// @note This method must be called from the main thread.
/// The viewControllerFutureBlock will be invoked from the main thread and may not return nil.
/// @note The passed block will be copied and retained for the duration of the application.
/// You may want to use __weak references.
- (void)setCustomViewerForContentType:(NSString *)contentType
            viewControllerFutureBlock:(FLEXCustomContentViewerFuture)viewControllerFutureBlock;

@end

NS_ASSUME_NONNULL_END
