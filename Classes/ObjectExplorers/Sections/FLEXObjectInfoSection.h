//
//  FLEXObjectInfoSection.h
//  FLEX
//
//  Created by Tanner Bennett on 8/28/19.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// A protocol for \c FLEXTableViewSection subclasses that only need the object
/// being explored in order to be initialized.
///
/// Since \c FLEXTableViewSection itself has no knowledge of the object being explored,
/// conforming to this protocol is the preferred way to indicate that a section can be
/// initialized from the object alone, without introducing an abstract class to the hierarchy.
@protocol FLEXObjectInfoSection <NSObject>

+ (instancetype)forObject:(id)object;

@end

NS_ASSUME_NONNULL_END
