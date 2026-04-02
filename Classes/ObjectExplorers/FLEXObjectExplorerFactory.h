//
//  FLEXObjectExplorerFactory.h
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

#import "FLEXGlobalsEntry.h"

#ifndef _FLEXObjectExplorerViewController_h
#import "FLEXObjectExplorerViewController.h"
#else
@class FLEXObjectExplorerViewController;
#endif

NS_ASSUME_NONNULL_BEGIN

/// A factory for creating `FLEXObjectExplorerViewController` instances.
///
/// Custom explorer sections can be registered per class so that FLEX
/// uses the appropriate specialized section when exploring objects of that type.
@interface FLEXObjectExplorerFactory : NSObject <FLEXGlobalsEntry>

/// @return An explorer view controller for the given object or class,
/// or `nil` if the object is `nil` or its type is not explorable.
+ (nullable FLEXObjectExplorerViewController *)explorerViewControllerForObject:(nullable id)object;

/// Registers a custom shortcuts section class to be used when exploring
/// an object of the given class. Subsequent calls for the same class will
/// overwrite any existing registration.
/// @param sectionClass A `FLEXShortcutsSection` subclass. Must respond to `+forObject:`
/// @param objectClass The class whose instances should use `sectionClass`
+ (void)registerExplorerSection:(Class)sectionClass forClass:(Class)objectClass;

@end

NS_ASSUME_NONNULL_END
