#pragma once

#include <stdbool.h>

typedef enum {
    MFModifiedDragActionEventBecameInUse,
    MFModifiedDragActionEventMouseInput,
    MFModifiedDragActionEventDeactivated,
} MFModifiedDragActionEvent;

typedef struct {
    bool didExecute;
} MFModifiedDragActionPlan;

bool MFModifiedDragActionPlanHandleEvent(
    MFModifiedDragActionPlan *plan,
    MFModifiedDragActionEvent event
);
