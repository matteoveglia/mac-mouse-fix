//
// --------------------------------------------------------------------------
// HelperUtility.h
// Created for Mac Mouse Fix (https://github.com/noah-nuebling/mac-mouse-fix)
// Created by Noah Nuebling in 2019
// Licensed under the MMF License (https://github.com/noah-nuebling/mac-mouse-fix/blob/master/License)
// --------------------------------------------------------------------------
//

#import <Foundation/Foundation.h>
@import AppKit;
@import CoreVideo;

NS_ASSUME_NONNULL_BEGIN

/// Window metadata already attached by WindowServer to an input event.  This
/// is deliberately a small, side-effect-free helper so the event-tap callback
/// can read the window number without calling AppKit.
NS_INLINE CGWindowID MFWindowNumberUnderMousePointerFromFields(CGWindowID windowUnderPointer,
                                                               CGWindowID handlerWindow) {
    return handlerWindow != kCGNullWindowID ? handlerWindow : windowUnderPointer;
}

NS_INLINE CGWindowID MFWindowNumberUnderMousePointerFromEvent(CGEventRef _Nullable event) {
    if (event == NULL) return kCGNullWindowID;

    return MFWindowNumberUnderMousePointerFromFields(
        (CGWindowID)CGEventGetIntegerValueField(event, kCGMouseEventWindowUnderMousePointer),
        (CGWindowID)CGEventGetIntegerValueField(event, kCGMouseEventWindowUnderMousePointerThatCanHandleThisEvent));
}

/// Find the owner PID for an exact window entry.  Window-list APIs can return
/// surrounding windows as well as the requested one, so callers must match
/// the window number rather than relying on array position.
NS_INLINE pid_t MFProcessIdentifierForWindowNumberFromWindowInfo(NSArray * _Nullable windowInfo,
                                                                 CGWindowID windowNumber) {
    if (windowInfo == nil || windowNumber == kCGNullWindowID) return -1;

    for (id object in windowInfo) {
        if (![object isKindOfClass:NSDictionary.class]) continue;
        NSDictionary *entry = object;
        NSNumber *candidateNumber = entry[(__bridge NSString *)kCGWindowNumber];
        if (![candidateNumber isKindOfClass:NSNumber.class]
            || candidateNumber.unsignedIntValue != windowNumber) {
            continue;
        }

        NSNumber *ownerPID = entry[(__bridge NSString *)kCGWindowOwnerPID];
        if (![ownerPID isKindOfClass:NSNumber.class]) return -1;
        pid_t pid = ownerPID.intValue;
        return pid > 0 ? pid : -1;
    }

    return -1;
}

@interface HelperUtility : NSObject

/// Display under pointer
+ (CVReturn)displayUnderMousePointer:(CGDirectDisplayID *)dspID withEvent:(CGEventRef _Nullable)event;
+ (CVReturn)display:(CGDirectDisplayID *)dspID atPoint:(CGPoint)point;

/// App under pointer
+ (NSRunningApplication * _Nullable)appUnderMousePointerWithEvent:(CGEventRef _Nullable)event;
+ (NSRunningApplication * _Nullable)appForWindowNumber:(CGWindowID)windowNumber;

/// Open main app
+ (void)openMainApp;

/// Display data
//+ (CGEventRef)createEventWithValuesFromEvent:(CGEventRef)event;
+ (void)printEventFieldDifferencesBetween:(CGEventRef)event1 and:(CGEventRef)event2;

/// Get current modifier flags
CGEventFlags getModifierFlags(void);
CGEventFlags getModifierFlagsWithEvent(CGEventRef flagEvent);

/// Get current pointer location
CGPoint getPointerLocation(void);
CGPoint getPointerLocationWithEvent(CGEventRef _Nullable locEvent);
NSPoint getFlippedPointerLocation(void);
NSPoint getFlippedPointerLocationWithEvent(CGEventRef _Nullable locEvent);

@end

NS_ASSUME_NONNULL_END
