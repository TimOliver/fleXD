//
//  FLEXMetadataSection.h
//  FLEX
//
//  Created by Tanner Bennett on 9/19/19.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

#import "FLEXTableViewSection.h"
#import "FLEXObjectExplorer.h"

NS_ASSUME_NONNULL_BEGIN

/// The kind of Objective-C runtime metadata displayed by a `FLEXMetadataSection`
typedef NS_ENUM(NSUInteger, FLEXMetadataKind) {
    FLEXMetadataKindProperties = 1,
    FLEXMetadataKindClassProperties,
    FLEXMetadataKindIvars,
    FLEXMetadataKindMethods,
    FLEXMetadataKindClassMethods,
    FLEXMetadataKindClassHierarchy,
    FLEXMetadataKindProtocols,
    FLEXMetadataKindOther,
};

/// A table view section that lists Objective-C runtime metadata for an object or class,
/// such as its properties, instance variables, methods, or protocols.
@interface FLEXMetadataSection : FLEXTableViewSection

+ (instancetype)explorer:(FLEXObjectExplorer *)explorer kind:(FLEXMetadataKind)metadataKind;

/// The type of metadata this section displays.
@property (nonatomic, readonly) FLEXMetadataKind metadataKind;

/// A set of metadata names to exclude from this section.
///
/// Use this to group specific properties or methods into a separate, dedicated section.
/// Setting this property calls `reloadData` on the section.
@property (nonatomic) NSSet<NSString *> *excludedMetadata;

@end

NS_ASSUME_NONNULL_END
