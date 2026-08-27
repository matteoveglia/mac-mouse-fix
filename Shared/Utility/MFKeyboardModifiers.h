#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <Carbon/Carbon.h>

NS_ASSUME_NONNULL_BEGIN

NS_INLINE CGEventFlags MFKeyboardModifierFlagForKeyCode(CGKeyCode keyCode) {
    switch (keyCode) {
        case kVK_Control:
        case kVK_RightControl:
            return kCGEventFlagMaskControl;
        case kVK_Option:
        case kVK_RightOption:
            return kCGEventFlagMaskAlternate;
        case kVK_Shift:
        case kVK_RightShift:
            return kCGEventFlagMaskShift;
        case kVK_Command:
        case kVK_RightCommand:
            return kCGEventFlagMaskCommand;
        case kVK_Function:
            return kCGEventFlagMaskSecondaryFn;
        default:
            return 0;
    }
}

NS_INLINE CGEventFlags MFKeyboardSupportedModifierFlags(void) {
    return kCGEventFlagMaskControl
        | kCGEventFlagMaskAlternate
        | kCGEventFlagMaskShift
        | kCGEventFlagMaskCommand
        | kCGEventFlagMaskSecondaryFn;
}

NS_ASSUME_NONNULL_END
