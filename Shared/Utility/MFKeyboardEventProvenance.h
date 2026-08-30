//
// --------------------------------------------------------------------------
// MFKeyboardEventProvenance.h
// Created for Mac Mouse Fix (https://github.com/noah-nuebling/mac-mouse-fix)
// Licensed under the MMF License (https://github.com/noah-nuebling/mac-mouse-fix/blob/master/License)
// --------------------------------------------------------------------------
//

#import <CoreGraphics/CoreGraphics.h>

/// A private, process-independent marker for keyboard events synthesized by
/// Mac Mouse Fix. PID and sender metadata are not stable across event taps;
/// the Core Graphics user-data field travels with the event instead.
#define kMFSyntheticKeyboardEventUserData 0x4D4D464B41555431LL

static inline void MFMarkKeyboardEventAsSynthetic(CGEventRef event) {
    if (event != NULL) {
        CGEventSetIntegerValueField(event, kCGEventSourceUserData, kMFSyntheticKeyboardEventUserData);
    }
}

static inline BOOL MFIsSyntheticKeyboardEvent(CGEventRef event) {
    return event != NULL
        && CGEventGetIntegerValueField(event, kCGEventSourceUserData) == kMFSyntheticKeyboardEventUserData;
}
