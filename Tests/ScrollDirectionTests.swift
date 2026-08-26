//
// Deterministic contract checks for axis-specific reverse-direction settings.
// This file is compiled directly by the remediation test workflow.
//

import Foundation
import Darwin

private func check(_ condition: @autoclosure () -> Bool, _ message: String, _ failures: inout Int) {
    if !condition() {
        NSLog("FAIL: %@", message)
        failures += 1
    }
}

@main
private enum ScrollDirectionTestMain {
    static func main() {
        var failures = 0

        check(ScrollDirection.inversion(forAxis: 2, verticalReversed: false, horizontalReversed: false) == 1,
              "vertical direction remains unchanged when vertical reversal is off", &failures)
        check(ScrollDirection.inversion(forAxis: 2, verticalReversed: true, horizontalReversed: false) == -1,
              "vertical direction uses only the vertical reversal setting", &failures)
        check(ScrollDirection.inversion(forAxis: 1, verticalReversed: false, horizontalReversed: false) == 1,
              "horizontal direction remains unchanged when horizontal reversal is off", &failures)
        check(ScrollDirection.inversion(forAxis: 1, verticalReversed: false, horizontalReversed: true) == -1,
              "horizontal direction uses only the horizontal reversal setting", &failures)
        check(ScrollDirection.inversion(forAxis: 1, verticalReversed: true, horizontalReversed: false) == 1,
              "vertical reversal does not leak into horizontal direction", &failures)
        check(ScrollDirection.inversion(forAxis: 2, verticalReversed: false, horizontalReversed: true) == 1,
              "horizontal reversal does not leak into vertical direction", &failures)
        check(ScrollDirection.inversion(forAxis: 0, verticalReversed: true, horizontalReversed: true) == 1,
              "an unspecified axis is never reversed", &failures)

        let defaultConfigURL = URL(fileURLWithPath: "Shared/Config/default_config.plist")
        guard let defaultConfig = NSDictionary(contentsOf: defaultConfigURL),
              let scroll = defaultConfig["Scroll"] as? NSDictionary,
              let constants = defaultConfig["Constants"] as? NSDictionary else {
            NSLog("FAIL: default config is readable")
            exit(EXIT_FAILURE)
        }
        check((constants["configVersion"] as? NSNumber)?.intValue == 28,
              "default config uses the axis-direction migration version", &failures)
        check(scroll["reverseDirection"] == nil,
              "default config no longer declares the shared reverse-direction key", &failures)
        check(scroll["reverseDirectionVertical"] is NSNumber,
              "default config declares vertical reversal", &failures)
        check(scroll["reverseDirectionHorizontal"] is NSNumber,
              "default config declares horizontal reversal", &failures)

        if failures == 0 {
            NSLog("ScrollDirectionTests passed")
        }
        exit(failures == 0 ? EXIT_SUCCESS : EXIT_FAILURE)
    }
}
