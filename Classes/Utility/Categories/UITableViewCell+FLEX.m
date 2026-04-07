//
//  UITableViewCell+FLEX.m
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

#import "UITableViewCell+FLEX.h"

@implementation UITableViewCell (FLEX)

- (void)flex_replaceDetailAccessoryWithSFSymbol {
    UITableViewCellAccessoryType type = self.accessoryType;
    BOOL isDetailDisclosure = type == UITableViewCellAccessoryDetailDisclosureButton;
    BOOL isDetail = type == UITableViewCellAccessoryDetailButton;

    // Clear any stale custom accessory view left over from a previous cell reuse
    self.accessoryView = nil;

    if (!isDetailDisclosure && !isDetail) return;

    // Build the pencil-in-circle edit button
    UIImageSymbolConfiguration *pencilConfig = [UIImageSymbolConfiguration
        configurationWithPointSize:11 weight:UIImageSymbolWeightMedium];
    UIImage *pencilImage = [UIImage systemImageNamed:@"pencil" withConfiguration:pencilConfig];

    UIButtonConfiguration *btnConfig = [UIButtonConfiguration plainButtonConfiguration];
    btnConfig.image = pencilImage;
    btnConfig.baseForegroundColor = UIColor.secondaryLabelColor;
    btnConfig.background.backgroundColor = UIColor.secondarySystemFillColor;
    btnConfig.background.cornerRadius = 13;

    UIButton *infoButton = [UIButton buttonWithConfiguration:btnConfig primaryAction:nil];
    infoButton.frame = CGRectMake(0, 0, 26, 26);

    // At tap time, walk the superview chain to find the table view and dispatch
    // through its delegate — no need to capture either at configuration time.
    __weak typeof(self) weakSelf = self;
    [infoButton addAction:[UIAction actionWithHandler:^(__kindof UIAction *action) {
        UIView *view = weakSelf.superview;
        while (view && ![view isKindOfClass:UITableView.class]) {
            view = view.superview;
        }
        UITableView *tableView = (UITableView *)view;
        NSIndexPath *ip = [tableView indexPathForCell:weakSelf];
        if (tableView && ip) {
            [tableView.delegate tableView:tableView accessoryButtonTappedForRowWithIndexPath:ip];
        }
    }] forControlEvents:UIControlEventTouchUpInside];

    // DetailDisclosure: edit button + disclosure chevron
    UIImageSymbolConfiguration *chevronConfig = [UIImageSymbolConfiguration
        configurationWithPointSize:12 weight:UIImageSymbolWeightSemibold];
    UIImage *chevronImage = [UIImage systemImageNamed:@"chevron.right" withConfiguration:chevronConfig];
    UIImageView *chevron = [[UIImageView alloc] initWithImage:chevronImage];
    chevron.tintColor = UIColor.tertiaryLabelColor;
    [chevron sizeToFit];

    CGFloat spacing = 6;
    CGFloat chevronW = isDetailDisclosure ? chevron.frame.size.width : 10;
    CGFloat chevronH = chevron.frame.size.height;
    CGFloat totalW = 26 + spacing + chevronW;
    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, totalW, 26)];
    infoButton.frame = CGRectMake(0, 0, 26, 26);
    [container addSubview:infoButton];

    if (isDetailDisclosure) {
        chevron.frame = CGRectMake(26 + spacing, (26 - chevronH) / 2.0, chevronW, chevronH);
        [container addSubview:chevron];
    }

    self.accessoryView = container;
}

@end
