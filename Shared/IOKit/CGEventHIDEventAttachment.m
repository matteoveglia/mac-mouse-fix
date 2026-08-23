//
// --------------------------------------------------------------------------
// CGEventHIDEventAttachment.m
// Created for Mac Mouse Fix (https://github.com/noah-nuebling/mac-mouse-fix)
// Licensed under the MMF License (https://github.com/noah-nuebling/mac-mouse-fix/blob/master/License)
// --------------------------------------------------------------------------
//

#import "CGEventHIDEventAttachment.h"

BOOL MFCGEventAttachHIDEvent(const void *cgEvent,
                            const void *hidEvent,
                            BOOL requiresModernSetter,
                            MFCGEventHIDEventAttachmentBackend backend) {
    if (!cgEvent || !hidEvent) return NO;

    MFCGEventHIDEventSetter setter = requiresModernSetter ? backend.modernSetter : backend.legacySetter;
    if (!setter) return NO;

    return setter(backend.context, cgEvent, hidEvent);
}
