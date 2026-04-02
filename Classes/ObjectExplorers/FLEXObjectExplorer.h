//
//  FLEXObjectExplorer.h
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

#import "FLEXRuntime+UIKitHelpers.h"

NS_ASSUME_NONNULL_BEGIN

/// Carries the current user defaults display settings for an object explorer.
@interface FLEXObjectExplorerDefaults : NSObject

+ (instancetype)canEdit:(BOOL)editable wantsPreviews:(BOOL)showPreviews;

/// `YES` for properties and ivars that support editing, `NO` otherwise.
@property (nonatomic, readonly) BOOL isEditable;
/// `YES` to show live value previews for properties and ivars, `NO` otherwise.
@property (nonatomic, readonly) BOOL wantsDynamicPreviews;

@end


/// Provides the runtime metadata for a given object or class,
/// used to populate the sections of an `FLEXObjectExplorerViewController`
@interface FLEXObjectExplorer : NSObject

+ (instancetype)forObject:(id)objectOrClass;

+ (void)configureDefaultsForItems:(NSArray<id<FLEXObjectExplorerItem>> *)items;

/// The object or class being explored.
@property (nonatomic, readonly) id object;
/// A human-readable description of the object. Subclasses can override for more detail.
@property (nonatomic, readonly) NSString *objectDescription;

/// `YES` if `object` is a class instance, `NO` if it is a class itself.
@property (nonatomic, readonly) BOOL objectIsInstance;

/// The index of the selected class scope within `classHierarchy`
///
/// This determines which set of data is returned by the metadata properties.
/// For example, `properties` returns the properties of the selected class scope,
/// while `allProperties` contains one array per class in the hierarchy.
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
