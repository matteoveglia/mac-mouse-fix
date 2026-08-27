#import <Foundation/Foundation.h>
#import "MFModifierCaptureState.h"

static void MFCheck(BOOL condition, NSString *message, int *failures) {
    if (!condition) {
        NSLog(@"FAIL: %@", message);
        (*failures)++;
    }
}

int main(void) {
    @autoreleasepool {
        int failures = 0;
        MFModifierCaptureState state = {0};
        CGKeyCode capturedKeyCode = 0;

        MFCheck(MFModifierCaptureStateHandleFlagsChanged(
                    &state, kVK_Control, kCGEventFlagMaskControl, &capturedKeyCode)
                    == kMFModifierCaptureOutcomeNone,
                @"modifier-down waits for release", &failures);
        MFCheck(MFModifierCaptureStateHandleFlagsChanged(
                    &state, kVK_Control, 0, &capturedKeyCode)
                    == kMFModifierCaptureOutcomeCaptured,
                @"a single modifier is captured on release", &failures);
        MFCheck(capturedKeyCode == kVK_Control, @"the captured side-specific key code is preserved", &failures);

        MFModifierCaptureStateReset(&state);
        capturedKeyCode = 0;
        MFModifierCaptureStateHandleFlagsChanged(
            &state, kVK_Control, kCGEventFlagMaskControl, &capturedKeyCode);
        MFModifierCaptureStateHandleFlagsChanged(
            &state, kVK_Shift, kCGEventFlagMaskControl | kCGEventFlagMaskShift, &capturedKeyCode);
        MFCheck(MFModifierCaptureStateHandleFlagsChanged(
                    &state, kVK_Shift, kCGEventFlagMaskControl, &capturedKeyCode)
                    == kMFModifierCaptureOutcomeNone,
                @"releasing part of a chord does not capture it", &failures);
        MFCheck(MFModifierCaptureStateHandleFlagsChanged(
                    &state, kVK_Control, 0, &capturedKeyCode)
                    == kMFModifierCaptureOutcomeNone,
                @"a multi-modifier chord stays rejected through final release", &failures);

        MFCheck(MFModifierCaptureStateHandleFlagsChanged(
                    &state, kVK_RightOption, kCGEventFlagMaskAlternate, &capturedKeyCode)
                    == kMFModifierCaptureOutcomeNone,
                @"capture rearms after all chord modifiers are released", &failures);
        MFCheck(MFModifierCaptureStateHandleFlagsChanged(
                    &state, kVK_RightOption, 0, &capturedKeyCode)
                    == kMFModifierCaptureOutcomeCaptured,
                @"a right-side modifier can be captured", &failures);
        MFCheck(capturedKeyCode == kVK_RightOption, @"right-side identity is retained", &failures);

        MFModifierCaptureStateReset(&state);
        MFCheck(MFModifierCaptureStateHandleFlagsChanged(
                    &state, kVK_CapsLock, kCGEventFlagMaskAlphaShift, &capturedKeyCode)
                    == kMFModifierCaptureOutcomeNone,
                @"Caps Lock is not treated as a one-shot modifier", &failures);

        if (failures == 0) NSLog(@"MFModifierCaptureStateTests passed");
        return failures == 0 ? 0 : 1;
    }
}
