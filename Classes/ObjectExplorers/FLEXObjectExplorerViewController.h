//
//  FLEXObjectExplorerViewController.h
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

#ifndef _FLEXObjectExplorerViewController_h
#define _FLEXObjectExplorerViewController_h
#endif

#import "FLEXFilteringTableViewController.h"
#import "FLEXObjectExplorer.h"
@class FLEXTableViewSection;

NS_ASSUME_NONNULL_BEGIN

/// A class that displays information about an object or class.
///
/// The explorer view controller uses `FLEXObjectExplorer` to provide a description
/// of the object and list its properties, ivars, methods, and superclasses.
/// Below the description and before properties, some shortcuts will be displayed
/// for certain classes like UIViews. At very bottom, there is an option to view
/// a list of other objects found to be referencing the object being explored.
@interface FLEXObjectExplorerViewController : FLEXFilteringTableViewController

/// Uses the default `FLEXShortcutsSection` for this object as a custom section.
+ (instancetype)exploringObject:(id)objectOrClass;
/// No custom section unless you provide one.
+ (instancetype)exploringObject:(id)objectOrClass customSection:(nullable FLEXTableViewSection *)customSection;
/// No custom sections unless you provide some.
+ (instancetype)exploringObject:(id)objectOrClass
                 customSections:(nullable NSArray<FLEXTableViewSection *> *)customSections;

/// The object being explored, which may be an instance of a class or a class itself.
@property (nonatomic, readonly) id object;

/// This object provides the object's metadata for the explorer view controller.
@property (nonatomic, readonly) FLEXObjectExplorer *explorer;

/// Called once to initialize the list of section objects.
///
/// Subclasses can override this to add, remove, or rearrange sections of the explorer.
- (NSArray<FLEXTableViewSection *> *)makeSections;

/// Whether to allow showing/drilling in to current values for ivars and properties. Default is YES.
@property (nonatomic, readonly) BOOL canHaveInstanceState;

/// Whether to allow drilling in to method calling interfaces for instance methods. Default is YES.
@property (nonatomic, readonly) BOOL canCallInstanceMethods;

/// If the custom section data makes the description redundant, subclasses can choose to hide it. Default is YES.
@property (nonatomic, readonly) BOOL shouldShowDescription;

@end

NS_ASSUME_NONNULL_END
