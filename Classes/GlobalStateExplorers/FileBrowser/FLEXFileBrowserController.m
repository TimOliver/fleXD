//
//  FLEXFileBrowserController.m
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

#import "FLEXFileBrowserController.h"
#import "FLEXUtility.h"
#import "FLEXWebViewController.h"
#import "FLEXActivityViewController.h"
#import "FLEXQuickLookController.h"
#import "FLEXImagePreviewController.h"
#import "FLEXTableListViewController.h"
#import "FLEXObjectExplorerFactory.h"
#import "FLEXObjectExplorerViewController.h"
#import <mach-o/loader.h>
#import <ImageIO/ImageIO.h>
#import "FLEXFileBrowserSearchOperation.h"
#import "FLEXFileBrowserCell.h"

static NSDateFormatter *FLEXFileBrowserDateFormatter(void) {
    static NSDateFormatter *formatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [NSDateFormatter new];
        formatter.dateStyle = NSDateFormatterMediumStyle;
        formatter.timeStyle = NSDateFormatterNoStyle;
    });
    return formatter;
}

// SF Symbols don't exist before iOS 13, so draw simple folder/document
// silhouettes in Core Graphics for that case. Returned as plain (black) shapes;
// the cell re-templates and tints them like the SF Symbol icons.
static UIImage *FLEXFileBrowserDrawLegacyIcon(BOOL isFolder) {
    CGFloat side = 40.0;
    UIGraphicsImageRendererFormat *format = UIGraphicsImageRendererFormat.preferredFormat;
    format.opaque = NO;
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc]
        initWithSize:CGSizeMake(side, side) format:format];

    return [renderer imageWithActions:^(UIGraphicsImageRendererContext *context) {
        [UIColor.blackColor setFill];

        if (isFolder) {
            CGFloat width = 26.0, height = 22.0;
            CGFloat x = (side - width) / 2.0, y = (side - height) / 2.0;
            CGFloat tabWidth = 11.0, tabHeight = 5.0, radius = 3.0;

            // A raised tab on the top-left, with the body filling the rest below it.
            UIBezierPath *tab = [UIBezierPath bezierPathWithRoundedRect:
                CGRectMake(x, y, tabWidth, tabHeight + radius) cornerRadius:radius];
            UIBezierPath *body = [UIBezierPath bezierPathWithRoundedRect:
                CGRectMake(x, y + tabHeight, width, height - tabHeight) cornerRadius:radius];
            [tab fill];
            [body fill];
        } else {
            CGFloat width = 23.0, height = 29.0;
            CGFloat x = (side - width) / 2.0, y = (side - height) / 2.0;
            CGFloat fold = 8.0, radius = 3.0;

            // A page with rounded corners and a folded-down top-right corner.
            UIBezierPath *page = [UIBezierPath bezierPath];
            [page moveToPoint:CGPointMake(x + radius, y)];
            [page addLineToPoint:CGPointMake(x + width - fold, y)];
            [page addLineToPoint:CGPointMake(x + width, y + fold)];
            [page addLineToPoint:CGPointMake(x + width, y + height - radius)];
            [page addQuadCurveToPoint:CGPointMake(x + width - radius, y + height)
                          controlPoint:CGPointMake(x + width, y + height)];
            [page addLineToPoint:CGPointMake(x + radius, y + height)];
            [page addQuadCurveToPoint:CGPointMake(x, y + height - radius)
                          controlPoint:CGPointMake(x, y + height)];
            [page addLineToPoint:CGPointMake(x, y + radius)];
            [page addQuadCurveToPoint:CGPointMake(x + radius, y)
                          controlPoint:CGPointMake(x, y)];
            [page closePath];
            [page fill];
        }
    }];
}

static UIImage *FLEXFileBrowserLegacyIcon(BOOL isFolder) {
    static UIImage *folderImage = nil;
    static UIImage *documentImage = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        folderImage = FLEXFileBrowserDrawLegacyIcon(YES);
        documentImage = FLEXFileBrowserDrawLegacyIcon(NO);
    });
    return isFolder ? folderImage : documentImage;
}

