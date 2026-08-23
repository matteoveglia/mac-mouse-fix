#import <Foundation/Foundation.h>
#import <math.h>
#import "MFDockSwipePayload.h"

static void MFCheck(BOOL condition, NSString *message, int *failures) {
    if (!condition) {
        NSLog(@"FAIL: %@", message);
        (*failures)++;
    }
}

static BOOL MFNear(double lhs, double rhs) {
    return fabs(lhs - rhs) < 0.000001;
}

int main(void) {
    @autoreleasepool {
        int failures = 0;

        MFDockSwipeState state = MFDockSwipeStateMake();
        MFDockSwipePayload began = MFDockSwipePayloadAdvance(&state, 0.2, kMFDockSwipePhaseBegan, NO);
        MFCheck(began.shouldPost, @"began posts", &failures);
        MFCheck(MFNear(began.legacyProgress, 0.2), @"began establishes progress", &failures);
        MFCheck(!began.includesExitVelocity, @"began has no exit velocity", &failures);

        MFDockSwipePayload changed = MFDockSwipePayloadAdvance(&state, 0.3, kMFDockSwipePhaseChanged, NO);
        MFCheck(MFNear(changed.legacyProgress, 0.5), @"changed accumulates progress", &failures);

        MFDockSwipePayload ended = MFDockSwipePayloadAdvance(&state, 0.0, kMFDockSwipePhaseEnded, NO);
        MFCheck(ended.phase == kMFDockSwipePhaseEnded, @"same-direction release ends", &failures);
        MFCheck(ended.includesExitVelocity, @"ended includes one velocity payload", &failures);
        MFCheck(MFNear(ended.legacyExitVelocity, 30.0), @"release velocity uses previous delta", &failures);

        state = MFDockSwipeStateMake();
        (void)MFDockSwipePayloadAdvance(&state, -0.25, kMFDockSwipePhaseBegan, YES);
        MFDockSwipePayload invertedChanged = MFDockSwipePayloadAdvance(&state, -0.1, kMFDockSwipePhaseChanged, YES);
        MFDockSwipePayload invertedEnded = MFDockSwipePayloadAdvance(&state, 0.0, kMFDockSwipePhaseEnded, YES);
        MFCheck(MFNear(invertedChanged.legacyProgress, -0.35), @"legacy progress remains device-flipped", &failures);
        MFCheck(MFNear(invertedChanged.modernProgress, 0.35), @"modern progress is unflipped", &failures);
        MFCheck(MFNear(invertedEnded.legacyExitVelocity, -10.0), @"legacy velocity preserves sign", &failures);
        MFCheck(MFNear(invertedEnded.modernExitVelocity, 10.0), @"modern velocity is unflipped with progress", &failures);

        state = MFDockSwipeStateMake();
        (void)MFDockSwipePayloadAdvance(&state, 0.5, kMFDockSwipePhaseBegan, NO);
        (void)MFDockSwipePayloadAdvance(&state, -0.1, kMFDockSwipePhaseChanged, NO);
        MFDockSwipePayload reversed = MFDockSwipePayloadAdvance(&state, 0.0, kMFDockSwipePhaseEnded, NO);
        MFCheck(reversed.phase == kMFDockSwipePhaseCancelled, @"release moving against progress cancels", &failures);
        MFCheck(MFNear(reversed.legacyExitVelocity, -10.0), @"cancelled release keeps signed velocity", &failures);

        state = MFDockSwipeStateMake();
        (void)MFDockSwipePayloadAdvance(&state, 0.4, kMFDockSwipePhaseBegan, NO);
        MFDockSwipeState beforeZero = state;
        MFDockSwipePayload zero = MFDockSwipePayloadAdvance(&state, 0.0, kMFDockSwipePhaseChanged, NO);
        MFCheck(!zero.shouldPost, @"zero changed event is suppressed", &failures);
        MFCheck(MFNear(state.originOffset, beforeZero.originOffset) && MFNear(state.lastDelta, beforeZero.lastDelta),
                @"suppressed event does not mutate state", &failures);

        MFDockSwipePayload cancelled = MFDockSwipePayloadAdvance(&state, 0.0, kMFDockSwipePhaseCancelled, NO);
        MFCheck(cancelled.phase == kMFDockSwipePhaseCancelled, @"explicit cancellation is preserved", &failures);
        MFCheck(cancelled.includesExitVelocity, @"cancelled includes one velocity payload", &failures);

        if (failures == 0) NSLog(@"MFDockSwipePayloadTests passed");
        return failures == 0 ? 0 : 1;
    }
}
