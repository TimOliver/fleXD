//
//  FLEXKeyPathSearchController.h
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

#import <UIKit/UIKit.h>
#import "FLEXRuntimeBrowserToolbar.h"
#import "FLEXMethod.h"

@protocol FLEXKeyPathSearchControllerDelegate <UITableViewDataSource>

@property (nonatomic, readonly) UITableView *tableView;
@property (nonatomic, readonly) UISearchController *searchController;

/// For loaded images which don't have an NSBundle
- (void)didSelectImagePath:(NSString *)message shortName:(NSString *)shortName;
- (void)didSelectBundle:(NSBundle *)bundle;
- (void)didSelectClass:(Class)cls;

@end


@interface FLEXKeyPathSearchController : NSObject <UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate>

+ (instancetype)delegate:(id<FLEXKeyPathSearchControllerDelegate>)delegate;

@property (nonatomic) FLEXRuntimeBrowserToolbar *toolbar;

/// Suggestions for the toolbar
@property (nonatomic, readonly) NSArray<NSString *> *suggestions;

- (void)didSelectKeyPathOption:(NSString *)text;
- (void)didPressButton:(NSString *)text insertInto:(UISearchBar *)searchBar;

@end
