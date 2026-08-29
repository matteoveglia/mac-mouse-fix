import Foundation

@main
struct InputCapturePolicyTests {
    static func main() {
        var failures = 0
        func check(_ condition: @autoclosure () -> Bool, _ message: String) {
            if !condition() {
                NSLog("FAIL: %@", message)
                failures += 1
            }
        }

        check(InputCapturePolicy.featureIsEnabled(killSwitch: false, addModeIsEnabled: false),
              "an enabled feature accepts normal input")
        check(!InputCapturePolicy.featureIsEnabled(killSwitch: true, addModeIsEnabled: false),
              "a menu-disabled feature rejects normal input")
        check(InputCapturePolicy.featureIsEnabled(killSwitch: true, addModeIsEnabled: true),
              "Add Mode temporarily accepts input without changing the saved kill switch")

        check(!InputCapturePolicy.captureIsAllowed(
            userIsActive: false, isLockedDown: false, killSwitch: false, addModeIsEnabled: true),
              "Add Mode does not bypass an inactive user session")
        check(!InputCapturePolicy.captureIsAllowed(
            userIsActive: true, isLockedDown: true, killSwitch: false, addModeIsEnabled: true),
              "Add Mode does not bypass helper lockdown")
        check(InputCapturePolicy.captureIsAllowed(
            userIsActive: true, isLockedDown: false, killSwitch: true, addModeIsEnabled: true),
              "Add Mode can capture while the corresponding feature remains menu-disabled")

        if failures == 0 { NSLog("InputCapturePolicyTests passed") }
        exit(failures == 0 ? EXIT_SUCCESS : EXIT_FAILURE)
    }
}