static UIImage *FLEXFileBrowserFolderIcon(void) {
    if (@available(iOS 13.0, *)) {
        return [UIImage systemImageNamed:@"folder.fill"];
    }
    return FLEXFileBrowserLegacyIcon(YES);
}

static UIImage *FLEXFileBrowserDocumentIcon(void) {
    if (@available(iOS 13.0, *)) {
        return [UIImage systemImageNamed:@"doc.fill"];
    }
    return FLEXFileBrowserLegacyIcon(NO);
}

static UIImage *FLEXFileBrowserThumbnail(NSString *path, CGFloat pointSize, CGFloat scale) {
    NSURL *url = [NSURL fileURLWithPath:path];
    CGImageSourceRef source = CGImageSourceCreateWithURL((__bridge CFURLRef)url, NULL);
    if (!source) {
        return nil;
    }
    // Not an image (CGImageSource can't identify a type): bail.
    if (!CGImageSourceGetType(source)) {
        CFRelease(source);
        return nil;
    }

    NSDictionary *options = @{
        (id)kCGImageSourceCreateThumbnailFromImageAlways: @YES,
        (id)kCGImageSourceCreateThumbnailWithTransform: @YES,
        (id)kCGImageSourceThumbnailMaxPixelSize: @(pointSize * scale),
    };
    CGImageRef thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, (__bridge CFDictionaryRef)options);
    CFRelease(source);
    if (!thumbnail) {
        return nil;
    }

    UIImage *image = [UIImage imageWithCGImage:thumbnail scale:scale orientation:UIImageOrientationUp];
    CGImageRelease(thumbnail);
    return image;
}

typedef NS_ENUM(NSUInteger, FLEXFileBrowserSortAttribute) {
    FLEXFileBrowserSortAttributeNone = 0,
    FLEXFileBrowserSortAttributeName,
    FLEXFileBrowserSortAttributeCreationDate,
};

@interface FLEXFileBrowserController () <FLEXFileBrowserSearchOperationDelegate>

@property (nonatomic, copy) NSString *path;
@property (nonatomic, copy) NSArray<NSString *> *childPaths;
@property (nonatomic) NSArray<NSString *> *searchPaths;
@property (nonatomic) NSNumber *recursiveSize;
@property (nonatomic) NSNumber *searchPathsSize;
@property (nonatomic) NSOperationQueue *operationQueue;
@property (nonatomic) NSCache<NSString *, id> *thumbnailCache;
@property (nonatomic) FLEXFileBrowserSortAttribute sortAttribute;

@end

@implementation FLEXFileBrowserController

+ (instancetype)path:(NSString *)path {
    return [[self alloc] initWithPath:path];
}

- (id)init {
    return [self initWithPath:NSHomeDirectory()];
}

- (id)initWithPath:(NSString *)path {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        self.path = path;
        self.title = [path lastPathComponent];
        self.operationQueue = [NSOperationQueue new];
        self.thumbnailCache = [NSCache new];

        // Compute path size
        weakify(self)
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSFileManager *fileManager = NSFileManager.defaultManager;
            NSDictionary<NSString *, id> *attributes = [fileManager attributesOfItemAtPath:path error:NULL];
            uint64_t totalSize = [attributes fileSize];

            for (NSString *fileName in [fileManager enumeratorAtPath:path]) {
                attributes = [fileManager attributesOfItemAtPath:[path stringByAppendingPathComponent:fileName] error:NULL];
                totalSize += [attributes fileSize];

                // Bail if the interested view controller has gone away
                if (!self) {
                    return;
                }
            }

            dispatch_async(dispatch_get_main_queue(), ^{ strongify(self)
                self.recursiveSize = @(totalSize);
                [self.tableView reloadData];
            });
        });

        [self reloadCurrentPath];
    }
    return self;
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.tableView registerClass:[FLEXFileBrowserCell class] forCellReuseIdentifier:@"fileCell"];
    self.tableView.rowHeight = 60.0;

    self.showsSearchBar = YES;
    self.searchBarDebounceInterval = kFLEXDebounceForAsyncSearch;
    [self addToolbarItems:@[
        [[UIBarButtonItem alloc] initWithTitle:@"Sort"
                                         style:UIBarButtonItemStylePlain
                                        target:self
                                        action:@selector(sortDidTouchUpInside:)]
    ]];
}

