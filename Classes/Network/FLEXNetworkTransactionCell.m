//
//  FLEXNetworkTransactionCell.m
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

#import "FLEXColor.h"
#import "FLEXNetworkTransactionCell.h"
#import "FLEXNetworkTransaction.h"
#import "FLEXUtility.h"
#import "FLEXResources.h"

NSString * const kFLEXNetworkTransactionCellIdentifier = @"kFLEXNetworkTransactionCellIdentifier";

@interface FLEXNetworkTransactionCell ()

@property (nonatomic) UIImageView *thumbnailImageView;
@property (nonatomic) UILabel *nameLabel;
@property (nonatomic) UILabel *pathLabel;
@property (nonatomic) UILabel *transactionDetailsLabel;

@end

@implementation FLEXNetworkTransactionCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

        self.nameLabel = [UILabel new];
        self.nameLabel.font = UIFont.flex_defaultTableCellFont;
        [self.contentView addSubview:self.nameLabel];

        self.pathLabel = [UILabel new];
        self.pathLabel.font = UIFont.flex_defaultTableCellFont;
        self.pathLabel.textColor = [UIColor colorWithWhite:0.4 alpha:1.0];
        self.pathLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
        [self.contentView addSubview:self.pathLabel];

        self.thumbnailImageView = [UIImageView new];
        self.thumbnailImageView.layer.borderColor = UIColor.blackColor.CGColor;
        self.thumbnailImageView.layer.borderWidth = 1.0;
        self.thumbnailImageView.contentMode = UIViewContentModeScaleAspectFit;
        [self.contentView addSubview:self.thumbnailImageView];

        self.transactionDetailsLabel = [UILabel new];
        self.transactionDetailsLabel.font = [UIFont systemFontOfSize:10.0];
        self.transactionDetailsLabel.textColor = [UIColor colorWithWhite:0.65 alpha:1.0];
        [self.contentView addSubview:self.transactionDetailsLabel];
    }
    return self;
}

- (void)setTransaction:(FLEXNetworkTransaction *)transaction {
    if (_transaction != transaction) {
        _transaction = transaction;
        [self setNeedsLayout];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];

    const CGFloat kVerticalPadding = 8.0;
    const CGFloat kLeftPadding = 10.0;
    const CGFloat kImageDimension = 32.0;

    CGFloat thumbnailOriginY = round((self.contentView.bounds.size.height - kImageDimension) / 2.0);
    self.thumbnailImageView.frame = CGRectMake(kLeftPadding, thumbnailOriginY, kImageDimension, kImageDimension);
    self.thumbnailImageView.image = self.transaction.thumbnail;

    CGFloat textOriginX = CGRectGetMaxX(self.thumbnailImageView.frame) + kLeftPadding;
    CGFloat availableTextWidth = self.contentView.bounds.size.width - textOriginX;

    self.nameLabel.text = [self nameLabelText];
    CGSize nameLabelPreferredSize = [self.nameLabel sizeThatFits:CGSizeMake(availableTextWidth, CGFLOAT_MAX)];
    self.nameLabel.frame = CGRectMake(textOriginX, kVerticalPadding, availableTextWidth, nameLabelPreferredSize.height);
    self.nameLabel.textColor = self.transaction.displayAsError ? UIColor.redColor : FLEXColor.primaryTextColor;

    self.pathLabel.text = [self pathLabelText];
    CGSize pathLabelPreferredSize = [self.pathLabel sizeThatFits:CGSizeMake(availableTextWidth, CGFLOAT_MAX)];
    CGFloat pathLabelOriginY = ceil((self.contentView.bounds.size.height - pathLabelPreferredSize.height) / 2.0);
    self.pathLabel.frame = CGRectMake(textOriginX, pathLabelOriginY, availableTextWidth, pathLabelPreferredSize.height);

    self.transactionDetailsLabel.text = [self transactionDetailsLabelText];
    CGSize transactionLabelPreferredSize = [self.transactionDetailsLabel sizeThatFits:CGSizeMake(availableTextWidth, CGFLOAT_MAX)];
    CGFloat transactionDetailsOriginX = textOriginX;
    CGFloat transactionDetailsLabelOriginY = CGRectGetMaxY(self.contentView.bounds) - kVerticalPadding - transactionLabelPreferredSize.height;
    CGFloat transactionDetailsLabelWidth = self.contentView.bounds.size.width - transactionDetailsOriginX;
    self.transactionDetailsLabel.frame = CGRectMake(transactionDetailsOriginX, transactionDetailsLabelOriginY, transactionDetailsLabelWidth, transactionLabelPreferredSize.height);
}

- (NSString *)nameLabelText {
    return self.transaction.primaryDescription;
}

- (NSString *)pathLabelText {
    return self.transaction.secondaryDescription;
}

- (NSString *)transactionDetailsLabelText {
    return self.transaction.tertiaryDescription;
}

+ (CGFloat)preferredCellHeight {
    return 65.0;
}

+ (NSString *)reuseID {
    return kFLEXNetworkTransactionCellIdentifier;
}

@end
