enum InputCapturePolicy {
    static func featureIsEnabled(killSwitch: Bool, addModeIsEnabled: Bool) -> Bool {
        !killSwitch || addModeIsEnabled
    }

    static func captureIsAllowed(
        userIsActive: Bool,
        isLockedDown: Bool,
        killSwitch: Bool,
        addModeIsEnabled: Bool
    ) -> Bool {
        userIsActive
            && !isLockedDown
            && featureIsEnabled(killSwitch: killSwitch, addModeIsEnabled: addModeIsEnabled)
    }
}
