#import <Foundation/Foundation.h>
#import "../../Shared/Utility/MFKeyboardModifiers.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, MFModifierCaptureOutcome) {
    kMFModifierCaptureOutcomeNone,
    kMFModifierCaptureOutcomeCaptured,
};

typedef struct {
    CGKeyCode candidateKeyCode;
    BOOL hasCandidate;
    BOOL blockedUntilAllModifiersAreReleased;
} MFModifierCaptureState;

NS_INLINE void MFModifierCaptureStateReset(MFModifierCaptureState *state) {
    if (state == NULL) return;
    *state = (MFModifierCaptureState){0};
}

/// Capture exactly one modifier on release. A second modifier invalidates the
/// candidate until the whole chord is released, while an ordinary key-down is
/// still handled immediately by the existing shortcut capture path.
NS_INLINE MFModifierCaptureOutcome MFModifierCaptureStateHandleFlagsChanged(
    MFModifierCaptureState *state,
    CGKeyCode keyCode,
    CGEventFlags flags,
    CGKeyCode * _Nullable capturedKeyCode
) {
    if (state == NULL) return kMFModifierCaptureOutcomeNone;

    CGEventFlags keyFlag = MFKeyboardModifierFlagForKeyCode(keyCode);
    CGEventFlags activeFlags = flags & MFKeyboardSupportedModifierFlags();
    if (keyFlag == 0) return kMFModifierCaptureOutcomeNone;

    if (state->blockedUntilAllModifiersAreReleased) {
        if (activeFlags == 0) MFModifierCaptureStateReset(state);
        return kMFModifierCaptureOutcomeNone;
    }

    BOOL keyIsDown = (activeFlags & keyFlag) != 0;
    if (!state->hasCandidate) {
        if (keyIsDown && activeFlags == keyFlag) {
            state->candidateKeyCode = keyCode;
            state->hasCandidate = YES;
        } else if (keyIsDown) {
            state->blockedUntilAllModifiersAreReleased = YES;
        }
        return kMFModifierCaptureOutcomeNone;
    }

    if (keyCode != state->candidateKeyCode) {
        state->hasCandidate = NO;
        state->blockedUntilAllModifiersAreReleased = activeFlags != 0;
        return kMFModifierCaptureOutcomeNone;
    }

    if (keyIsDown) return kMFModifierCaptureOutcomeNone;

    CGKeyCode completedKeyCode = state->candidateKeyCode;
    if (activeFlags == 0) {
        MFModifierCaptureStateReset(state);
        if (capturedKeyCode != NULL) *capturedKeyCode = completedKeyCode;
        return kMFModifierCaptureOutcomeCaptured;
    }

    state->hasCandidate = NO;
    state->blockedUntilAllModifiersAreReleased = YES;
    return kMFModifierCaptureOutcomeNone;
}

NS_ASSUME_NONNULL_END
