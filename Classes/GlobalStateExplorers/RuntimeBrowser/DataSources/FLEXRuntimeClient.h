//
//  FLEXRuntimeClient.h
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

#import "FLEXSearchToken.h"
@class FLEXMethod;

/// Accepts runtime queries given a token.
@interface FLEXRuntimeClient : NSObject

@property (nonatomic, readonly, class) FLEXRuntimeClient *runtime;

/// Called automatically when `FLEXRuntime` is first used.
/// You may call it again when you think a library has
/// been loaded since this method was first called.
- (void)reloadLibrariesList;

/// You must call this method on the main thread
/// before you attempt to call `copySafeClassList`
+ (void)initializeWebKitLegacy;

/// Do not call unless you absolutely need all classes. This will cause
/// every class in the runtime to initialize itself, which is not common.
/// Before you call this method, call `initializeWebKitLegacy` on the main thread.
- (NSArray<Class> *)copySafeClassList;

- (NSArray<Protocol *> *)copyProtocolList;

/// An array of strings representing the currently loaded libraries.
@property (nonatomic, readonly) NSArray<NSString *> *imageDisplayNames;

/// "Image name" is the path of the bundle
- (NSString *)shortNameForImageName:(NSString *)imageName;
/// "Image name" is the path of the bundle
- (NSString *)imageNameForShortName:(NSString *)imageName;

/// @return Bundle names for the UI
- (NSMutableArray<NSString *> *)bundleNamesForToken:(FLEXSearchToken *)token;
/// @return Bundle paths for more queries
- (NSMutableArray<NSString *> *)bundlePathsForToken:(FLEXSearchToken *)token;
/// @return Class names
- (NSMutableArray<NSString *> *)classesForToken:(FLEXSearchToken *)token
                                      inBundles:(NSMutableArray<NSString *> *)bundlePaths;
/// @return A list of lists of `FLEXMethods` where
/// each list corresponds to one of the given classes
- (NSArray<NSMutableArray<FLEXMethod *> *> *)methodsForToken:(FLEXSearchToken *)token
                                                    instance:(NSNumber *)onlyInstanceMethods
                                                   inClasses:(NSArray<NSString *> *)classes;

@end
