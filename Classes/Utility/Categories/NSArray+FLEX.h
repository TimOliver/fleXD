//
//  NSArray+FLEX.h
//  FLEX
//
//  Created by Tanner Bennett on 9/25/19.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSArray<T> (Functional)

/// Maps the array to a new array, omitting any elements for which the block returns `nil`
///
/// Unlike a true flatmap, this will not flatten arrays of arrays into a single array.
- (__kindof NSArray *)flex_mapped:(id _Nullable (^)(T obj, NSUInteger idx))mapFunc;

/// Like `flex_mapped:` but expects each block invocation to return an array,
/// and flattens all returned arrays into a single result array.
- (__kindof NSArray *)flex_flatmapped:(NSArray * _Nullable (^)(id obj, NSUInteger idx))block;

/// Returns a new array containing only the elements for which the block returns `YES`
- (instancetype)flex_filtered:(BOOL(^)(T obj, NSUInteger idx))filterFunc;

/// Enumerates the array, invoking the block for each element.
- (void)flex_forEach:(void(^)(T obj, NSUInteger idx))block;

/// Returns a subarray of up to \e maxLength elements from the beginning of the array.
///
/// Unlike `-subarrayWithRange:` this will not throw an exception if \e maxLength
/// exceeds the array's count; it simply returns all available elements.
- (instancetype)flex_subArrayUpto:(NSUInteger)maxLength;

/// Creates an array by mapping integers in [0, \e bound) through the given block.
+ (instancetype)flex_forEachUpTo:(NSUInteger)bound map:(T(^)(NSUInteger i))block;

/// Creates an array by mapping each element of \e collection through the given block,
/// omitting elements for which the block returns `nil`
+ (instancetype)flex_mapped:(id<NSFastEnumeration>)collection
                      block:(id _Nullable (^)(T obj, NSUInteger idx))mapFunc;

/// Returns a copy of the array sorted using the given selector.
- (instancetype)flex_sortedUsingSelector:(SEL)selector;

/// Returns the first element for which the block returns `YES` or `nil` if none.
- (nullable T)flex_firstWhere:(BOOL(^)(T obj))meetingCriteria;

@end


@interface NSMutableArray<T> (Functional)

/// Removes all elements for which the block returns `NO`
- (void)flex_filter:(BOOL(^)(T obj, NSUInteger idx))filterFunc;

@end

NS_ASSUME_NONNULL_END
