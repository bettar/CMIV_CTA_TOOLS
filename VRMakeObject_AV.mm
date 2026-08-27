#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

// Minimal AVFoundation-based fallback for creating an "object movie" on 64-bit macOS.
// This does NOT produce legacy QuickTime VR tracks (QTVR) because those APIs and file
// formats rely on QuickTime/Carbon. Instead this function copies the source movie's
// video track into a QuickTime movie container at the destination path. This provides
// a usable movie file on modern macOS where QuickTime APIs are unavailable.

int VRObject_MakeObjectMovie_AV(const char *theMoviePath, const char *theDestPath, long maxFrames)
{
    @autoreleasepool {
        if (theMoviePath == NULL || theDestPath == NULL)
            return -1;

        NSString *srcPath = [NSString stringWithUTF8String:theMoviePath];
        NSString *dstPath = [NSString stringWithUTF8String:theDestPath];
        if (!srcPath || !dstPath)
            return -2;

        NSURL *srcURL = [NSURL fileURLWithPath:srcPath];
        NSURL *dstURL = [NSURL fileURLWithPath:dstPath];

        // Remove existing destination file if present
        NSFileManager *fm = [NSFileManager defaultManager];
        if ([fm fileExistsAtPath:dstPath]) {
            NSError *removeErr = nil;
            [fm removeItemAtPath:dstPath error:&removeErr];
            if (removeErr) {
                // couldn't remove existing file
                return -3;
            }
        }

        AVURLAsset *asset = [AVURLAsset URLAssetWithURL:srcURL options:nil];
        if (!asset)
            return -4;

        // Choose a suitable preset; passthrough preserves original tracks if possible
        NSString *preset = AVAssetExportPresetPassthrough;
        NSArray *presets = [AVAssetExportSession exportPresetsCompatibleWithAsset:asset];
        if (![presets containsObject:preset] && presets.count > 0) {
            preset = presets.firstObject;
        }

        AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:asset presetName:preset];
        if (!exporter)
            return -5;

        exporter.outputURL = dstURL;
        // Use QuickTime movie container when possible
        if ([[AVAssetExportSession allExportPresets] containsObject:AVAssetExportPresetPassthrough]) {
            exporter.outputFileType = AVFileTypeQuickTimeMovie;
        } else {
            exporter.outputFileType = AVFileTypeMPEG4;
        }

        dispatch_semaphore_t sem = dispatch_semaphore_create(0);
        [exporter exportAsynchronouslyWithCompletionHandler:^{
            dispatch_semaphore_signal(sem);
        }];

        // Wait up to 120 seconds for export to finish
        dispatch_time_t timeout = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(120 * NSEC_PER_SEC));
        long waitRes = dispatch_semaphore_wait(sem, timeout);
        if (waitRes != 0) {
            // timeout
            return -10;
        }

        if (exporter.status == AVAssetExportSessionStatusCompleted) {
            return 0;
        } else {
            NSError *err = exporter.error;
            if (err) return (int)err.code;
            return -11;
        }
    }
}
