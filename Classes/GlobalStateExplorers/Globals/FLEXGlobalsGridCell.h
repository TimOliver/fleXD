//
//  FLEXGlobalsGridCell.h
//
//  Copyright (c) FLEX Team (2020-2026).
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
@class FLEXGlobalsEntry;

NS_ASSUME_NONNULL_BEGIN

extern NSString * const kFLEXGlobalsGridCellIdentifier;

/// A table view cell that displays a row of grid items, each consisting of
/// a colored rounded square icon and a title label below. Used by
/// FLEXGlobalsSection to pack multiple globals entries into a single row.
@interface FLEXGlobalsGridCell : UITableViewCell

/// Extra space added below the stack view. Set to 24pt on the last row of a
/// section to provide visual breathing room before the section footer/next section.
@property (nonatomic) CGFloat bottomPadding;

/// Populate the cell with up to itemsPerRow entries. Entries fewer than
/// itemsPerRow produce empty placeholder slots to maintain uniform widths.
- (void)configureWithEntries:(NSArray<FLEXGlobalsEntry *> *)entries
                 itemsPerRow:(NSInteger)itemsPerRow
               onItemTapped:(void(^)(NSInteger itemIndex))onItemTapped;

@end

NS_ASSUME_NONNULL_END
