//
//  FLEXGlobalsViewController.m
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

#import "FLEXGlobalsViewController.h"
#import "FLEXUtility.h"
#import "FLEXRuntimeUtility.h"
#import "FLEXObjcRuntimeViewController.h"
#import "FLEXKeychainViewController.h"
#import "FLEXAPNSViewController.h"
#import "FLEXObjectExplorerViewController.h"
#import "FLEXObjectExplorerFactory.h"
#import "FLEXLiveObjectsController.h"
#import "FLEXFileBrowserController.h"
#import "FLEXCookiesViewController.h"
#import "FLEXGlobalsEntry.h"
#import "FLEXManager+Private.h"
#import "FLEXSystemLogViewController.h"
#import "FLEXNetworkMITMViewController.h"
#import "FLEXAddressExplorerCoordinator.h"
#import "FLEXGlobalsSection.h"
#import "UIBarButtonItem+FLEX.h"

@interface FLEXGlobalsViewController ()
/// Only displayed sections of the table view; empty sections are purged from this array.
@property (nonatomic) NSArray<FLEXGlobalsSection *> *sections;
/// Every section in the table view, regardless of whether or not a section is empty.
@property (nonatomic, readonly) NSArray<FLEXGlobalsSection *> *allSections;
@property (nonatomic, readonly) BOOL manuallyDeselectOnAppear;
@end

@implementation FLEXGlobalsViewController
@dynamic sections, allSections;

#pragma mark - Initialization

+ (NSString *)globalsTitleForSection:(FLEXGlobalsSectionKind)section {
    switch (section) {
        case FLEXGlobalsSectionCustom:
            return @"Custom Additions";
        case FLEXGlobalsSectionProcessAndEvents:
            return @"Process and Events";
        case FLEXGlobalsSectionAppShortcuts:
            return @"App Shortcuts";
        case FLEXGlobalsSectionMisc:
            return @"Miscellaneous";

        default:
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Unexpected FLEXGlobalsSection value" userInfo:nil];
    }
}

+ (FLEXGlobalsEntry *)globalsEntryForRow:(FLEXGlobalsRow)row {
    FLEXGlobalsEntry *entry;
    switch (row) {
        case FLEXGlobalsRowAppKeychainItems:
            entry = [FLEXKeychainViewController flex_concreteGlobalsEntry:row]; break;
        case FLEXGlobalsRowPushNotifications:
            entry = [FLEXAPNSViewController flex_concreteGlobalsEntry:row]; break;
        case FLEXGlobalsRowAddressInspector:
            entry = [FLEXAddressExplorerCoordinator flex_concreteGlobalsEntry:row]; break;
        case FLEXGlobalsRowBrowseRuntime:
            entry = [FLEXObjcRuntimeViewController flex_concreteGlobalsEntry:row]; break;
        case FLEXGlobalsRowLiveObjects:
            entry = [FLEXLiveObjectsController flex_concreteGlobalsEntry:row]; break;
        case FLEXGlobalsRowCookies:
            entry = [FLEXCookiesViewController flex_concreteGlobalsEntry:row]; break;
        case FLEXGlobalsRowBrowseBundle:
        case FLEXGlobalsRowBrowseContainer:
            entry = [FLEXFileBrowserController flex_concreteGlobalsEntry:row]; break;
        case FLEXGlobalsRowSystemLog:
            entry = [FLEXSystemLogViewController flex_concreteGlobalsEntry:row]; break;
        case FLEXGlobalsRowNetworkHistory:
            entry = [FLEXNetworkMITMViewController flex_concreteGlobalsEntry:row]; break;
        case FLEXGlobalsRowKeyWindow:
        case FLEXGlobalsRowRootViewController:
        case FLEXGlobalsRowProcessInfo:
        case FLEXGlobalsRowAppDelegate:
        case FLEXGlobalsRowUserDefaults:
        case FLEXGlobalsRowMainBundle:
        case FLEXGlobalsRowApplication:
        case FLEXGlobalsRowMainScreen:
        case FLEXGlobalsRowCurrentDevice:
        case FLEXGlobalsRowPasteboard:
        case FLEXGlobalsRowURLSession:
        case FLEXGlobalsRowURLCache:
        case FLEXGlobalsRowNotificationCenter:
        case FLEXGlobalsRowFileManager:
        case FLEXGlobalsRowTimeZone:
        case FLEXGlobalsRowLocale:
        case FLEXGlobalsRowCalendar:
        case FLEXGlobalsRowMainRunLoop:
        case FLEXGlobalsRowMainThread:
        case FLEXGlobalsRowOperationQueue:
            entry = [FLEXObjectExplorerFactory flex_concreteGlobalsEntry:row]; break;

        case FLEXGlobalsRowCount: break;
    }

    if (!entry) {
        @throw [NSException
            exceptionWithName:NSInternalInconsistencyException
            reason:@"Missing globals case in switch" userInfo:nil
        ];
    }

    entry.symbolName = [self symbolNameForRow:row];
    entry.iconColor = [self colorForRow:row];
    return entry;
}