- (void)sortDidTouchUpInside:(UIBarButtonItem *)sortButton {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Sort"
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleActionSheet];
    [alertController addAction:[UIAlertAction actionWithTitle:@"None"
                                                        style:UIAlertActionStyleCancel
                                                      handler:^(UIAlertAction * _Nonnull action) {
        [self sortWithAttribute:FLEXFileBrowserSortAttributeNone];
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"Name"
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * _Nonnull action) {
        [self sortWithAttribute:FLEXFileBrowserSortAttributeName];
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"Creation Date"
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * _Nonnull action) {
        [self sortWithAttribute:FLEXFileBrowserSortAttributeCreationDate];
    }]];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)sortWithAttribute:(FLEXFileBrowserSortAttribute)attribute {
    self.sortAttribute = attribute;
    [self reloadDisplayedPaths];
}

#pragma mark - FLEXGlobalsEntry

+ (NSString *)globalsEntryTitle:(FLEXGlobalsRow)row {
    switch (row) {
        case FLEXGlobalsRowBrowseBundle: return @"App Bundle Directory";
        case FLEXGlobalsRowBrowseContainer: return @"App Sandbox Directory";
        default: return nil;
    }
}

+ (UIViewController *)globalsEntryViewController:(FLEXGlobalsRow)row {
    switch (row) {
        case FLEXGlobalsRowBrowseBundle: return [[self alloc] initWithPath:NSBundle.mainBundle.bundlePath];
        case FLEXGlobalsRowBrowseContainer: return [[self alloc] initWithPath:NSHomeDirectory()];
        default: return [self new];
    }
}

#pragma mark - FLEXFileBrowserSearchOperationDelegate

- (void)fileBrowserSearchOperationResult:(NSArray<NSString *> *)searchResult size:(uint64_t)size {
    self.searchPaths = searchResult;
    self.searchPathsSize = @(size);
    [self.tableView reloadData];
}

#pragma mark - Search bar

- (void)updateSearchResults:(NSString *)newText {
    [self reloadDisplayedPaths];
}

#pragma mark UISearchControllerDelegate

- (void)willDismissSearchController:(UISearchController *)searchController {
    [self.operationQueue cancelAllOperations];
    [self reloadCurrentPath];
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.searchController.isActive ? self.searchPaths.count : self.childPaths.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    BOOL isSearchActive = self.searchController.isActive;
    NSNumber *currentSize = isSearchActive ? self.searchPathsSize : self.recursiveSize;
    NSArray<NSString *> *currentPaths = isSearchActive ? self.searchPaths : self.childPaths;

    NSString *sizeString = nil;
    if (!currentSize) {
        sizeString = @"Computing size…";
    } else {
        sizeString = [NSByteCountFormatter stringFromByteCount:[currentSize longLongValue] countStyle:NSByteCountFormatterCountStyleFile];
    }

    return [NSString stringWithFormat:@"%lu files (%@)", (unsigned long)currentPaths.count, sizeString];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *fullPath = [self filePathAtIndexPath:indexPath];
    NSDictionary<NSString *, id> *attributes = [NSFileManager.defaultManager attributesOfItemAtPath:fullPath error:NULL];
    BOOL isDirectory = [attributes.fileType isEqual:NSFileTypeDirectory];

    FLEXFileBrowserCell *cell = [tableView dequeueReusableCellWithIdentifier:@"fileCell" forIndexPath:indexPath];
    cell.representedPath = fullPath;
    cell.titleLabel.text = fullPath.lastPathComponent;
    cell.subtitleLabel.text = [self subtitleForPath:fullPath attributes:attributes isDirectory:isDirectory];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    if (isDirectory) {
        [cell setSymbolIcon:FLEXFileBrowserFolderIcon() tintColor:UIColor.systemBlueColor];
    } else {
        [cell setSymbolIcon:FLEXFileBrowserDocumentIcon() tintColor:UIColor.systemGrayColor];
        [self loadThumbnailForPath:fullPath intoCell:cell];
    }

    return cell;
}

