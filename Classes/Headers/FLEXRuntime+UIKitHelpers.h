//
//  FLEXRuntime+UIKitHelpers.h
//  FLEX
//
//  Created by Tanner Bennett on 12/16/19.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FLEXProperty.h"
#import "FLEXIvar.h"
#import "FLEXMethod.h"
#import "FLEXProtocol.h"
#import "FLEXTableViewSection.h"

NS_ASSUME_NONNULL_BEGIN

@class FLEXObjectExplorerDefaults;

/// A protocol adopted by model objects in an object explorer screen.
/// Conforming objects can respond to user defaults changes.
@protocol FLEXObjectExplorerItem <NSObject>

/// The current explorer display settings. Updated when settings change.
@property (nonatomic) FLEXObjectExplorerDefaults *defaults;

/// `YES` for properties and ivars that support editing, `NO` for all methods.
@property (nonatomic, readonly) BOOL isEditable;
/// `NO` for ivars, `YES` for supported methods and properties.
@property (nonatomic, readonly) BOOL isCallable;

@end


/// A protocol for Objective-C runtime metadata objects displayed in the object explorer.
@protocol FLEXRuntimeMetadata <FLEXObjectExplorerItem>

/// The primary display string for this metadata row.
- (NSString *)description;
/// The name of this metadata item, used for uniqueness comparisons.
@property (nonatomic, readonly) NSString *name;

/// For internal use.
@property (nonatomic) id tag;

/// Returns the current runtime value of this metadata on the given object, or `nil`
- (nullable id)currentValueWithTarget:(id)object;
/// Returns a short display string for the current value, used as the row subtitle.
- (NSString *)previewWithTarget:(id)object;
/// Returns a viewer for this metadata: a method call screen for methods,
/// or an object explorer for properties and ivars.
- (nullable UIViewController *)viewerWithTarget:(id)object;
/// Returns an editor for this metadata, or `nil` for methods and protocols.
/// The given section is reloaded when the user commits a change.
- (nullable UIViewController *)editorWithTarget:(id)object section:(FLEXTableViewSection *)section;
/// Returns the accessory type that best represents the available interactions for this item.
- (UITableViewCellAccessoryType)suggestedAccessoryTypeWithTarget:(id)object;
/// Returns a custom reuse identifier, or `nil` to use the default.
- (nullable NSString *)reuseIdentifierWithTarget:(id)object;

/// Returns additional actions for the first section of the context menu.
- (NSArray<UIAction *> *)additionalActionsWithTarget:(id)object sender:(UIViewController *)sender;
/// Returns an array of key-value pairs for copy actions.
/// Every two elements form a pair: a description (e.g. "Name") and the string to copy.
- (NSArray<NSString *> *)copiableMetadataWithTarget:(id)object;
/// Returns the memory address of the object held by a property or ivar, if applicable.
- (nullable NSString *)contextualSubtitleWithTarget:(id)object;

@end


// Note: a readonly property may still be editable via a custom setter.
// Checking isEditable will not reflect that unless the property was initialized with a class.
@interface FLEXProperty (UIKitHelpers) <FLEXRuntimeMetadata> @end
@interface FLEXIvar (UIKitHelpers) <FLEXRuntimeMetadata> @end
@interface FLEXMethodBase (UIKitHelpers) <FLEXRuntimeMetadata> @end
@interface FLEXMethod (UIKitHelpers) <FLEXRuntimeMetadata> @end
@interface FLEXProtocol (UIKitHelpers) <FLEXRuntimeMetadata> @end


/// The display style of a `FLEXStaticMetadata` row.
typedef NS_ENUM(NSUInteger, FLEXStaticMetadataRowStyle) {
    FLEXStaticMetadataRowStyleSubtitle,
    FLEXStaticMetadataRowStyleKeyValue,
    FLEXStaticMetadataRowStyleDefault = FLEXStaticMetadataRowStyleSubtitle,
};

/// A read-only metadata row that displays a static key-value pair of information.
@interface FLEXStaticMetadata : NSObject <FLEXRuntimeMetadata>

+ (instancetype)style:(FLEXStaticMetadataRowStyle)style title:(NSString *)title string:(NSString *)string;
+ (instancetype)style:(FLEXStaticMetadataRowStyle)style title:(NSString *)title number:(NSNumber *)number;

+ (NSArray<FLEXStaticMetadata *> *)classHierarchy:(NSArray<Class> *)classes;

@end

NS_ASSUME_NONNULL_END
