#import <Foundation/Foundation.h>
#import "MFKeyboardShortcutEventPlan.h"

static void MFCheck(BOOL condition, NSString *message, int *failures) {
    if (!condition) {
        NSLog(@"FAIL: %@", message);
        (*failures)++;
    }
}

static BOOL MFStepEquals(MFKeyboardShortcutEventStep step,
                         CGKeyCode keyCode,
                         BOOL keyDown,
                         CGEventFlags flags) {
    return step.keyCode == keyCode && step.keyDown == keyDown && step.flags == flags;
}

int main(void) {
    @autoreleasepool {
        int failures = 0;

        MFKeyboardShortcutEventPlan commandTab = MFKeyboardShortcutEventPlanMake(
            kVK_Tab, kCGEventFlagMaskCommand);
        MFCheck(commandTab.count == 4, @"Command-Tab has four key transitions", &failures);
        MFCheck(MFStepEquals(commandTab.steps[0], kVK_Command, YES, kCGEventFlagMaskCommand),
                @"Command is pressed first", &failures);
        MFCheck(MFStepEquals(commandTab.steps[1], kVK_Tab, YES, kCGEventFlagMaskCommand),
                @"Tab is pressed with Command", &failures);
        MFCheck(MFStepEquals(commandTab.steps[2], kVK_Tab, NO, kCGEventFlagMaskCommand),
                @"Tab is released before Command", &failures);
        MFCheck(MFStepEquals(commandTab.steps[3], kVK_Command, NO, 0),
                @"Command receives an explicit key-up", &failures);
        MFCheck(commandTab.finalFlags == 0, @"Command-Tab leaves no modifier active", &failures);

        CGEventFlags multiFlags = kCGEventFlagMaskControl | kCGEventFlagMaskShift | kCGEventFlagMaskCommand;
        MFKeyboardShortcutEventPlan multi = MFKeyboardShortcutEventPlanMake(kVK_ANSI_A, multiFlags);
        MFCheck(multi.count == 8, @"three modifiers create six transitions around the key tap", &failures);
        MFCheck(MFStepEquals(multi.steps[0], kVK_Control, YES, kCGEventFlagMaskControl),
                @"Control is pressed first", &failures);
        MFCheck(MFStepEquals(multi.steps[1], kVK_Shift, YES,
                             kCGEventFlagMaskControl | kCGEventFlagMaskShift),
                @"Shift adds to the active flags", &failures);
        MFCheck(MFStepEquals(multi.steps[2], kVK_Command, YES, multiFlags),
                @"Command completes the modifier chord", &failures);
        MFCheck(MFStepEquals(multi.steps[5], kVK_Command, NO,
                             kCGEventFlagMaskControl | kCGEventFlagMaskShift),
                @"modifiers release in reverse order", &failures);
        MFCheck(MFStepEquals(multi.steps[7], kVK_Control, NO, 0),
                @"the final modifier is released", &failures);

        MFKeyboardShortcutEventPlan plain = MFKeyboardShortcutEventPlanMake(
            kVK_Space, kCGEventFlagMaskNumericPad);
        MFCheck(plain.count == 2, @"an unmodified shortcut only taps its key", &failures);
        MFCheck(plain.steps[0].flags == kCGEventFlagMaskNumericPad,
                @"non-key-state flags remain on the shortcut", &failures);
        MFCheck(plain.finalFlags == kCGEventFlagMaskNumericPad,
                @"non-key-state flags survive the release plan", &failures);

        if (failures == 0) NSLog(@"MFKeyboardShortcutEventPlanTests passed");
        return failures == 0 ? 0 : 1;
    }
}
