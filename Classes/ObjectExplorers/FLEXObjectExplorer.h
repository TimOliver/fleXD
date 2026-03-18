//
//  FLEXObjectExplorer.h
//  FLEX
//
//  Created by Tanner Bennett on 8/28/19.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

#import "FLEXRuntime+UIKitHelpers.h"

NS_ASSUME_NONNULL_BEGIN

/// Carries the current user defaults display settings for an object explorer.
@interface FLEXObjectExplorerDefaults : NSObject

+ (instancetype)canEdit:(BOOL)editable wantsPreviews:(BOOL)showPreviews;

/// \c YES for properties and ivars that support editing, \c NO otherwise.
@property (nonatomic, readonly) BOOL isEditable;
/// \c YES to show live value previews for properties and ivars, \c NO otherwise.
@property (nonatomic, readonly) BOOL wantsDynamicPreviews;

@end


/// Provides the runtime metadata for a given object or class,
/// used to populate the sections of an \c FLEXObjectExplorerViewController.
@interface FLEXObjectExplorer : NSObject

+ (instancetype)forObject:(id)objectOrClass;

+ (void)configureDefaultsForItems:(NSArray<id<FLEXObjectExplorerItem>> *)items;

/// The object or class being explored.
@property (nonatomic, readonly) id object;
/// A human-readable description of the object. Subclasses can override for more detail.
@property (nonatomic, readonly) NSString *objectDescription;

/// \c YES if \c object is a class instance, \c NO if it is a class itself.
@property (nonatomic, readonly) BOOL objectIsInstance;

/// The index of the selected class scope within \c classHierarchy.
///
/// This determines which set of data is returned by the metadata properties.
/// For example, \c properties returns the properties of the selected class scope,
/// while \c allProperties contains one array per class in the hierarchy.
@property (nonatomic) NSInteger classScope;

@property (nonatomic, readonly) NSArray<NSArray<FLEXProperty *> *> *allProperties;
@property (nonatomic, readonly) NSArray<FLEXProperty *> *properties;

@property (nonatomic, readonly) NSArray<NSArray<FLEXProperty *> *> *allClassProperties;
@property (nonatomic, readonly) NSArray<FLEXProperty *> *classProperties;

@property (nonatomic, readonly) NSArray<NSArray<FLEXIvar *> *> *allIvars;
@property (nonatomic, readonly) NSArray<FLEXIvar *> *ivars;

@property (nonatomic, readonly) NSArray<NSArray<FLEXMethod *> *> *allMethods;
@property (nonatomic, readonly) NSArray<FLEXMethod *> *methods;

@property (nonatomic, readonly) NSArray<NSArray<FLEXMethod *> *> *allClassMethods;
@property (nonatomic, readonly) NSArray<FLEXMethod *> *classMethods;

@property (nonatomic, readonly) NSArray<Class> *classHierarchyClasses;
@property (nonatomic, readonly) NSArray<FLEXStaticMetadata *> *classHierarchy;

@property (nonatomic, readonly) NSArray<NSArray<FLEXProtocol *> *> *allConformedProtocols;
@property (nonatomic, readonly) NSArray<FLEXProtocol *> *conformedProtocols;

@property (nonatomic, readonly) NSArray<FLEXStaticMetadata *> *allInstanceSizes;
@property (nonatomic, readonly) FLEXStaticMetadata *instanceSize;

@property (nonatomic, readonly) NSArray<FLEXStaticMetadata *> *allImageNames;
@property (nonatomic, readonly) FLEXStaticMetadata *imageName;

- (void)reloadMetadata;
- (void)reloadClassHierarchy;

@end


@interface FLEXObjectExplorer (Reflex)

/// Do not enable this property manually; Reflex will set it when it is loaded.
/// You may disable it manually if needed.
@property (nonatomic, class) BOOL reflexAvailable;

@end

NS_ASSUME_NONNULL_END
