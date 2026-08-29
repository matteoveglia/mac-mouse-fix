#import "ModifiedDragOutputAction.h"

#import "Actions.h"
#import "MFModifiedDragActionPlan.h"

@implementation ModifiedDragOutputAction

static ModifiedDragState *_drag;
static MFModifiedDragActionPlan _plan;

+ (BOOL)canHandleEffectDict:(NSDictionary *)effectDict {
    NSString *actionType = effectDict[kMFActionDictKeyType];
    if ([actionType isEqual:kMFActionDictTypeKeyboardShortcut]) {
        return [effectDict[kMFActionDictKeyKeyboardShortcutVariantKeycode] isKindOfClass:NSNumber.class]
            && [effectDict[kMFActionDictKeyKeyboardShortcutVariantModifierFlags] isKindOfClass:NSNumber.class];
    }
    if ([actionType isEqual:kMFActionDictTypeSystemDefinedEvent]) {
        return [effectDict[kMFActionDictKeySystemDefinedEventVariantType] isKindOfClass:NSNumber.class]
            && [effectDict[kMFActionDictKeySystemDefinedEventVariantModifierFlags] isKindOfClass:NSNumber.class];
    }
    return NO;
}

+ (void)initializeWithDragState:(ModifiedDragState *)dragStateRef {
    _drag = dragStateRef;
    _plan = (MFModifiedDragActionPlan){0};
}

+ (void)handleEvent:(MFModifiedDragActionEvent)event {
    if (!MFModifiedDragActionPlanHandleEvent(&_plan, event)) return;
    [Actions executeActionArray:@[_drag->effectDict]
                         phase:kMFActionPhaseCombined
                 mouseLocation:_drag->usageOrigin];
}

+ (void)handleBecameInUse {
    [self handleEvent:MFModifiedDragActionEventBecameInUse];
}

+ (void)handleMouseInputWhileInUseWithDeltaX:(double)deltaX
                                       deltaY:(double)deltaY
                                        event:(CGEventRef)event {
    [self handleEvent:MFModifiedDragActionEventMouseInput];
}

+ (void)handleDeactivationWhileInUseWithCancel:(BOOL)cancel {
    [self handleEvent:MFModifiedDragActionEventDeactivated];
}

+ (void)suspend {}
+ (void)unsuspend {}

@end
