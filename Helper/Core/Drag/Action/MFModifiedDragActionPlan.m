#import "MFModifiedDragActionPlan.h"

bool MFModifiedDragActionPlanHandleEvent(MFModifiedDragActionPlan *plan, MFModifiedDragActionEvent event) {
    if (event != MFModifiedDragActionEventBecameInUse || plan->didExecute) return false;
    plan->didExecute = true;
    return true;
}
