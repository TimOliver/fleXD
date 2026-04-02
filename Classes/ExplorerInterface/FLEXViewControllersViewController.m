//
//  FLEXViewControllersViewController.m
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

#import "FLEXViewControllersViewController.h"
#import "FLEXObjectExplorerFactory.h"
#import "FLEXMutableListSection.h"
#import "FLEXUtility.h"

@interface FLEXViewControllersViewController ()
@property (nonatomic, readonly) FLEXMutableListSection *section;
@property (nonatomic, readonly) NSArray<UIViewController *> *controllers;
@end

@implementation FLEXViewControllersViewController
@dynamic sections, allSections;

#pragma mark - Initialization

+ (instancetype)controllersForViews:(NSArray<UIView *> *)views {
    return [[self alloc] initWithViews:views];
}

- (id)initWithViews:(NSArray<UIView *> *)views {
    NSParameterAssert(views.count);

    self = [self initWithStyle:UITableViewStylePlain];
    if (self) {
        _controllers = [views flex_mapped:^id(UIView *view, NSUInteger idx) {
            return [FLEXUtility viewControllerForView:view];
        }];
    }

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"View Controllers at Tap";
    self.showsSearchBar = YES;
    [self disableToolbar];
}

- (NSArray<FLEXTableViewSection *> *)makeSections {
    _section = [FLEXMutableListSection list:self.controllers
        cellConfiguration:^(UITableViewCell *cell, UIViewController *controller, NSInteger row) {
            cell.textLabel.text = [NSString
                stringWithFormat:@"%@ — %p", NSStringFromClass(controller.class), controller
            ];
            cell.detailTextLabel.text = controller.view.description;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.textLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    } filterMatcher:^BOOL(NSString *filterText, UIViewController *controller) {
        return [NSStringFromClass(controller.class) localizedCaseInsensitiveContainsString:filterText];
    }];

    self.section.selectionHandler = ^(UIViewController *host, UIViewController *controller) {
        [host.navigationController pushViewController:
            [FLEXObjectExplorerFactory explorerViewControllerForObject:controller]
        animated:YES];
    };

    self.section.customTitle = @"View Controllers";
    return @[self.section];
}


#pragma mark - Private

- (void)dismissAnimated {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