- (void)loadThumbnailForPath:(NSString *)path intoCell:(FLEXFileBrowserCell *)cell {
    id cached = [self.thumbnailCache objectForKey:path];
    if ([cached isKindOfClass:[UIImage class]]) {
        [cell setThumbnail:cached];
        return;
    }
    if (cached) {
        // Cached NSNull: known to not be an image, leave the document icon.
        return;
    }

    CGFloat scale = UIScreen.mainScreen.scale;
    weakify(self)
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{ strongify(self)
        UIImage *thumbnail = FLEXFileBrowserThumbnail(path, 40.0, scale);
        if (!self) {
            return;
        }
        [self.thumbnailCache setObject:(thumbnail ?: (id)NSNull.null) forKey:path];

        if (!thumbnail) {
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([cell.representedPath isEqualToString:path]) {
                [cell setThumbnail:thumbnail];
            }
        });
    });
}

- (NSString *)subtitleForPath:(NSString *)path
                   attributes:(NSDictionary<NSString *, id> *)attributes
                  isDirectory:(BOOL)isDirectory {
    if (isDirectory) {
        NSUInteger count = [NSFileManager.defaultManager contentsOfDirectoryAtPath:path error:NULL].count;
        return [NSString stringWithFormat:@"%lu item%@", (unsigned long)count, (count == 1 ? @"" : @"s")];
    }

    NSString *sizeString = [NSByteCountFormatter stringFromByteCount:attributes.fileSize
                                                          countStyle:NSByteCountFormatterCountStyleFile];
    NSDate *modified = attributes.fileModificationDate;
    if (modified) {
        NSString *dateString = [FLEXFileBrowserDateFormatter() stringFromDate:modified];
        return [NSString stringWithFormat:@"%@ · %@", dateString, sizeString];
    }
    return sizeString;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];

    NSString *fullPath = [self filePathAtIndexPath:indexPath];
    NSString *subpath = fullPath.lastPathComponent;
    NSString *pathExtension = subpath.pathExtension;

    BOOL isDirectory = NO;
    BOOL stillExists = [NSFileManager.defaultManager fileExistsAtPath:fullPath isDirectory:&isDirectory];
    if (!stillExists) {
        [FLEXAlert showAlert:@"File Not Found" message:@"The file at the specified path no longer exists." from:self];
        [self reloadDisplayedPaths];
        return;
    }

    UIViewController *drillInViewController = nil;
    if (isDirectory) {
        drillInViewController = [[[self class] alloc] initWithPath:fullPath];
    } else {
        NSData *fileData = [NSData dataWithContentsOfFile:fullPath];
        if (!fileData.length) {
            [FLEXAlert showAlert:@"Empty File" message:@"No data returned from the file." from:self];
            return;
        }

        // Special case keyed archives, json, and plists to get more readable data.
        NSString *prettyString = nil;
        if ([pathExtension isEqualToString:@"json"]) {
            prettyString = [FLEXUtility prettyJSONStringFromData:fileData];
        } else {
            // Try to decode an archived object, regardless of file extension
            NSKeyedUnarchiver *unarchiver = ({
                NSKeyedUnarchiver *obj = [[NSKeyedUnarchiver alloc] initForReadingFromData:fileData error:nil];
                obj.requiresSecureCoding = NO;
                obj;
            });
            id object = [unarchiver decodeObjectForKey:NSKeyedArchiveRootObjectKey];

            // Try to decode other things instead
            object = object ?: [NSPropertyListSerialization
                propertyListWithData:fileData
                options:0
                format:NULL
                error:NULL
            ] ?: [NSDictionary dictionaryWithContentsOfFile:fullPath]
              ?: [NSArray arrayWithContentsOfFile:fullPath];

            if (object) {
                drillInViewController = [FLEXObjectExplorerFactory explorerViewControllerForObject:object];
            } else {
                // Is it possibly a mach-O file?
                if (fileData.length > sizeof(struct mach_header_64)) {
                    struct mach_header_64 header;
                    [fileData getBytes:&header length:sizeof(struct mach_header_64)];

                    // Does it have the mach header magic number?
                    if (header.magic == MH_MAGIC_64) {
                        // See if we can get some classes out of it...
                        unsigned int count = 0;
                        const char **classList = objc_copyClassNamesForImage(
                            fullPath.UTF8String, &count
                        );

                        if (count > 0) {
                            NSArray<NSString *> *classNames = [NSArray flex_forEachUpTo:count map:^id(NSUInteger i) {
                                return objc_getClass(classList[i]);
                            }];
                            drillInViewController = [FLEXObjectExplorerFactory explorerViewControllerForObject:classNames];
                        }
                    }
                }
            }
        }

        if (prettyString.length) {
            drillInViewController = [[FLEXWebViewController alloc] initWithText:prettyString];
        } else if ([FLEXTableListViewController supportsExtension:pathExtension]) {
            drillInViewController = [[FLEXTableListViewController alloc] initWithPath:fullPath];
        } else if (!drillInViewController) {
            // Prefer our own image viewer over QuickLook: it handles images without
            // recognisable extensions and supports zoom-transition presentation.
            // Sniff the file via CGImageSource so large images don't stall the
            // presentation on a synchronous main-thread decode — the preview
            // controller decodes the full image asynchronously.
            CGImageSourceRef source = CGImageSourceCreateWithURL(
                (__bridge CFURLRef)[NSURL fileURLWithPath:fullPath], NULL
            );
            BOOL isImage = source && CGImageSourceGetType(source);
            if (source) CFRelease(source);

            if (isImage) {
                drillInViewController = [FLEXImagePreviewController
                    forImageAtPath:fullPath placeholder:nil];
            } else {
                // QuickLook handles video, audio, PDFs, and many other document types
                drillInViewController = [FLEXQuickLookController forFileAtPath:fullPath];
            }

            if (!drillInViewController) {
                // Plain text fallback for files QuickLook cannot handle
                NSString *fileString = [NSString stringWithUTF8String:fileData.bytes];
                if (fileString.length) {
                    drillInViewController = [[FLEXWebViewController alloc] initWithText:fileString];
                }
            }
        }
    }

    if ([drillInViewController isKindOfClass:FLEXQuickLookController.class]) {
        // Present QL full-screen so it covers the entire display, including the FLEX toolbar
        drillInViewController.modalPresentationStyle = UIModalPresentationFullScreen;
        [self.navigationController presentViewController:drillInViewController animated:YES completion:nil];
    } else if ([drillInViewController isKindOfClass:FLEXImagePreviewController.class]) {
        drillInViewController.title = subpath.lastPathComponent;
        // Wrap in a nav controller and present full-screen so the image covers the
        // entire display — including the FLEX explorer toolbar and close button.
        UINavigationController *nav = [[UINavigationController alloc]
            initWithRootViewController:drillInViewController];
        nav.modalPresentationStyle = UIModalPresentationFullScreen;
        if (@available(iOS 18.0, *)) {
            UITableViewCell *selectedCell = [tableView cellForRowAtIndexPath:indexPath];
            UIView *source = [selectedCell isKindOfClass:[FLEXFileBrowserCell class]]
                ? ((FLEXFileBrowserCell *)selectedCell).iconImageView
                : selectedCell.imageView;
            nav.preferredTransition = [UIViewControllerTransition
                zoomWithOptions:nil
                sourceViewProvider:^UIView *(UIZoomTransitionSourceViewProviderContext *ctx) {
                    return source;
                }
            ];
        }
        [self.navigationController presentViewController:nav animated:YES completion:nil];
    } else if (drillInViewController) {
        drillInViewController.title = subpath.lastPathComponent;
        [self.navigationController pushViewController:drillInViewController animated:YES];
    } else {
        // Share the file otherwise
        [self openFileController:fullPath];
    }
}

