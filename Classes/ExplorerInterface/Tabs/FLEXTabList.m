//
//  FLEXTabList.m
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

#import "FLEXTabList.h"
#import "FLEXUtility.h"

@interface FLEXTabList () {
    NSMutableArray *_openTabs;
    NSMutableArray *_openTabSnapshots;
}
@end
#pragma mark -
@implementation FLEXTabList

#pragma mark Initialization

+ (FLEXTabList *)sharedList {
    static FLEXTabList *sharedList = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedList = [self new];
    });

    return sharedList;
}

- (id)init {
    self = [super init];
    if (self) {
        _openTabs = [NSMutableArray new];
        _openTabSnapshots = [NSMutableArray new];
        _activeTabIndex = NSNotFound;
    }

    return self;
}


#pragma mark Private

- (void)chooseNewActiveTab {
    if (self.openTabs.count) {
        self.activeTabIndex = self.openTabs.count - 1;
    } else {
        self.activeTabIndex = NSNotFound;
    }
}


#pragma mark Public

- (void)setActiveTabIndex:(NSInteger)idx {
    NSParameterAssert(idx < self.openTabs.count || idx == NSNotFound);
    if (_activeTabIndex == idx) return;

    _activeTabIndex = idx;
    _activeTab = (idx == NSNotFound) ? nil : self.openTabs[idx];
}

- (void)addTab:(UINavigationController *)newTab {
    NSParameterAssert(newTab);

    // Update snapshot of the last active tab
    if (self.activeTab) {
        [self updateSnapshotForActiveTab];
    }

    // Add new tab and snapshot,
    // update active tab and index
    [_openTabs addObject:newTab];
    [_openTabSnapshots addObject:[FLEXUtility previewImageForView:newTab.view]];
    _activeTab = newTab;
    _activeTabIndex = self.openTabs.count - 1;
}

- (void)closeTab:(UINavigationController *)tab {
    NSParameterAssert(tab);
    const NSInteger idx = [self.openTabs indexOfObject:tab];
    if (idx != NSNotFound) {
        [self closeTabAtIndex:idx];
    }

    // Not sure how this is possible, but it happens sometimes
    if (self.activeTab == tab) {
        [self chooseNewActiveTab];
    }

    // It is possible for an object explorer to form a retain cycle
    // with its own navigation controller; clearing the view controllers
    // manually when closing a tab breaks the cycle
    tab.viewControllers = @[];
}

- (void)closeTabAtIndex:(NSInteger)idx {
    NSParameterAssert(idx < self.openTabs.count);

    // Remove old tab and snapshot
    [_openTabs removeObjectAtIndex:idx];
    [_openTabSnapshots removeObjectAtIndex:idx];

    // Update active tab and index if needed
    if (self.activeTabIndex == idx) {
        [self chooseNewActiveTab];
    }
}

- (void)closeTabsAtIndexes:(NSIndexSet *)indexes {
    // Remove old tabs and snapshot
    [_openTabs removeObjectsAtIndexes:indexes];
    [_openTabSnapshots removeObjectsAtIndexes:indexes];

    // Update active tab and index if needed
    if ([indexes containsIndex:self.activeTabIndex]) {
        [self chooseNewActiveTab];
    }
}

- (void)closeActiveTab {
    [self closeTab:self.activeTab];
}

- (void)closeAllTabs {
    // Remove tabs and snapshots
    [_openTabs removeAllObjects];
    [_openTabSnapshots removeAllObjects];

    // Update active tab index
    self.activeTabIndex = NSNotFound;
}

- (void)updateSnapshotForActiveTab {
    if (self.activeTabIndex != NSNotFound) {
        UIImage *newSnapshot = [FLEXUtility previewImageForView:self.activeTab.view];
        [_openTabSnapshots replaceObjectAtIndex:self.activeTabIndex withObject:newSnapshot];
    }
}

@end
