//
//  FLEXTableLeftCell.m
//  FLEX
//
//  Created by Peng Tao on 15/11/24.
//  Copyright © 2015年 f. All rights reserved.
//

#import "FLEXTableLeftCell.h"

static NSString * const kFLEXTableLeftCellIdentifier = @"FLEXTableLeftCell";

@implementation FLEXTableLeftCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        UILabel *textLabel           = [UILabel new];
        textLabel.textAlignment      = NSTextAlignmentCenter;
        textLabel.font               = [UIFont systemFontOfSize:13.0];
        [self.contentView addSubview:textLabel];
        self.titlelabel = textLabel;
    }
    return self;
}

+ (instancetype)cellWithTableView:(UITableView *)tableView {
    [tableView registerClass:[self class] forCellReuseIdentifier:kFLEXTableLeftCellIdentifier];
    return [tableView dequeueReusableCellWithIdentifier:kFLEXTableLeftCellIdentifier];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.titlelabel.frame = self.contentView.frame;
}

@end