+ (UIColor *)colorForRow:(FLEXGlobalsRow)row {
    switch (row) {
        // Process and Events — row 1: Blue/Orange/Purple, row 2: Green/Teal/Indigo
        case FLEXGlobalsRowNetworkHistory:      return UIColor.systemBlueColor;
        case FLEXGlobalsRowSystemLog:           return UIColor.systemOrangeColor;
        case FLEXGlobalsRowProcessInfo:         return UIColor.systemPurpleColor;
        case FLEXGlobalsRowLiveObjects:         return UIColor.systemGreenColor;
        case FLEXGlobalsRowAddressInspector:    return UIColor.systemTealColor;
        case FLEXGlobalsRowBrowseRuntime:       return UIColor.systemIndigoColor;
        // App Shortcuts — row1: Orange/Blue/Green, row2: Purple/Indigo/Red,
        //                 row3: Blue/Orange/Teal, row4: Green/Pink
        case FLEXGlobalsRowBrowseBundle:        return UIColor.systemOrangeColor;
        case FLEXGlobalsRowBrowseContainer:     return UIColor.systemBlueColor;
        case FLEXGlobalsRowMainBundle:          return UIColor.systemGreenColor;
        case FLEXGlobalsRowUserDefaults:        return UIColor.systemPurpleColor;
        case FLEXGlobalsRowAppKeychainItems:    return UIColor.systemIndigoColor;
        case FLEXGlobalsRowPushNotifications:   return UIColor.systemRedColor;
        case FLEXGlobalsRowApplication:         return UIColor.systemBlueColor;
        case FLEXGlobalsRowAppDelegate:         return UIColor.systemOrangeColor;
        case FLEXGlobalsRowKeyWindow:           return UIColor.systemTealColor;
        case FLEXGlobalsRowRootViewController:  return UIColor.systemGreenColor;
        case FLEXGlobalsRowCookies:             return UIColor.systemPinkColor;
        // Misc — row1: Orange/Teal/Blue, row2: Green/Purple/Red,
        //        row3: Pink/Orange/Green, row4: Teal/Purple/Blue, row5: Indigo
        case FLEXGlobalsRowPasteboard:          return UIColor.systemOrangeColor;
        case FLEXGlobalsRowMainScreen:          return UIColor.systemTealColor;
        case FLEXGlobalsRowCurrentDevice:       return UIColor.systemBlueColor;
        case FLEXGlobalsRowURLSession:          return UIColor.systemGreenColor;
        case FLEXGlobalsRowURLCache:            return UIColor.systemPurpleColor;
        case FLEXGlobalsRowNotificationCenter:  return UIColor.systemRedColor;
        case FLEXGlobalsRowFileManager:         return UIColor.systemPinkColor;
        case FLEXGlobalsRowTimeZone:            return UIColor.systemOrangeColor;
        case FLEXGlobalsRowLocale:              return UIColor.systemGreenColor;
        case FLEXGlobalsRowCalendar:            return UIColor.systemTealColor;
        case FLEXGlobalsRowMainRunLoop:         return UIColor.systemPurpleColor;
        case FLEXGlobalsRowMainThread:          return UIColor.systemBlueColor;
        case FLEXGlobalsRowOperationQueue:      return UIColor.systemIndigoColor;
        case FLEXGlobalsRowCount:               return nil;
    }
    return nil;
}

