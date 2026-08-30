import Foundation

@main
struct DragActivationThresholdTests {
    static func main() {
        var failures = 0
        func check(_ condition: @autoclosure () -> Bool, _ message: String) {
            if !condition() {
                NSLog("FAIL: %@", message)
                failures += 1
            }
        }

        check(DragActivationThreshold.sanitized(nil) == 7, "missing values use the legacy seven-point threshold")
        check(DragActivationThreshold.sanitized("bad") == 7, "malformed values use the default")
        check(DragActivationThreshold.sanitized(2) == 3, "values below the supported range are clamped")
        check(DragActivationThreshold.sanitized(18) == 18, "values inside the range are preserved")
        check(DragActivationThreshold.sanitized(99) == 40, "values above the supported range are clamped")

        let defaultConfigURL = URL(fileURLWithPath: "Shared/Config/default_config.plist")
        guard let defaultConfig = NSDictionary(contentsOf: defaultConfigURL),
              let general = defaultConfig["General"] as? NSDictionary,
              let constants = defaultConfig["Constants"] as? NSDictionary else {
            NSLog("FAIL: default config is readable")
            exit(EXIT_FAILURE)
        }
        check((general["dragActivationThreshold"] as? NSNumber)?.intValue == 7,
              "default config preserves the legacy threshold")
        check((constants["configVersion"] as? NSNumber)?.intValue == 30,
              "default config includes the zoom-speed migration")

        if failures == 0 { NSLog("DragActivationThresholdTests passed") }
        exit(failures == 0 ? EXIT_SUCCESS : EXIT_FAILURE)
    }
}
