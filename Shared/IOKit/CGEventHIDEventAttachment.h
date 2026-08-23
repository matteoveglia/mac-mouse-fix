//
// --------------------------------------------------------------------------
// CGEventHIDEventAttachment.h
// Created for Mac Mouse Fix (https://github.com/noah-nuebling/mac-mouse-fix)
// Licensed under the MMF License (https://github.com/noah-nuebling/mac-mouse-fix/blob/master/License)
// --------------------------------------------------------------------------
//

#import <Foundation/Foundation.h>

typedef BOOL (*MFCGEventHIDEventSetter)(void * _Nullable context,
                                       const void * _Nullable cgEvent,
                                       const void * _Nullable hidEvent);

typedef struct {
    void * _Nullable context;
    MFCGEventHIDEventSetter _Nullable modernSetter;
    MFCGEventHIDEventSetter _Nullable legacySetter;
} MFCGEventHIDEventAttachmentBackend;

/// Routes attachment to exactly one backend. Modern systems fail closed when their setter is unavailable.
FOUNDATION_EXPORT BOOL MFCGEventAttachHIDEvent(const void * _Nullable cgEvent,
                                              const void * _Nullable hidEvent,
                                              BOOL requiresModernSetter,
                                              MFCGEventHIDEventAttachmentBackend backend);
