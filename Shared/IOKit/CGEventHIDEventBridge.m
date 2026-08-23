//
// --------------------------------------------------------------------------
// CGEventHIDEventBridge.m
// Created for Mac Mouse Fix (https://github.com/noah-nuebling/mac-mouse-fix)
// Created by Noah Nuebling in 2022
// Licensed under the MMF License (https://github.com/noah-nuebling/mac-mouse-fix/blob/master/License)
// --------------------------------------------------------------------------
//

#import "CGEventHIDEventBridge.h"
@import CoreGraphics.CGEvent;
#import <dispatch/dispatch.h>
#import "Logging.h"
#import "PrivateFunctions.h"
#import "CGEventHIDEventAttachment.h"

@implementation CGEventHIDEventBridge

static BOOL MFCGEventSetIOHIDEvent(CGEventRef cgEvent, IOHIDEventRef iohidEvent);
static void applyOffset(void **ptr, uint8_t byteOffset);

/// MARK: CGEvent -> HIDEvent

/// Convenience wrapper
HIDEvent *CGEventGetHIDEvent(CGEventRef cgEvent) {

    if (!cgEvent) {
        assert(false);
        return nil;
    }
    
    return (HIDEvent *)CFBridgingRelease(CGEventCopyIOHIDEvent(cgEvent));
}

/// External CGEvent -> HIDEvent function
extern IOHIDEventRef CGEventCopyIOHIDEvent(CGEventRef); /// Doesnt seem to work for mouseDragged events. -> Investigate!

/// MARK: HIDEvent -> CGEvent

/// Convenience wrapper
BOOL CGEventSetHIDEvent(CGEventRef cgEvent, HIDEvent *hidEvent) {
    return MFCGEventSetIOHIDEvent(cgEvent, (__bridge IOHIDEventRef)hidEvent);
}

typedef void (*SLEventSetIOHIDEventFunction)(CGEventRef, IOHIDEventRef);
static SLEventSetIOHIDEventFunction _slEventSetIOHIDEvent = NULL;

static BOOL MFSetHIDEventWithSkyLight(void *context, const void *cgEvent, const void *hidEvent) {
    if (!_slEventSetIOHIDEvent) return NO;
    _slEventSetIOHIDEvent((CGEventRef)cgEvent, (IOHIDEventRef)hidEvent);
    return YES;
}

static BOOL MFSetHIDEventWithLegacyOffsets(void *context, const void *cgEvent, const void *hidEvent) {
    CFRetain((CFTypeRef)hidEvent);

    void *resultHIDPtr = (void *)cgEvent;
    applyOffset(&resultHIDPtr, 0x18);
    resultHIDPtr = *(void **)resultHIDPtr;
    applyOffset(&resultHIDPtr, 0xd0);
    *(IOHIDEventRef *)resultHIDPtr = (IOHIDEventRef)hidEvent;
    return YES;
}

/// Attaches an IOHIDEvent to a CGEvent.
///     The legacy implementation writes through hard-coded CGEvent struct offsets. Those offsets changed on macOS 27,
///     so use SkyLight's setter there and keep the old implementation only for earlier macOS versions.
static BOOL MFCGEventSetIOHIDEvent(CGEventRef cgEvent, IOHIDEventRef iohidEvent) {
    
    /// Validate
    if (!cgEvent) {
        assert(false);
        return NO;
    }
    if (!iohidEvent) {
        assert(false);
        return NO;
    }

    /// Use SkyLight's setter on macOS 27.
    ///     The private setter copies the payload; retaining it here would leak one HID event for every simulated gesture.
    ///     If Apple removes or renames the symbol, failing closed is safer than writing through offsets known to be invalid.
    if (@available(macOS 27.0, *)) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            _slEventSetIOHIDEvent = (SLEventSetIOHIDEventFunction)MFLoadSymbol_native(kMFFrameworkSkyLight, @"SLEventSetIOHIDEvent");
        });

        MFCGEventHIDEventAttachmentBackend backend = {
            .modernSetter = _slEventSetIOHIDEvent ? MFSetHIDEventWithSkyLight : NULL,
            .legacySetter = MFSetHIDEventWithLegacyOffsets,
        };
        BOOL attached = MFCGEventAttachHIDEvent(cgEvent, iohidEvent, YES, backend);
        if (!attached) {
            DDLogError("CGEventSetIOHIDEvent: couldn't resolve SLEventSetIOHIDEvent on macOS 27; skipping the incompatible offset writer.");
        }
        return attached;
    }

    MFCGEventHIDEventAttachmentBackend backend = {
        .legacySetter = MFSetHIDEventWithLegacyOffsets,
    };
    return MFCGEventAttachHIDEvent(cgEvent, iohidEvent, NO, backend);
}

/// MARK: Helper

/// applyOffset()
/// Used to emulate the immediate offset we see in the LDR instruction (ARM assembly)
///
/// Takes a (pointer to a) pointer `ptr` as well as an offset `byteOffset`.
/// Shifts (the pointer pointed to by) `ptr` by an offset of `byteOffset` bytes before returning.
///
/// The "immediate offset" in the LDR instruction is also an offset in bytes. That's why this is helpful for recreating assembly code involving the LDR instruction.
///
/// LDR only supports positive offsets between 0 and 31*4 = 124. That's why we chose uint8_t for the `byteOffset`. We could make it bigger though.
///
/// See:  https://developer.arm.com/documentation/dui0068/b/Thumb-Instruction-Reference/Thumb-memory-access-instructions/LDR-and-STR--immediate-offset

static void applyOffset(void **ptr, uint8_t byteOffset) {
    *ptr = ((uint8_t *)*ptr) + byteOffset;
}

/// MARK: Old

CGEventRef MFCGEventCreateWithIOHIDEvent_Original(HIDEvent *hidEvent) {
    
    CGEventRef result = CGEventCreate(NULL);
    uint8_t *bytePtr = (uint8_t *)result;
    uint8_t *bytePtr2 = (uint8_t *)*((uint64_t *)(bytePtr + 0x18));
    uint8_t *bytePtr3 = (bytePtr2 + 0xd0);
    uint64_t *resultHIDPtr = (uint64_t *)bytePtr3;
    *resultHIDPtr = (uint64_t)hidEvent;
    
    return result;
}

@end
