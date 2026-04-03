//
//  FLEXCookiesViewController.m
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

#import "FLEXCookiesViewController.h"
#import "FLEXObjectExplorerFactory.h"
#import "FLEXMutableListSection.h"
#import "FLEXUtility.h"

@interface FLEXCookiesViewController ()
@property (nonatomic, readonly) FLEXMutableListSection<NSHTTPCookie *> *cookies;
@property (nonatomic) NSString *headerTitle;
@end

@implementation FLEXCookiesViewController

#pragma mark - Overrides

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"Cookies";
}

- (NSString *)headerTitle {
    return self.cookies.title;
}

- (void)setHeaderTitle:(NSString *)headerTitle {
    self.cookies.customTitle = headerTitle;
}

- (NSArray<FLEXTableViewSection *> *)makeSections {
    NSSortDescriptor *nameSortDescriptor = [[NSSortDescriptor alloc]
        initWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)
    ];
    NSArray *cookies = [NSHTTPCookieStorage.sharedHTTPCookieStorage.cookies
       sortedArrayUsingDescriptors:@[nameSortDescriptor]
    ];

    _cookies = [FLEXMutableListSection list:cookies
        cellConfiguration:^(UITableViewCell *cell, NSHTTPCookie *cookie, NSInteger row) {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.textLabel.text = [cookie.name stringByAppendingFormat:@" (%@)", cookie.value];
            cell.detailTextLabel.text = [cookie.domain stringByAppendingFormat:@" — %@", cookie.path];
        } filterMatcher:^BOOL(NSString *filterText, NSHTTPCookie *cookie) {
            return [cookie.name localizedCaseInsensitiveContainsString:filterText] ||
                [cookie.value localizedCaseInsensitiveContainsString:filterText] ||
                [cookie.domain localizedCaseInsensitiveContainsString:filterText] ||
                [cookie.path localizedCaseInsensitiveContainsString:filterText];
        }
    ];

    self.cookies.selectionHandler = ^(UIViewController *host, NSHTTPCookie *cookie) {
        [host.navigationController pushViewController:[
            FLEXObjectExplorerFactory explorerViewControllerForObject:cookie
        ] animated:YES];
    };

    return @[self.cookies];
}

- (void)reloadData {
    self.headerTitle = [NSString stringWithFormat:
        @"%@ cookies", @(self.cookies.filteredList.count)
    ];
    [super reloadData];
}

#pragma mark - FLEXGlobalsEntry

+ (NSString *)globalsEntryTitle:(FLEXGlobalsRow)row {
    return @"Cookies";
}

+ (UIViewController *)globalsEntryViewController:(FLEXGlobalsRow)row {
    return [self new];
}

@end