- (UIContextMenuConfiguration *)tableView:(UITableView *)tableView
contextMenuConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath
                                    point:(CGPoint)point {
    weakify(self)
    return [UIContextMenuConfiguration configurationWithIdentifier:nil previewProvider:nil
        actionProvider:^UIMenu *(NSArray<UIMenuElement *> *suggestedActions) {
            UITableViewCell * const cell = [tableView cellForRowAtIndexPath:indexPath];
            UIAction *rename = [UIAction actionWithTitle:@"Rename" image:nil identifier:@"Rename"
                handler:^(UIAction *action) { strongify(self)
                    [self fileBrowserRename:cell];
                }
            ];
            UIAction *delete = [UIAction actionWithTitle:@"Delete" image:nil identifier:@"Delete"
                handler:^(UIAction *action) { strongify(self)
                    [self fileBrowserDelete:cell];
                }
            ];
            UIAction *copyPath = [UIAction actionWithTitle:@"Copy Path" image:nil identifier:@"Copy Path"
                handler:^(UIAction *action) { strongify(self)
                    [self fileBrowserCopyPath:cell];
                }
            ];
            UIAction *share = [UIAction actionWithTitle:@"Share" image:nil identifier:@"Share"
                handler:^(UIAction *action) { strongify(self)
                    [self fileBrowserShare:cell];
                }
            ];

            return [UIMenu menuWithTitle:@"Manage File" image:nil
                identifier:@"Manage File"
                options:UIMenuOptionsDisplayInline
                children:@[rename, delete, copyPath, share]
            ];
        }
    ];
}

