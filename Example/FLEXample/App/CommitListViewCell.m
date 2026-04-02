//
//  CommitListViewCell.m
//  FLEXample
//
//  Created by Tim Oliver on 2/4/2026.
//  Copyright © 2026 Flipboard. All rights reserved.
//

#import "CommitListViewCell.h"

static const CGFloat kAvatarSize = 52.0;
static const CGFloat kAvatarGap = 10.0;
static const CGFloat kRowSpacing = 2.0;
static const CGFloat kMessageTopSpacing = 2.0;
static const CGFloat kColumnGap = 4.0;

@implementation CommitListViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _avatarImageView = [UIImageView new];
        _avatarImageView.contentMode = UIViewContentModeScaleAspectFill;
        _avatarImageView.clipsToBounds = YES;
        _avatarImageView.layer.cornerRadius = kAvatarSize / 2.0f;
        [self.contentView addSubview:_avatarImageView];

        _nameLabel = [UILabel new];
        _nameLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];
        _nameLabel.backgroundColor = [UIColor systemBackgroundColor];

        _loginLabel = [UILabel new];
        _loginLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightRegular];
        _loginLabel.textColor = UIColor.secondaryLabelColor;
        _loginLabel.backgroundColor = [UIColor systemBackgroundColor];

        _hashLabel = [UILabel new];
        _hashLabel.font = [UIFont monospacedSystemFontOfSize:15 weight:UIFontWeightRegular];
        _hashLabel.textColor = UIColor.tertiaryLabelColor;
        _hashLabel.textAlignment = NSTextAlignmentRight;
        _hashLabel.backgroundColor = [UIColor systemBackgroundColor];

        _messageLabel = [UILabel new];
        _messageLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightRegular];
        _messageLabel.numberOfLines = 3;
        _messageLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        _messageLabel.backgroundColor = [UIColor systemBackgroundColor];

        for (UILabel *label in @[_nameLabel, _loginLabel, _hashLabel, _messageLabel]) {
            [self.contentView addSubview:label];
        }
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    CGRect readable = self.contentView.readableContentGuide.layoutFrame;
    CGFloat left = CGRectGetMinX(readable);
    CGFloat top = self.contentView.layoutMargins.top;
    CGFloat contentWidth = CGRectGetWidth(readable);

    CGFloat rightInset = CGRectGetWidth(self.bounds) - CGRectGetMaxX(readable);
    self.separatorInset = UIEdgeInsetsMake(0, left + kAvatarSize + kAvatarGap, 0, rightInset);

    // Avatar on the left
    CGFloat textLeft = left + kAvatarSize + kAvatarGap;
    CGFloat textWidth = contentWidth - kAvatarSize - kAvatarGap;

    // Row 1: [name] ... [hash]
    CGSize hashSize = [_hashLabel sizeThatFits:CGSizeMake(textWidth, CGFLOAT_MAX)];
    CGFloat nameWidth = textWidth - hashSize.width - kColumnGap;
    CGSize nameSize = [_nameLabel sizeThatFits:CGSizeMake(nameWidth, CGFLOAT_MAX)];

    _nameLabel.frame = CGRectMake(textLeft, top, nameWidth, nameSize.height);
    CGFloat hashY = top + nameSize.height - hashSize.height;
    _hashLabel.frame = CGRectMake(textLeft + textWidth - hashSize.width, hashY, hashSize.width, hashSize.height);

    // Row 2: [login+date]
    CGFloat row2Top = CGRectGetMaxY(_nameLabel.frame) + kRowSpacing;
    CGSize loginSize = [_loginLabel sizeThatFits:CGSizeMake(textWidth, CGFLOAT_MAX)];
    _loginLabel.frame = CGRectMake(textLeft, row2Top, textWidth, loginSize.height);

    // Row 3: message (full width of text area)
    CGFloat row3Top = CGRectGetMaxY(_loginLabel.frame) + kMessageTopSpacing;
    CGSize messageSize = [_messageLabel sizeThatFits:CGSizeMake(textWidth, CGFLOAT_MAX)];
    _messageLabel.frame = CGRectMake(textLeft, row3Top, textWidth, messageSize.height);

    // Align avatar with top of name label
    _avatarImageView.frame = CGRectMake(left, top, kAvatarSize, kAvatarSize);
}

- (CGSize)systemLayoutSizeFittingSize:(CGSize)targetSize
        withHorizontalFittingPriority:(UILayoutPriority)horizontalFittingPriority
              verticalFittingPriority:(UILayoutPriority)verticalFittingPriority {
    return [self sizeThatFits:targetSize];
}

- (CGSize)sizeThatFits:(CGSize)size {
    UIEdgeInsets margins = self.contentView.layoutMargins;
    CGFloat contentWidth = size.width - margins.left - margins.right;

    CGFloat textWidth = contentWidth - kAvatarSize - kAvatarGap;
    CGSize nameSize = [_nameLabel sizeThatFits:CGSizeMake(textWidth, CGFLOAT_MAX)];
    CGSize loginSize = [_loginLabel sizeThatFits:CGSizeMake(textWidth, CGFLOAT_MAX)];
    CGSize messageSize = [_messageLabel sizeThatFits:CGSizeMake(textWidth, CGFLOAT_MAX)];

    CGFloat textHeight = nameSize.height + kRowSpacing + loginSize.height + kMessageTopSpacing + messageSize.height;
    CGFloat totalHeight = margins.top
        + MAX(textHeight, kAvatarSize)
        + margins.bottom;

    return CGSizeMake(size.width, totalHeight);
}

@end
