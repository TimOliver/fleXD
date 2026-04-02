//
//  CommitListViewCell.h
//  FLEXample
//
//  Created by Tim Oliver on 2/4/2026.
//  Copyright © 2026 Flipboard. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CommitListViewCell : UITableViewCell

@property (nonatomic, readonly) UIImageView *avatarImageView;
@property (nonatomic, readonly) UILabel *nameLabel;
@property (nonatomic, readonly) UILabel *loginLabel;
@property (nonatomic, readonly) UILabel *hashLabel;
@property (nonatomic, readonly) UILabel *messageLabel;

@end

NS_ASSUME_NONNULL_END