- (void)openFileController:(NSString *)fullPath {
    NSURL *fileURL = [NSURL fileURLWithPath:fullPath];
    UIViewController *shareSheet = [FLEXActivityViewController sharing:@[fileURL] source:self.view];
    [self presentViewController:shareSheet animated:YES completion:nil];
}

- (void)fileBrowserRename:(UITableViewCell *)sender {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
    NSString *fullPath = [self filePathAtIndexPath:indexPath];

    BOOL stillExists = [NSFileManager.defaultManager fileExistsAtPath:self.path isDirectory:NULL];
    if (stillExists) {
        [FLEXAlert makeAlert:^(FLEXAlert *make) {
            make.title([NSString stringWithFormat:@"Rename %@?", fullPath.lastPathComponent]);
            make.configuredTextField(^(UITextField *textField) {
                textField.placeholder = @"New file name";
                textField.text = fullPath.lastPathComponent;
            });
            make.button(@"Rename").handler(^(NSArray<NSString *> *strings) {
                NSString *newFileName = strings.firstObject;
                NSString *newPath = [fullPath.stringByDeletingLastPathComponent stringByAppendingPathComponent:newFileName];
                [NSFileManager.defaultManager moveItemAtPath:fullPath toPath:newPath error:NULL];
                [self reloadDisplayedPaths];
            });
            make.button(@"Cancel").cancelStyle();
        } showFrom:self];
    } else {
        [FLEXAlert showAlert:@"File Removed" message:@"The file at the specified path no longer exists." from:self];
    }
}

