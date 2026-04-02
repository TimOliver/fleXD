//
//  FLEXRuntime+UIKitHelpers.h
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
