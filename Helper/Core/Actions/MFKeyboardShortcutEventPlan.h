#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <Carbon/Carbon.h>
#import "../../../Shared/Utility/MFKeyboardModifiers.h"

NS_ASSUME_NONNULL_BEGIN

typedef struct {
    CGKeyCode keyCode;
    BOOL keyDown;
    CGEventFlags flags;
} MFKeyboardShortcutEventStep;

typedef struct {
    MFKeyboardShortcutEventStep steps[12];
    NSUInteger count;
    CGEventFlags finalFlags;
} MFKeyboardShortcutEventPlan;

typedef struct {
    CGKeyCode keyCode;
    CGEventFlags flag;
} MFKeyboardShortcutModifier;

/// Build a complete shortcut tap: press each modifier, tap the primary key,
/// then release modifiers in reverse order. Non-key-state flags such as
/// NumericPad are retained but do not produce synthetic modifier events.
NS_INLINE MFKeyboardShortcutEventPlan MFKeyboardShortcutEventPlanMake(CGKeyCode keyCode,
                                                                      CGEventFlags flags) {
    const MFKeyboardShortcutModifier modifiers[] = {
        { kVK_Control,  kCGEventFlagMaskControl },
        { kVK_Option,   kCGEventFlagMaskAlternate },
        { kVK_Shift,    kCGEventFlagMaskShift },
        { kVK_Command,  kCGEventFlagMaskCommand },
        { kVK_Function, kCGEventFlagMaskSecondaryFn },
    };
    const NSUInteger modifierCount = sizeof(modifiers) / sizeof(modifiers[0]);

    CGEventFlags syntheticModifierMask = 0;
    for (NSUInteger index = 0; index < modifierCount; index++) {
        syntheticModifierMask |= modifiers[index].flag;
    }

    MFKeyboardShortcutEventPlan plan = {0};
    CGEventFlags currentFlags = flags & ~syntheticModifierMask;
    CGEventFlags primaryModifierFlag = MFKeyboardModifierFlagForKeyCode(keyCode);

    for (NSUInteger index = 0; index < modifierCount; index++) {
        MFKeyboardShortcutModifier modifier = modifiers[index];
        if ((flags & modifier.flag) == 0) continue;
        currentFlags |= modifier.flag;
        plan.steps[plan.count++] = (MFKeyboardShortcutEventStep){
            .keyCode = modifier.keyCode,
            .keyDown = YES,
            .flags = currentFlags,
        };
    }

    plan.steps[plan.count++] = (MFKeyboardShortcutEventStep){
        .keyCode = keyCode,
        .keyDown = YES,
        .flags = flags | primaryModifierFlag,
    };
    plan.steps[plan.count++] = (MFKeyboardShortcutEventStep){
        .keyCode = keyCode,
        .keyDown = NO,
        .flags = flags & ~primaryModifierFlag,
    };

    for (NSInteger index = (NSInteger)modifierCount - 1; index >= 0; index--) {
        MFKeyboardShortcutModifier modifier = modifiers[index];
        if ((flags & modifier.flag) == 0) continue;
        currentFlags &= ~modifier.flag;
        plan.steps[plan.count++] = (MFKeyboardShortcutEventStep){
            .keyCode = modifier.keyCode,
            .keyDown = NO,
            .flags = currentFlags,
        };
    }

    plan.finalFlags = currentFlags;
    return plan;
}

NS_ASSUME_NONNULL_END
