//
//  FLEXRuntimeKeyPath.h
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

NS_ASSUME_NONNULL_BEGIN

/// A key path represents a query into a set of bundles or classes
/// for a set of one or more methods. It is composed of three tokens:
/// bundle, class, and method. A key path may be incomplete if it
/// is missing any of the tokens. A key path is considered "absolute"
/// if all tokens have no options and if methodKey.string begins
/// with a + or a -.
///
/// The @code TBKeyPathTokenizer @endcode class is used to create
/// a key path from a string.
@interface FLEXRuntimeKeyPath : NSObject

+ (instancetype)empty;

/// @param method must start with either a wildcard or a + or -.
+ (instancetype)bundle:(FLEXSearchToken *)bundle
                 class:(FLEXSearchToken *)cls
                method:(FLEXSearchToken *)method
            isInstance:(NSNumber *)instance
                string:(NSString *)keyPathString;

@property (nonatomic, nullable, readonly) FLEXSearchToken *bundleKey;
@property (nonatomic, nullable, readonly) FLEXSearchToken *classKey;
@property (nonatomic, nullable, readonly) FLEXSearchToken *methodKey;

/// Indicates whether the method token specifies instance methods.
/// Nil if not specified.
@property (nonatomic, nullable, readonly) NSNumber *instanceMethods;

@end
NS_ASSUME_NONNULL_END
