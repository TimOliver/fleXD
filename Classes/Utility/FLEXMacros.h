//
//  FLEXMacros.h
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

#ifndef FLEXMacros_h
#define FLEXMacros_h

#ifndef __cplusplus
#ifndef auto
#define auto __auto_type
#endif
#endif

#define flex_keywordify class NSObject;
#define ctor flex_keywordify __attribute__((constructor)) void __flex_ctor_##__LINE__()
#define dtor flex_keywordify __attribute__((destructor)) void __flex_dtor_##__LINE__()

#ifndef strongify

#define weakify(var) __weak __typeof(var) __weak__##var = var;

#define strongify(var) \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Wshadow\"") \
__strong typeof(var) var = __weak__##var; \
_Pragma("clang diagnostic pop")

#endif

// A macro to check if we are running in a test environment
#define FLEX_IS_TESTING() (NSClassFromString(@"XCTest") != nil)

/// Whether we want the majority of constructors to run upon load or not.
extern BOOL FLEXConstructorsShouldRun(void);

/// A macro to return from the current procedure if we don't want to run constructors
#define FLEX_EXIT_IF_NO_CTORS() if (!FLEXConstructorsShouldRun()) return;

/// The display scale of the current trait environment.
NS_INLINE CGFloat FLEXScreenScale(void) {
    return UITraitCollection.currentTraitCollection.displayScale;
}

/// Rounds down to the nearest "point" coordinate
NS_INLINE CGFloat FLEXFloor(CGFloat x) {
    CGFloat scale = FLEXScreenScale();
    return floor(scale * x) / scale;
}

/// Returns the given number of points in pixels
NS_INLINE CGFloat FLEXPointsToPixels(CGFloat points) {
    return points / FLEXScreenScale();
}

/// Creates a CGRect with all members rounded down to the nearest "point" coordinate
NS_INLINE CGRect FLEXRectMake(CGFloat x, CGFloat y, CGFloat width, CGFloat height) {
    return CGRectMake(FLEXFloor(x), FLEXFloor(y), FLEXFloor(width), FLEXFloor(height));
}

/// Adjusts the origin of an existing rect
NS_INLINE CGRect FLEXRectSetOrigin(CGRect r, CGPoint origin) {
    r.origin = origin; return r;
}

/// Adjusts the size of an existing rect
NS_INLINE CGRect FLEXRectSetSize(CGRect r, CGSize size) {
    r.size = size; return r;
}

/// Adjusts the origin.x of an existing rect
NS_INLINE CGRect FLEXRectSetX(CGRect r, CGFloat x) {
    r.origin.x = x; return r;
}

/// Adjusts the origin.y of an existing rect
NS_INLINE CGRect FLEXRectSetY(CGRect r, CGFloat y) {
    r.origin.y = y; return r;
}

/// Adjusts the size.width of an existing rect
NS_INLINE CGRect FLEXRectSetWidth(CGRect r, CGFloat width) {
    r.size.width = width; return r;
}

/// Adjusts the size.height of an existing rect
NS_INLINE CGRect FLEXRectSetHeight(CGRect r, CGFloat height) {
    r.size.height = height; return r;
}

#define FLEXPluralString(count, plural, singular) [NSString \
    stringWithFormat:@"%@ %@", @(count), (count == 1 ? singular : plural) \
]

#define FLEXPluralFormatString(count, pluralFormat, singularFormat) [NSString \
    stringWithFormat:(count == 1 ? singularFormat : pluralFormat), @(count)  \
]

#define flex_dispatch_after(nSeconds, onQueue, block) \
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, \
    (int64_t)(nSeconds * NSEC_PER_SEC)), onQueue, block)

#endif /* FLEXMacros_h */