+ (NSString *)symbolNameForRow:(FLEXGlobalsRow)row {
    switch (row) {
        case FLEXGlobalsRowNetworkHistory:      return @"network";
        case FLEXGlobalsRowSystemLog:           return @"doc.text.magnifyingglass";
        case FLEXGlobalsRowProcessInfo:         return @"cpu";
        case FLEXGlobalsRowLiveObjects:         return @"memorychip";
        case FLEXGlobalsRowAddressInspector:    return @"mappin.and.ellipse";
        case FLEXGlobalsRowBrowseRuntime:       return @"books.vertical.fill";
        case FLEXGlobalsRowAppKeychainItems:    return @"key.fill";
        case FLEXGlobalsRowPushNotifications:   return @"bell.fill";
        case FLEXGlobalsRowBrowseBundle:        return @"folder.fill";
        case FLEXGlobalsRowBrowseContainer:     return @"internaldrive.fill";
        case FLEXGlobalsRowMainBundle:          return @"shippingbox.fill";
        case FLEXGlobalsRowUserDefaults:        return @"slider.horizontal.3";
        case FLEXGlobalsRowApplication:         return @"iphone";
        case FLEXGlobalsRowAppDelegate:         return @"bolt.fill";
        case FLEXGlobalsRowKeyWindow:           return @"macwindow";
        case FLEXGlobalsRowRootViewController:  return @"rectangle.stack.fill";
        case FLEXGlobalsRowCookies:             return @"lock.shield.fill";
        case FLEXGlobalsRowPasteboard:          return @"doc.on.clipboard.fill";
        case FLEXGlobalsRowMainScreen:          return @"display";
        case FLEXGlobalsRowCurrentDevice:       return @"ipad.landscape";
        case FLEXGlobalsRowURLSession:          return @"globe";
        case FLEXGlobalsRowURLCache:            return @"arrow.triangle.2.circlepath";
        case FLEXGlobalsRowNotificationCenter:  return @"bell.badge.fill";
        case FLEXGlobalsRowFileManager:         return @"folder.badge.gearshape";
        case FLEXGlobalsRowTimeZone:            return @"clock.fill";
        case FLEXGlobalsRowLocale:              return @"globe.americas.fill";
        case FLEXGlobalsRowCalendar:            return @"calendar";
        case FLEXGlobalsRowMainRunLoop:         return @"arrow.clockwise";
        case FLEXGlobalsRowMainThread:          return @"arrow.left.arrow.right";
        case FLEXGlobalsRowOperationQueue:      return @"list.number";
        case FLEXGlobalsRowCount:               return nil;
    }
    return nil;
}

+ (NSArray<FLEXGlobalsSection *> *)defaultGlobalSections {
    static NSMutableArray<FLEXGlobalsSection *> *sections = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSDictionary<NSNumber *, NSArray<FLEXGlobalsEntry *> *> *rowsBySection = @{
            @(FLEXGlobalsSectionProcessAndEvents) : @[
                [self globalsEntryForRow:FLEXGlobalsRowNetworkHistory],
                [self globalsEntryForRow:FLEXGlobalsRowSystemLog],
                [self globalsEntryForRow:FLEXGlobalsRowProcessInfo],
                [self globalsEntryForRow:FLEXGlobalsRowLiveObjects],
                [self globalsEntryForRow:FLEXGlobalsRowAddressInspector],
                [self globalsEntryForRow:FLEXGlobalsRowBrowseRuntime],
            ],
            @(FLEXGlobalsSectionAppShortcuts) : @[
                [self globalsEntryForRow:FLEXGlobalsRowBrowseBundle],
                [self globalsEntryForRow:FLEXGlobalsRowBrowseContainer],
                [self globalsEntryForRow:FLEXGlobalsRowMainBundle],
                [self globalsEntryForRow:FLEXGlobalsRowUserDefaults],
                [self globalsEntryForRow:FLEXGlobalsRowAppKeychainItems],
                [self globalsEntryForRow:FLEXGlobalsRowPushNotifications],
                [self globalsEntryForRow:FLEXGlobalsRowApplication],
                [self globalsEntryForRow:FLEXGlobalsRowAppDelegate],
                [self globalsEntryForRow:FLEXGlobalsRowKeyWindow],
                [self globalsEntryForRow:FLEXGlobalsRowRootViewController],
                [self globalsEntryForRow:FLEXGlobalsRowCookies],
            ],
            @(FLEXGlobalsSectionMisc) : @[
                [self globalsEntryForRow:FLEXGlobalsRowPasteboard],
                [self globalsEntryForRow:FLEXGlobalsRowMainScreen],
                [self globalsEntryForRow:FLEXGlobalsRowCurrentDevice],
                [self globalsEntryForRow:FLEXGlobalsRowURLSession],
                [self globalsEntryForRow:FLEXGlobalsRowURLCache],
                [self globalsEntryForRow:FLEXGlobalsRowNotificationCenter],
                [self globalsEntryForRow:FLEXGlobalsRowFileManager],
                [self globalsEntryForRow:FLEXGlobalsRowTimeZone],
                [self globalsEntryForRow:FLEXGlobalsRowLocale],
                [self globalsEntryForRow:FLEXGlobalsRowCalendar],
                [self globalsEntryForRow:FLEXGlobalsRowMainRunLoop],
                [self globalsEntryForRow:FLEXGlobalsRowMainThread],
                [self globalsEntryForRow:FLEXGlobalsRowOperationQueue],
            ]
        };

        sections = [NSMutableArray array];
        for (FLEXGlobalsSectionKind i = FLEXGlobalsSectionCustom + 1; i < FLEXGlobalsSectionCount; ++i) {
            NSString *title = [self globalsTitleForSection:i];
            [sections addObject:[FLEXGlobalsSection title:title rows:rowsBySection[@(i)]]];
        }
    });

    return sections;
}


