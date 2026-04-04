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
        _avatarImageView.layer.borderWidth = 1.0f;
        _avatarImageView.layer.borderColor = [UIColor separatorColor].CGColor;

        _nameLabel = [UILabel new];
        _nameLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];

        _loginLabel = [UILabel new];
        _loginLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightRegular];
        _loginLabel.textColor = UIColor.secondaryLabelColor;

        _hashLabel = [UILabel new];
        _hashLabel.font = [UIFont monospacedSystemFontOfSize:15 weight:UIFontWeightRegular];
        _hashLabel.textColor = UIColor.tertiaryLabelColor;
        _hashLabel.textAlignment = NSTextAlignmentRight;

        _messageLabel = [UILabel new];
        _messageLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightRegular];
        _messageLabel.numberOfLines = 3;
        _messageLabel.lineBreakMode = NSLineBreakByTruncatingTail;

        NSArray *const views = @[_avatarImageView, _nameLabel, _loginLabel, _hashLabel, _messageLabel];
        for (UIView *view in views) { [self.contentView addSubview:view]; }
    }
    return self;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    if ([previousTraitCollection hasDifferentColorAppearanceComparedToTraitCollection:self.traitCollection]) {
        _avatarImageView.layer.borderColor = [UIColor separatorColor].CGColor;
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];

    // We'll add readable insetting on large screens, like iPad.
    CGRect readable = self.contentView.readableContentGuide.layoutFrame;
    CGFloat left = CGRectGetMinX(readable);
    CGFloat top = self.contentView.layoutMargins.top;
    CGFloat contentWidth = CGRectGetWidth(readable);

    // Ensure the separator is edge to edge on iPhone, but clipped to the text margin on iPad.
    BOOL isCompact = self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact;
    CGFloat rightInset = isCompact ? 0 : CGRectGetWidth(self.bounds) - CGRectGetMaxX(readable);
    self.separatorInset = UIEdgeInsetsMake(0, left + kAvatarSize + kAvatarGap, 0, rightInset);

    // Avatar aligned to the top left hand corner of the cell
    CGFloat textLeft = left + kAvatarSize + kAvatarGap;
    CGFloat textWidth = contentWidth - kAvatarSize - kAvatarGap;

    // Top Row: Author name in the top left, commit hash value in top right
    CGSize hashSize = [_hashLabel sizeThatFits:CGSizeMake(textWidth, CGFLOAT_MAX)];
    CGFloat nameWidth = textWidth - hashSize.width - kColumnGap;
    CGSize nameSize = [_nameLabel sizeThatFits:CGSizeMake(nameWidth, CGFLOAT_MAX)];

    _nameLabel.frame = CGRectMake(textLeft, top, nameWidth, nameSize.height);
    CGFloat hashY = top + nameSize.height - hashSize.height;
    _hashLabel.frame = CGRectMake(textLeft + textWidth - hashSize.width, hashY, hashSize.width, hashSize.height);

    // Row 2: The user's account name with the commit date appended
    CGFloat row2Top = CGRectGetMaxY(_nameLabel.frame) + kRowSpacing;
    CGSize loginSize = [_loginLabel sizeThatFits:CGSizeMake(textWidth, CGFLOAT_MAX)];
    _loginLabel.frame = CGRectMake(textLeft, row2Top, textWidth, loginSize.height);

    // Row 3: The commit message, truncated to only 2 or 3 lines.
    CGFloat row3Top = CGRectGetMaxY(_loginLabel.frame) + kMessageTopSpacing;
    CGSize messageSize = [_messageLabel sizeThatFits:CGSizeMake(textWidth, CGFLOAT_MAX)];
    _messageLabel.frame = CGRectMake(textLeft, row3Top, textWidth, messageSize.height);

    // Align avatar with top of name label
    _avatarImageView.frame = CGRectMake(left, top, kAvatarSize, kAvatarSize);
}

- (CGSize)systemLayoutSizeFittingSize:(CGSize)targetSize
        withHorizontalFittingPriority:(UILayoutPriority)horizontalFittingPriority
              verticalFittingPriority:(UILayoutPriority)verticalFittingPriority {
    // `sizeThatFits` potentially doesn't get called on its own when there aren't any
    // active Auto Layout constraints. Call this method and pass it along to capture all sizing calls.
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
