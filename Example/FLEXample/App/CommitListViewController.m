//
//  CommitListViewController.m
//  FLEXample
//
//  Created by Tanner on 3/11/20.
//  Copyright © 2020 Flipboard. All rights reserved.
//

#import "CommitListViewController.h"
#import "FLEXample-Swift.h"
#import "Person.h"
#import "CommitListViewCell.h"
#import <FLEX.h>

@interface CommitListViewController ()
@property (nonatomic) FLEXMutableListSection<Commit *> *commits;
@property (nonatomic, readonly) NSMutableDictionary<NSString *, UIImage *> *avatars;
@property (nonatomic) UIView *headerSeparator;
@end

@interface UIAlertController (Private)
@property (nonatomic) UIViewController *contentViewController;
@end

@interface ContentViewController : UIViewController
+ (instancetype)customView:(UIView *)view;
@end

@implementation ContentViewController

+ (instancetype)customView:(UIView *)view {
    ContentViewController *vc = [self new];
    vc.view = view;
    return vc;
}

@end

@implementation CommitListViewController

- (id)init {
    // Default style is grouped
    return [self initWithStyle:UITableViewStylePlain];
}

- (void)showCustomView {
    UIAlertController *alert = [FLEXAlert makeAlert:^(FLEXAlert *make) {
        make.title(@"Custom View").button(@"Dismiss").cancelStyle();
    }];
    
    // I like to use this to easily display and interact with custom views I'm working on
    alert.contentViewController = [ContentViewController customView:[UIView new]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationController.navigationBar.prefersLargeTitles = YES;
    
    _avatars = [NSMutableDictionary new];
    
    self.title = @"Commit History";
    self.showsSearchBar = YES;

    CGFloat hairline = 1.0 / UIScreen.mainScreen.scale;
    UIView *headerContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, hairline)];
    _headerSeparator = [[UIView alloc] initWithFrame:CGRectZero];
    _headerSeparator.backgroundColor = self.tableView.separatorColor;
    [headerContainer addSubview:_headerSeparator];
    self.tableView.tableHeaderView = headerContainer;
    self.navigationItem.rightBarButtonItem = [UIBarButtonItem
        flex_itemWithTitle:@"FLEX" target:FLEXManager.sharedManager action:@selector(toggleExplorer)
    ];
    self.navigationItem.rightBarButtonItem.accessibilityIdentifier = @"toggle-explorer";
    
    self.navigationItem.leftBarButtonItem = [UIBarButtonItem
        flex_itemWithTitle:@"Test" target:self action:@selector(showCustomView)
    ];
    
    // Load and process commits
    NSString *commitsURL = @"https://api.github.com/repos/apple/swift/commits";
    [self startDataTask:commitsURL completion:^(NSData *data, NSInteger statusCode, NSError *error) {
        if (statusCode == 200) {
            self.commits.list = [Commit commitsFrom:data];
            [self fadeInNewRows];
        } else {
            [FLEXAlert showAlert:@"Error"
                message:error.localizedDescription ?: @(statusCode).stringValue
                from:self
            ];
        }
    }];
    
    FLEXManager *flex = FLEXManager.sharedManager;
    
    // Register 't' for testing: quickly present an object explorer for debugging
    [flex registerSimulatorShortcutWithKey:@"t" modifiers:0 action:^{
        [flex showExplorer];
        [flex presentTool:^UINavigationController *{
            return [FLEXNavigationController withRootViewController:[FLEXObjectExplorerFactory
                explorerViewControllerForObject:Person.bob
            ]];
        } completion:nil];
    } description:@"Present an object explorer for debugging"];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self disableToolbar];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    CGRect readable = self.view.readableContentGuide.layoutFrame;
    UINavigationBar *bar = self.navigationController.navigationBar;
    NSDirectionalEdgeInsets barMargins = bar.directionalLayoutMargins;
    barMargins.leading = CGRectGetMinX(readable);
    barMargins.trailing = CGRectGetWidth(self.view.bounds) - CGRectGetMaxX(readable);
    bar.directionalLayoutMargins = barMargins;

    // Position the header separator based on size class
    UIView *header = self.tableView.tableHeaderView;
    BOOL isCompact = self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact;
    if (isCompact) {
        UIEdgeInsets margins = self.tableView.layoutMargins;
        CGFloat textLeft = margins.left + 52.0 + 10.0; // avatar size + gap
        _headerSeparator.frame = CGRectMake(textLeft, 0, header.bounds.size.width - textLeft, header.bounds.size.height);
    } else {
        _headerSeparator.frame = CGRectMake(CGRectGetMinX(readable), 0, CGRectGetWidth(readable), header.bounds.size.height);
    }
}

- (NSArray<FLEXTableViewSection *> *)makeSections {
    _commits = [FLEXMutableListSection list:@[]
        cellConfiguration:^(__kindof CommitListViewCell *cell, Commit *commit, NSInteger row) {
            cell.nameLabel.text = commit.committerName;
            NSString *login = commit.committer.login ? [@"@" stringByAppendingString:commit.committer.login] : nil;
            NSString *date = commit.relativeDate;
            if (login) {
                cell.loginLabel.text = [NSString stringWithFormat:@"%@ \u00B7 %@", login, date];
            } else {
                cell.loginLabel.text = date;
            }
            cell.hashLabel.text = commit.shortHash;
            cell.messageLabel.text = commit.commitMessage;

            NSString *avatarLogin = commit.committer.login;
            UIImage *avi = avatarLogin ? self.avatars[avatarLogin] : nil;
            if (avi) {
                cell.avatarImageView.image = avi;
            } else {
                cell.avatarImageView.image = nil;
                cell.tag = commit.identifier;
                [self loadImage:commit.committer.avatarUrl completion:^(UIImage *image) {
                    if (avatarLogin) {
                        self.avatars[avatarLogin] = image;
                    }
                    if (cell.tag == commit.identifier) {
                        cell.avatarImageView.image = image;
                    }
                }];
            }
        } filterMatcher:^BOOL(NSString *filterText, Commit *commit) {
            return [commit matchesWithQuery:filterText];
        }
    ];
    
    self.commits.selectionHandler = ^(__kindof UIViewController *host, Commit *commit) {
        [host.navigationController pushViewController:[
            FLEXObjectExplorerFactory explorerViewControllerForObject:commit
        ] animated:YES];
    };

    self.commits.cellRegistrationMapping = @{ @"Cell" : [CommitListViewCell class] };

    return @[self.commits];
}

// Empty sections are removed by default and we always want this one section
- (NSArray<FLEXTableViewSection *> *)nonemptySections {
    return @[_commits];
}

- (void)fadeInNewRows {
    NSIndexSet *sections = [NSIndexSet indexSetWithIndex:0];
    [self.tableView reloadSections:sections withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)loadImage:(NSString *)imageURL completion:(void(^)(UIImage *image))callback {
    [self startDataTask:imageURL completion:^(NSData *data, NSInteger statusCode, NSError *error) {
        if (statusCode == 200) {
            callback([UIImage imageWithData:data]);
        }
    }];
}

- (void)startDataTask:(NSString *)urlString completion:(void (^)(NSData *data, NSInteger statusCode, NSError *error))completionHandler {
//    return;
    NSURL *url = [NSURL URLWithString:urlString];
    [[NSURLSession.sharedSession dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSInteger code = [(NSHTTPURLResponse *)response statusCode];
            
            completionHandler(data, code, error);
        });
    }] resume];
}

@end