- (void)fileBrowserDelete:(UITableViewCell *)sender {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
    NSString *fullPath = [self filePathAtIndexPath:indexPath];

    BOOL isDirectory = NO;
    BOOL stillExists = [NSFileManager.defaultManager fileExistsAtPath:fullPath isDirectory:&isDirectory];
    if (stillExists) {
        [FLEXAlert makeAlert:^(FLEXAlert *make) {
            make.title(@"Confirm Deletion");
            make.message([NSString stringWithFormat:
                @"The %@ '%@' will be deleted. This operation cannot be undone",
                (isDirectory ? @"directory" : @"file"), fullPath.lastPathComponent
            ]);
            make.button(@"Delete").destructiveStyle().handler(^(NSArray<NSString *> *strings) {
                [NSFileManager.defaultManager removeItemAtPath:fullPath error:NULL];
                [self reloadDisplayedPaths];
            });
            make.button(@"Cancel").cancelStyle();
        } showFrom:self];
    } else {
        [FLEXAlert showAlert:@"File Removed" message:@"The file at the specified path no longer exists." from:self];
    }
}

- (void)fileBrowserCopyPath:(UITableViewCell *)sender {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
    NSString *fullPath = [self filePathAtIndexPath:indexPath];
    UIPasteboard.generalPasteboard.string = fullPath;
}

- (void)fileBrowserShare:(UITableViewCell *)sender {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
    NSString *pathString = [self filePathAtIndexPath:indexPath];
    NSURL *filePath = [NSURL fileURLWithPath:pathString];

    BOOL isDirectory = NO;
    [NSFileManager.defaultManager fileExistsAtPath:pathString isDirectory:&isDirectory];

    if (isDirectory) {
        // UIDocumentInteractionController for folders
        [self openFileController:pathString];
    } else {
        // Share sheet for files
        UIViewController *shareSheet = [FLEXActivityViewController sharing:@[filePath] source:sender];
        [self presentViewController:shareSheet animated:true completion:nil];
    }
}

- (void)reloadDisplayedPaths {
    if (self.searchController.isActive) {
        [self updateSearchPaths];
    } else {
        [self reloadCurrentPath];
        [self.tableView reloadData];
    }
}

- (void)reloadCurrentPath {
    NSMutableArray<NSString *> *childPaths = [NSMutableArray new];
    NSArray<NSString *> *subpaths = [NSFileManager.defaultManager contentsOfDirectoryAtPath:self.path error:NULL];
    for (NSString *subpath in subpaths) {
        [childPaths addObject:[self.path stringByAppendingPathComponent:subpath]];
    }
    if (self.sortAttribute != FLEXFileBrowserSortAttributeNone) {
        [childPaths sortUsingComparator:^NSComparisonResult(NSString *path1, NSString *path2) {
            switch (self.sortAttribute) {
                case FLEXFileBrowserSortAttributeNone:
                    // invalid state
                    return NSOrderedSame;
                case FLEXFileBrowserSortAttributeName:
                    return [path1 compare:path2];
                case FLEXFileBrowserSortAttributeCreationDate: {
                    NSDictionary<NSFileAttributeKey, id> *path1Attributes = [NSFileManager.defaultManager attributesOfItemAtPath:path1
                                                                                                                           error:NULL];
                    NSDictionary<NSFileAttributeKey, id> *path2Attributes = [NSFileManager.defaultManager attributesOfItemAtPath:path2
                                                                                                                           error:NULL];
                    NSDate *path1Date = path1Attributes[NSFileCreationDate];
                    NSDate *path2Date = path2Attributes[NSFileCreationDate];

                    return [path1Date compare:path2Date];
                }
            }
        }];
    }
    self.childPaths = childPaths;
}

- (void)updateSearchPaths {
    self.searchPaths = nil;
    self.searchPathsSize = nil;

    //clear pre search request and start a new one
    [self.operationQueue cancelAllOperations];
    FLEXFileBrowserSearchOperation *newOperation = [[FLEXFileBrowserSearchOperation alloc] initWithPath:self.path searchString:self.searchText];
    newOperation.delegate = self;
    [self.operationQueue addOperation:newOperation];
}

- (NSString *)filePathAtIndexPath:(NSIndexPath *)indexPath {
    return self.searchController.isActive ? self.searchPaths[indexPath.row] : self.childPaths[indexPath.row];
}

@end
