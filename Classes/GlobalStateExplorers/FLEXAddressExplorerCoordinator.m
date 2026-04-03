//
//  FLEXAddressExplorerCoordinator.m
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

#import "FLEXAddressExplorerCoordinator.h"
#import "FLEXGlobalsViewController.h"
#import "FLEXObjectExplorerFactory.h"
#import "FLEXObjectExplorerViewController.h"
#import "FLEXRuntimeUtility.h"
#import "FLEXUtility.h"

@interface UITableViewController (FLEXAddressExploration)
- (void)deselectSelectedRow;
- (void)tryExploreAddress:(NSString *)addressString safely:(BOOL)safely;
@end

@implementation FLEXAddressExplorerCoordinator

#pragma mark - FLEXGlobalsEntry

+ (NSString *)globalsEntryTitle:(FLEXGlobalsRow)row {
    return @"Address Explorer";
}

+ (FLEXGlobalsEntryRowAction)globalsEntryRowAction:(FLEXGlobalsRow)row {
    return ^(UITableViewController *host) {

        NSString * const title = @"Explore Object at Address";
        NSString * const message = @"Paste a hexadecimal address below, starting with '0x'. "
        "Use the unsafe option if you need to bypass pointer validation, "
        "but know that it may crash the app if the address is invalid.";

        [FLEXAlert makeAlert:^(FLEXAlert *make) {
            make.title(title).message(message);
            make.configuredTextField(^(UITextField *textField) {
                NSString *copied = UIPasteboard.generalPasteboard.string;
                textField.placeholder = @"0x00000070deadbeef";
                // Go ahead and paste our clipboard if we have an address copied
                if ([copied hasPrefix:@"0x"]) {
                    textField.text = copied;
                    [textField selectAll:nil];
                }
            });
            make.button(@"Explore").handler(^(NSArray<NSString *> *strings) {
                [host tryExploreAddress:strings.firstObject safely:YES];
            });
            make.button(@"Unsafe Explore").destructiveStyle().handler(^(NSArray *strings) {
                [host tryExploreAddress:strings.firstObject safely:NO];
            });
            make.button(@"Cancel").cancelStyle();
        } showFrom:host];

    };
}

@end

@implementation UITableViewController (FLEXAddressExploration)

- (void)deselectSelectedRow {
    NSIndexPath *selected = self.tableView.indexPathForSelectedRow;
    [self.tableView deselectRowAtIndexPath:selected animated:YES];
}

- (void)tryExploreAddress:(NSString *)addressString safely:(BOOL)safely {
    NSScanner *scanner = [NSScanner scannerWithString:addressString];
    unsigned long long hexValue = 0;
    BOOL didParseAddress = [scanner scanHexLongLong:&hexValue];
    const void *pointerValue = (void *)hexValue;

    NSString *error = nil;

    if (didParseAddress) {
        if (safely && ![FLEXRuntimeUtility pointerIsValidObjcObject:pointerValue]) {
            error = @"The given address is unlikely to be a valid object.";
        }
    } else {
        error = @"Malformed address. Make sure it's not too long and starts with '0x'.";
    }

    if (!error) {
        id object = (__bridge id)pointerValue;
        FLEXObjectExplorerViewController *explorer = [FLEXObjectExplorerFactory explorerViewControllerForObject:object];
        [self.navigationController pushViewController:explorer animated:YES];
    } else {
        [FLEXAlert showAlert:@"Uh-oh" message:error from:self];
        [self deselectSelectedRow];
    }
}

@end
