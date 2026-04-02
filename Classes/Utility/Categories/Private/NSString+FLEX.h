//
//  NSString+FLEX.h
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

#import "FLEXRuntimeConstants.h"

@interface NSString (FLEXTypeEncoding)

///@return whether this type starts with the const specifier
@property (nonatomic, readonly) BOOL flex_typeIsConst;

/// @return the first char in the type encoding that is not the const specifier
@property (nonatomic, readonly) FLEXTypeEncoding flex_firstNonConstType;

/// @return the first char in the type encoding after the pointer specifier, if it is a pointer
@property (nonatomic, readonly) FLEXTypeEncoding flex_pointeeType;

/// @return whether this type is an objc object of any kind, even if it's const
@property (nonatomic, readonly) BOOL flex_typeIsObjectOrClass;

/// @return the class named in this type encoding if it is of the form `@"MYClass"`
@property (nonatomic, readonly) Class flex_typeClass;

/// Includes C strings and selectors as well as regular pointers
@property (nonatomic, readonly) BOOL flex_typeIsNonObjcPointer;

@end

@interface NSString (KeyPaths)

- (NSString *)flex_stringByRemovingLastKeyPathComponent;
- (NSString *)flex_stringByReplacingLastKeyPathComponent:(NSString *)replacement;

@end
