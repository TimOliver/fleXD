//
//  FLEXRuntimeController.h
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

#import "FLEXRuntimeKeyPath.h"

/// Wraps FLEXRuntimeClient and provides extra caching mechanisms
@interface FLEXRuntimeController : NSObject

/// @return An array of strings if the key path only evaluates
///         to a class or bundle; otherwise, a list of lists of FLEXMethods.
+ (NSArray *)dataForKeyPath:(FLEXRuntimeKeyPath *)keyPath;

/// Useful when you need to specify which classes to search in.
/// `dataForKeyPath:` will only search classes matching the class key.
/// We use this elsewhere when we need to search a class hierarchy.
+ (NSArray<NSArray<FLEXMethod *> *> *)methodsForToken:(FLEXSearchToken *)token
                                             instance:(NSNumber *)onlyInstanceMethods
                                            inClasses:(NSArray<NSString*> *)classes;

/// Useful when you need the classes that are associated with the
/// double list of methods returned from `dataForKeyPath`
+ (NSMutableArray<NSString *> *)classesForKeyPath:(FLEXRuntimeKeyPath *)keyPath;

+ (NSString *)shortBundleNameForClass:(NSString *)name;

+ (NSString *)imagePathWithShortName:(NSString *)suffix;

/// Gives back short names. For example, "Foundation.framework"
+ (NSArray<NSString*> *)allBundleNames;

@end
