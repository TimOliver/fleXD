//
//  FLEXQuickLookController.m
//
//  Copyright (c) FLEX Team (2020-2026).
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

#import "FLEXQuickLookController.h"

@interface FLEXQuickLookController () <QLPreviewControllerDataSource>
@property (nonatomic) NSURL *fileURL;
@end

@implementation FLEXQuickLookController

+ (nullable instancetype)forFileAtPath:(NSString *)path {
    NSURL *fileURL = [NSURL fileURLWithPath:path];

    // Fast path: QL can identify the type from the file extension.
    if (path.pathExtension.length > 0 && [QLPreviewController canPreviewItem:fileURL]) {
        return [self controllerWithFileURL:fileURL];
    }

    // Slow path: no extension (or unrecognised extension). Sniff the file type
    // from magic bytes and point QL at a temporary symlink that has the right extension.
    NSString *ext = [self detectedExtensionForFileAtPath:path];
    if (!ext) {
        return nil;
    }

    NSURL *copyURL = [self temporaryCopyForPath:path extension:ext];
    if (!copyURL || ![QLPreviewController canPreviewItem:copyURL]) {
        return nil;
    }

    return [self controllerWithFileURL:copyURL];
}

+ (instancetype)controllerWithFileURL:(NSURL *)fileURL {
    FLEXQuickLookController *controller = [self new];
    controller.fileURL = fileURL;
    controller.dataSource = controller;
    return controller;
}

/// Reads the first 16 bytes of the file and returns a suitable extension,
/// or nil if the type is not recognised.
+ (nullable NSString *)detectedExtensionForFileAtPath:(NSString *)path {
    NSFileHandle *handle = [NSFileHandle fileHandleForReadingAtPath:path];
    if (!handle) return nil;
    NSData *header = [handle readDataOfLength:16];
    [handle closeFile];

    if (header.length < 4) return nil;
    const uint8_t *b = header.bytes;

    // JPEG: FF D8 FF
    if (b[0] == 0xFF && b[1] == 0xD8 && b[2] == 0xFF) return @"jpeg";

    // PNG: 89 50 4E 47 0D 0A 1A 0A
    if (b[0] == 0x89 && b[1] == 0x50 && b[2] == 0x4E && b[3] == 0x47) return @"png";

    // GIF: 47 49 46 38 ("GIF8")
    if (b[0] == 0x47 && b[1] == 0x49 && b[2] == 0x46 && b[3] == 0x38) return @"gif";

    // PDF: 25 50 44 46 ("%PDF")
    if (b[0] == 0x25 && b[1] == 0x50 && b[2] == 0x44 && b[3] == 0x46) return @"pdf";

    // TIFF little-endian: 49 49 2A 00
    if (b[0] == 0x49 && b[1] == 0x49 && b[2] == 0x2A && b[3] == 0x00) return @"tiff";

    // TIFF big-endian: 4D 4D 00 2A
    if (b[0] == 0x4D && b[1] == 0x4D && b[2] == 0x00 && b[3] == 0x2A) return @"tiff";

    // WebP: 52 49 46 46 ?? ?? ?? ?? 57 45 42 50 ("RIFF....WEBP")
    if (header.length >= 12 &&
        b[0] == 0x52 && b[1] == 0x49 && b[2] == 0x46 && b[3] == 0x46 &&
        b[8] == 0x57 && b[9] == 0x45 && b[10] == 0x42 && b[11] == 0x50) return @"webp";

    // MP3: FF FB / FF F3 / FF F2, or ID3 tag: 49 44 33
    if ((b[0] == 0xFF && (b[1] == 0xFB || b[1] == 0xF3 || b[1] == 0xF2)) ||
        (b[0] == 0x49 && b[1] == 0x44 && b[2] == 0x33)) return @"mp3";

    // MP4/MOV/M4A/M4V: ftyp box at offset 4 — 66 74 79 70
    if (header.length >= 8 && b[4] == 0x66 && b[5] == 0x74 && b[6] == 0x79 && b[7] == 0x70) return @"mp4";

    return nil;
}

/// Copies the file at `path` into the temp directory with `extension` appended,
/// so QuickLook can access it directly without following symlinks.
/// Returns the copy's URL, or nil on failure.
+ (nullable NSURL *)temporaryCopyForPath:(NSString *)path extension:(NSString *)extension {
    NSString *filename = [path.lastPathComponent stringByAppendingPathExtension:extension];
    NSString *copyPath = [NSTemporaryDirectory() stringByAppendingPathComponent:filename];

    NSFileManager *fm = NSFileManager.defaultManager;
    [fm removeItemAtPath:copyPath error:nil]; // remove stale copy if present

    NSError *error = nil;
    [fm copyItemAtPath:path toPath:copyPath error:&error];
    return error ? nil : [NSURL fileURLWithPath:copyPath];
}


#pragma mark - QLPreviewControllerDataSource

- (NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)controller {
    return 1;
}

- (id<QLPreviewItem>)previewController:(QLPreviewController *)controller previewItemAtIndex:(NSInteger)index {
    return self.fileURL;
}

@end
