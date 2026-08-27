//
// --------------------------------------------------------------------------
// KeyCaptureMode.m
// Created for Mac Mouse Fix (https://github.com/noah-nuebling/mac-mouse-fix)
// Created by Noah Nuebling in 2022
// Licensed under the MMF License (https://github.com/noah-nuebling/mac-mouse-fix/blob/master/License)
// --------------------------------------------------------------------------
//

#import "KeyCaptureMode.h"
#import <Cocoa/Cocoa.h>
#import "ModificationUtility.h"
#import "MFEventTapHandle.h"
#import "MFMessagePort.h"
#import "MFModifierCaptureState.h"
#import "Logging.h"

@implementation KeyCaptureMode


/// Explanation for this class:
///  When the user records keyboard shortcuts in the mainApp we wanted to use eventTaps for that. I think otherwise certain keys weren't captured. Not sure though. The helper already has permissions to use eventTaps so the mainApp delegates the capturing to the helper.


static MFEventTapHandle *_keyCaptureEventTapHandle;
static BOOL _keyCaptureModeEnabled;
static MFModifierCaptureState _modifierCaptureState;

static BOOL setKeyCaptureEventTapEnabled(BOOL enabled, const char *reason) {
    NSString *logReason = reason ? [NSString stringWithUTF8String:reason] : @"unknown";
    return [_keyCaptureEventTapHandle setEnabled:enabled reason:logReason];
}

+ (void)enable {
    
    DDLogInfo("Enabling keyCaptureMode");
    
    if (_keyCaptureEventTapHandle == nil) {
        CGEventMask mask = CGEventMaskBit(kCGEventKeyDown)
            | CGEventMaskBit(kCGEventFlagsChanged)
            | CGEventMaskBit(NSEventTypeSystemDefined);
        _keyCaptureEventTapHandle = [MFEventTapHandle handleWithLocation:kCGHIDEventTap mask:mask options:kCGEventTapOptionDefault placement:kCGHeadInsertEventTap callback:keyCaptureModeCallback runLoop:CFRunLoopGetMain() mode:kCFRunLoopCommonModes label:@"KeyCaptureMode"];
    }
    if (_keyCaptureEventTapHandle == nil) {
        DDLogError("KeyCaptureMode: can't enable key capture because its event tap was not created.");
        _keyCaptureModeEnabled = NO;
        return;
    }

    _keyCaptureModeEnabled = YES;
    MFModifierCaptureStateReset(&_modifierCaptureState);
    if (!setKeyCaptureEventTapEnabled(YES, "enable")) {
        _keyCaptureModeEnabled = NO;
    }
}

+ (void)disable {
    _keyCaptureModeEnabled = NO;
    MFModifierCaptureStateReset(&_modifierCaptureState);
    setKeyCaptureEventTapEnabled(NO, "disable");
}

+ (void)shutdown {
    _keyCaptureModeEnabled = NO;
    MFModifierCaptureStateReset(&_modifierCaptureState);
    [_keyCaptureEventTapHandle invalidate];
    _keyCaptureEventTapHandle = nil;
}

CGEventRef  _Nullable keyCaptureModeCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *userInfo) {

    if (type == kCGEventTapDisabledByTimeout || type == kCGEventTapDisabledByUserInput) {
        DDLogWarn("KeyCaptureMode event tap disabled by %@.", type == kCGEventTapDisabledByTimeout ? @"timeout" : @"user input");
        if (type == kCGEventTapDisabledByTimeout && _keyCaptureModeEnabled && _keyCaptureEventTapHandle.valid) {
            if (!setKeyCaptureEventTapEnabled(YES, "eventTapDisabledByTimeout")) {
                _keyCaptureModeEnabled = NO;
            }
        }
        return event;
    }
    
    CGEventFlags flags  = CGEventGetFlags(event);
    
    NSDictionary *payload;
    
    if (type == kCGEventFlagsChanged) {

        CGKeyCode keyCode = (CGKeyCode)CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode);
        CGKeyCode capturedKeyCode = 0;
        MFModifierCaptureOutcome outcome = MFModifierCaptureStateHandleFlagsChanged(
            &_modifierCaptureState, keyCode, flags, &capturedKeyCode);
        if (outcome == kMFModifierCaptureOutcomeCaptured) {
            payload = @{
                @"keyCode": @(capturedKeyCode),
                @"flags": @(0),
            };
            [MFMessagePort sendMessage:@"keyCaptureModeFeedback" withPayload:payload waitForReply:NO];
            [KeyCaptureMode disable];
        }

        /// Keep modifier events observable by the main app's local monitor and
        /// preserve the physical down/up pair in the system event stream.
        return event;

    } else if (type == kCGEventKeyDown) {
        
        CGKeyCode keyCode = CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode);
        
        if (keyCaptureModePayloadIsValidWithKeyCode(keyCode, flags)) {
            
            payload = @{
                @"keyCode": @(keyCode),
                @"flags": @(flags),
            };
            
            [MFMessagePort sendMessage:@"keyCaptureModeFeedback" withPayload:payload waitForReply:NO];
            [KeyCaptureMode disable];
        }
        
    } else if (type == NSEventTypeSystemDefined) {
        
        NSEvent *e = [NSEvent eventWithCGEvent:event];
        
        MFSystemDefinedEventType type = (MFSystemDefinedEventType)(e.data1 >> 16);
        
        if (keyCaptureModePayloadIsValidWithEvent(e, flags, type)) {
            
            DDLogDebug("Capturing system event with data1: %ld, data2: %ld", e.data1, e.data2);
            
            payload = @{
                @"systemEventType": @(type),
                @"flags": @(flags),
            };
            
            [MFMessagePort sendMessage:@"keyCaptureModeFeedbackWithSystemEvent" withPayload:payload waitForReply:NO];
            [KeyCaptureMode disable];
        }
        
    }
    
    
    return nil;
}
bool keyCaptureModePayloadIsValidWithKeyCode(CGKeyCode keyCode, CGEventFlags flags) {
    return true; /// keyCode 0 is 'A'
}

bool keyCaptureModePayloadIsValidWithEvent(NSEvent *e, CGEventFlags flags, MFSystemDefinedEventType type) {
    
    BOOL isSub8 = (e.subtype == 8); /// 8 -> NSEventSubtypeScreenChanged
    BOOL isKeyDown = (e.data1 & kMFSystemDefinedEventPressedMask) == 0;
    BOOL secondDataIsNil = e.data2 == -1; /// The power key up event has both data fields be 0
    BOOL typeIsBlackListed = type == kMFSystemEventTypeCapsLock;
    
    BOOL isValid = isSub8 && isKeyDown && secondDataIsNil && !typeIsBlackListed;
    
    if (!isValid) {
        DDLogDebug("KeyCaptureMode received systemDefinedEvent but it is not valid – isSubtype8: %d, isKeyDown: %d, secondDataIsNil: %d, typeIsBlackListed: %d – event: %@, flags: %llu, type: %d", isSub8, isKeyDown, secondDataIsNil, typeIsBlackListed, e, flags, type);
    }
    
    return isValid;
}

@end
