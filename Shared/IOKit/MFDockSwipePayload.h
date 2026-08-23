//
// --------------------------------------------------------------------------
// MFDockSwipePayload.h
// Created for Mac Mouse Fix (https://github.com/noah-nuebling/mac-mouse-fix)
// Licensed under the MMF License (https://github.com/noah-nuebling/mac-mouse-fix/blob/master/License)
// --------------------------------------------------------------------------
//

#import <Foundation/Foundation.h>
#import <stdint.h>

typedef uint16_t MFDockSwipePhase;

typedef NS_OPTIONS(MFDockSwipePhase, MFDockSwipePhaseValue) {
    kMFDockSwipePhaseBegan = 1 << 0,
    kMFDockSwipePhaseChanged = 1 << 1,
    kMFDockSwipePhaseEnded = 1 << 2,
    kMFDockSwipePhaseCancelled = 1 << 3,
};

typedef struct {
    double originOffset;
    double lastDelta;
} MFDockSwipeState;

typedef struct {
    BOOL shouldPost;
    MFDockSwipePhase phase;
    double legacyProgress;
    double modernProgress;
    double legacyExitVelocity;
    double modernExitVelocity;
    BOOL includesExitVelocity;
} MFDockSwipePayload;

FOUNDATION_EXPORT MFDockSwipeState MFDockSwipeStateMake(void);

/// Advances one Dock-swipe stream and returns the values required by both event encodings.
/// A zero-delta changed event is suppressed and leaves state untouched, matching the historical behavior.
FOUNDATION_EXPORT MFDockSwipePayload MFDockSwipePayloadAdvance(MFDockSwipeState *state,
                                                              double delta,
                                                              MFDockSwipePhase phase,
                                                              BOOL invertedFromDevice);
