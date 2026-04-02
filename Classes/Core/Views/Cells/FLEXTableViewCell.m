//
//  FLEXTableViewCell.m
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

#import "FLEXTableViewCell.h"
#import "FLEXUtility.h"
#import "FLEXColor.h"
#import "FLEXTableView.h"

@interface UITableView (Internal)
// Exists at least since iOS 5
- (BOOL)_canPerformAction:(SEL)action forCell:(UITableViewCell *)cell sender:(id)sender;
- (void)_performAction:(SEL)action forCell:(UITableViewCell *)cell sender:(id)sender;
@end

@interface UITableViewCell (Internal)
// Exists at least since iOS 5
@property (nonatomic, readonly) FLEXTableView *_tableView;
@end

@implementation FLEXTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self postInit];
    }

    return self;
}

- (void)postInit {
    UIFont *cellFont = UIFont.flex_defaultTableCellFont;
    self.titleLabel.font = cellFont;
    self.subtitleLabel.font = cellFont;
    self.subtitleLabel.textColor = FLEXColor.deemphasizedTextColor;

    self.titleLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    self.subtitleLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;

    self.titleLabel.numberOfLines = 1;
    self.subtitleLabel.numberOfLines = 1;
}

- (UILabel *)titleLabel {
    return self.textLabel;
}

- (UILabel *)subtitleLabel {
    return self.detailTextLabel;
}

@end
