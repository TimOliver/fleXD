//
//  FLEXCollectionContentSection.h
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

#import "FLEXTableViewSection.h"
#import "FLEXObjectInfoSection.h"
@class FLEXCollectionContentSection, FLEXTableViewCell;
@protocol FLEXCollection, FLEXMutableCollection;

NS_ASSUME_NONNULL_BEGIN

/// Any foundation collection implicitly conforms to FLEXCollection.
/// This future should return one. We don't explicitly put FLEXCollection
/// here because making generic collections conform to FLEXCollection breaks
/// compile-time features of generic arrays, such as `someArray[0].property`
typedef id<NSObject, NSFastEnumeration /* FLEXCollection */> _Nonnull (^FLEXCollectionContentFuture)(__kindof FLEXCollectionContentSection *section);

#pragma mark Collection
/// A protocol that enables `FLEXCollectionContentSection` to operate on any arbitrary collection.
/// `NSArray` `NSDictionary` `NSSet` and `NSOrderedSet` all conform to this protocol.
@protocol FLEXCollection <NSObject, NSFastEnumeration>

@property (nonatomic, readonly) NSUInteger count;

- (id)copy;
- (id)mutableCopy;

@optional

/// Unordered, unkeyed collections must implement this
@property (nonatomic, readonly) NSArray *allObjects;
/// Keyed collections must implement this and `objectForKeyedSubscript:`
@property (nonatomic, readonly) NSArray *allKeys;

/// Ordered, indexed collections must implement this.
- (id)objectAtIndexedSubscript:(NSUInteger)idx;
/// Keyed, unordered collections must implement this and `allKeys`
- (id)objectForKeyedSubscript:(id)idx;

@end

@protocol FLEXMutableCollection <FLEXCollection>
- (void)filterUsingPredicate:(NSPredicate *)predicate;
@end


#pragma mark - FLEXCollectionContentSection
/// A custom section for viewing collection elements.
///
/// Tapping on a row pushes an object explorer for that element.
@interface FLEXCollectionContentSection<__covariant ObjectType> : FLEXTableViewSection <FLEXObjectInfoSection> {
    @protected
    /// Unused if initialized with a future
    id<FLEXCollection> _collection;
    /// Unused if initialized with a collection
    FLEXCollectionContentFuture _collectionFuture;
    /// The filtered collection from `_collection` or `_collectionFuture`
    id<FLEXCollection> _cachedCollection;
}

+ (instancetype)forCollection:(id)collection;
/// The future given should be safe to call more than once.
/// The result of calling this future multiple times may yield
/// different results each time if the data is changing by nature.
+ (instancetype)forReusableFuture:(FLEXCollectionContentFuture)collectionFuture;

/// Defaults to `NO`
@property (nonatomic) BOOL hideSectionTitle;
/// Defaults to `nil`
@property (nonatomic, copy) NSString *customTitle;
/// Defaults to `NO`
///
/// Setting this to `NO` will not display the element index for ordered collections.
/// This property only applies to `NSArray` or `NSOrderedSet` and their subclasses.
@property (nonatomic) BOOL hideOrderIndexes;

/// Set this property to provide a custom filter matcher.
///
/// By default, the collection will filter on the title and subtitle of the row.
/// So if you don't ever call `configureCell:` for example, you will need to set
/// this property so that your filter logic will match how you're setting up the cell. 
@property (nonatomic) BOOL (^customFilter)(NSString *filterText, ObjectType element);

/// Get the object in the collection associated with the given row.
/// For dictionaries, this returns the value, not the key.
- (ObjectType)objectForRow:(NSInteger)row;

/// Subclasses may override.
- (UITableViewCellAccessoryType)accessoryTypeForRow:(NSInteger)row;

@end

NS_ASSUME_NONNULL_END
