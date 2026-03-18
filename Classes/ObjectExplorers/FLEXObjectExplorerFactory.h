//
//  FLEXObjectExplorerFactory.h
//  Flipboard
//
//  Created by Ryan Olson on 5/15/14.
//  Copyright (c) 2020 FLEX Team. All rights reserved.
//

#import "FLEXGlobalsEntry.h"

#ifndef _FLEXObjectExplorerViewController_h
#import "FLEXObjectExplorerViewController.h"
#else
@class FLEXObjectExplorerViewController;
#endif

NS_ASSUME_NONNULL_BEGIN

/// A factory for creating \c FLEXObjectExplorerViewController instances.
///
/// Custom explorer sections can be registered per class so that FLEX
/// uses the appropriate specialized section when exploring objects of that type.
@interface FLEXObjectExplorerFactory : NSObject <FLEXGlobalsEntry>

/// @return An explorer view controller for the given object or class,
/// or \c nil if the object is \c nil or its type is not explorable.
+ (nullable FLEXObjectExplorerViewController *)explorerViewControllerForObject:(nullable id)object;

/// Registers a custom shortcuts section class to be used when exploring
/// an object of the given class. Subsequent calls for the same class will
/// overwrite any existing registration.
/// @param sectionClass A \c FLEXShortcutsSection subclass. Must respond to \c +forObject:
/// @param objectClass The class whose instances should use \c sectionClass.
+ (void)registerExplorerSection:(Class)sectionClass forClass:(Class)objectClass;

@end

NS_ASSUME_NONNULL_END
