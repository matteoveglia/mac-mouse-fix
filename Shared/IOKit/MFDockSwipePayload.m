//
// --------------------------------------------------------------------------
// MFDockSwipePayload.m
// Created for Mac Mouse Fix (https://github.com/noah-nuebling/mac-mouse-fix)
// Licensed under the MMF License (https://github.com/noah-nuebling/mac-mouse-fix/blob/master/License)
// --------------------------------------------------------------------------
//

#import "MFDockSwipePayload.h"

static int MFDoubleSign(double value) {
    return (value > 0.0) - (value < 0.0);
}

MFDockSwipeState MFDockSwipeStateMake(void) {
    return (MFDockSwipeState){ 0 };
}

MFDockSwipePayload MFDockSwipePayloadAdvance(MFDockSwipeState *state,
                                             double delta,
                                             MFDockSwipePhase phase,
                                             BOOL invertedFromDevice) {
    NSCParameterAssert(state != NULL);

    MFDockSwipePayload payload = {
        .shouldPost = YES,
        .phase = phase,
    };

    if (phase == kMFDockSwipePhaseBegan) {
        state->originOffset = delta;
    } else if (phase == kMFDockSwipePhaseChanged) {
        if (delta == 0.0) {
            payload.shouldPost = NO;
            return payload;
        }
        state->originOffset += delta;
    }

    payload.includesExitVelocity = phase == kMFDockSwipePhaseEnded || phase == kMFDockSwipePhaseCancelled;
    if (payload.includesExitVelocity) {
        payload.legacyExitVelocity = state->lastDelta * 100.0;
    }

    if (phase == kMFDockSwipePhaseEnded &&
        MFDoubleSign(state->lastDelta) != MFDoubleSign(state->originOffset)) {
        payload.phase = kMFDockSwipePhaseCancelled;
    }

    payload.legacyProgress = state->originOffset;
    payload.modernProgress = invertedFromDevice ? -payload.legacyProgress : payload.legacyProgress;
    payload.modernExitVelocity = invertedFromDevice ? -payload.legacyExitVelocity : payload.legacyExitVelocity;

    state->lastDelta = delta;
    return payload;
}