#pragma mark - Overrides

- (void)viewDidLoad {
    [super viewDidLoad];

    self.showsSearchBar = YES;
    self.searchBarDebounceInterval = kFLEXDebounceInstant;
    self.navigationItem.backBarButtonItem = [UIBarButtonItem flex_backItemWithTitle:@"Back"];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;

    if (@available(iOS 26.0, *)) {
        // The iOS 26 nav bar leaves a large gap before the first section. Pull the content up.
        self.additionalSafeAreaInsets = UIEdgeInsetsMake(-26, 0, 0, 0);
    }

    if (@available(iOS 26.0, *)) {
        // Add the FLEX logo as a bold custom label in the top left corner.
        // Uses less space than large titles, but also more prominent than the center one
        UILabel *titleLabel = [UILabel new];
        titleLabel.text = @"💪 FLEX";
        titleLabel.font = [UIFont systemFontOfSize:30 weight:UIFontWeightBold];
        titleLabel.textColor = UIColor.labelColor;
        [titleLabel sizeToFit];
        UIBarButtonItem *const barButtonItem = [[UIBarButtonItem alloc] initWithCustomView:titleLabel];
        barButtonItem.hidesSharedBackground = YES;
        self.navigationItem.leftBarButtonItem = barButtonItem;
    } else {
        self.title = @"💪 FLEX";
    }

    _manuallyDeselectOnAppear = NSProcessInfo.processInfo.operatingSystemVersion.majorVersion < 10;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self disableToolbar];

    if (self.manuallyDeselectOnAppear) {
        [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
    }
}

- (NSArray<FLEXGlobalsSection *> *)makeSections {
    NSMutableArray<FLEXGlobalsSection *> *sections = [NSMutableArray array];
    // Do we have custom sections to add?
    if (FLEXManager.sharedManager.userGlobalEntries.count) {
        NSString *title = [[self class] globalsTitleForSection:FLEXGlobalsSectionCustom];
        FLEXGlobalsSection *custom = [FLEXGlobalsSection
            title:title
            rows:FLEXManager.sharedManager.userGlobalEntries
        ];
        [sections addObject:custom];
    }

    [sections addObjectsFromArray:[self.class defaultGlobalSections]];

    NSInteger itemsPerRow = [self itemsPerRowForCurrentWidth];
    for (FLEXGlobalsSection *section in sections) {
        section.hostViewController = self;
        section.itemsPerRow = itemsPerRow;
    }

    return sections;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    NSInteger newItemsPerRow = [self itemsPerRowForCurrentWidth];

    BOOL changed = NO;
    for (FLEXTableViewSection *section in self.allSections) {
        if ([section isKindOfClass:FLEXGlobalsSection.class]) {
            FLEXGlobalsSection *gs = (FLEXGlobalsSection *)section;
            if (gs.itemsPerRow != newItemsPerRow) {
                gs.itemsPerRow = newItemsPerRow;
                changed = YES;
            }
        }
    }

    if (changed) {
        [self.tableView reloadData];
    }
}

- (NSInteger)itemsPerRowForCurrentWidth {
    CGFloat available = self.tableView.bounds.size.width
        - self.tableView.layoutMargins.left
        - self.tableView.layoutMargins.right;
    if (available < 100) {
        // View not yet laid out; use a sensible default
        return 3;
    }
    return MAX(2, (NSInteger)floor(available / 110.0));
}

@end
