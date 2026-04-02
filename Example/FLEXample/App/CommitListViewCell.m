//
//  CommitListViewCell.m
//  FLEXample
//
//  Created by Tim Oliver on 2/4/2026.
//  Copyright © 2026 Flipboard. All rights reserved.
//

#import "CommitListViewCell.h"

static const CGFloat kRowSpacing = 2.0;
static const CGFloat kMessageTopSpacing = 6.0;
static const CGFloat kColumnGap = 8.0;

@implementation CommitListViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _nameLabel = [UILabel new];
        _nameLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];

        _loginLabel = [UILabel new];
        _loginLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
        _loginLabel.textColor = UIColor.secondaryLabelColor;

        _hashLabel = [UILabel new];
        _hashLabel.font = [UIFont monospacedSystemFontOfSize:13 weight:UIFontWeightRegular];
        _hashLabel.textColor = UIColor.tertiaryLabelColor;
        _hashLabel.textAlignment = NSTextAlignmentRight;

        _messageLabel = [UILabel new];
        _messageLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
        _messageLabel.textColor = UIColor.labelColor;
        _messageLabel.numberOfLines = 3;
        _messageLabel.lineBreakMode = NSLineBreakByTruncatingTail;

        for (UILabel *label in @[_nameLabel, _loginLabel, _hashLabel, _messageLabel]) {
            [self.contentView addSubview:label];
        }
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    UIEdgeInsets margins = self.contentView.layoutMargins;
    CGFloat left = margins.left;
    CGFloat top = margins.top;
    CGFloat contentWidth = CGRectGetWidth(self.contentView.bounds) - margins.left - margins.right;

    // Row 1: name (left) | hash (right)
    CGSize hashSize = [_hashLabel sizeThatFits:CGSizeMake(contentWidth, CGFLOAT_MAX)];
    CGFloat nameWidth = contentWidth - hashSize.width - kColumnGap;
    CGSize nameSize = [_nameLabel sizeThatFits:CGSizeMake(nameWidth, CGFLOAT_MAX)];

    _nameLabel.frame = CGRectMake(left, top, nameWidth, nameSize.height);
    CGFloat hashY = top + nameSize.height - hashSize.height;
    _hashLabel.frame = CGRectMake(left + contentWidth - hashSize.width, hashY, hashSize.width, hashSize.height);

    // Row 2: login + date
    CGFloat row2Top = CGRectGetMaxY(_nameLabel.frame) + kRowSpacing;
    CGSize loginSize = [_loginLabel sizeThatFits:CGSizeMake(contentWidth, CGFLOAT_MAX)];
    _loginLabel.frame = CGRectMake(left, row2Top, contentWidth, loginSize.height);

    // Row 3: message (full width)
    CGFloat row3Top = CGRectGetMaxY(_loginLabel.frame) + kMessageTopSpacing;
    CGSize messageSize = [_messageLabel sizeThatFits:CGSizeMake(contentWidth, CGFLOAT_MAX)];
    _messageLabel.frame = CGRectMake(left, row3Top, contentWidth, messageSize.height);
}

- (CGSize)sizeThatFits:(CGSize)size {
    UIEdgeInsets margins = self.contentView.layoutMargins;
    CGFloat contentWidth = size.width - margins.left - margins.right;

    CGSize nameSize = [_nameLabel sizeThatFits:CGSizeMake(contentWidth, CGFLOAT_MAX)];
    CGSize loginSize = [_loginLabel sizeThatFits:CGSizeMake(contentWidth, CGFLOAT_MAX)];
    CGSize messageSize = [_messageLabel sizeThatFits:CGSizeMake(contentWidth, CGFLOAT_MAX)];

    CGFloat totalHeight = margins.top
        + nameSize.height + kRowSpacing
        + loginSize.height + kMessageTopSpacing
        + messageSize.height
        + margins.bottom;

    return CGSizeMake(size.width, totalHeight);
}

@end
