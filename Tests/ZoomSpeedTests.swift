//
// Deterministic contract checks for the independent zoom-speed setting.
// This file is compiled directly by the remediation test workflow.
//

import Foundation

private func check(_ condition: @autoclosure () -> Bool, _ message: String, _ failures: inout Int) {
    if !condition() {
        NSLog("FAIL: %@", message)
        failures += 1
    }
}

@main
private enum ZoomSpeedTestMain {
    static func main() {
        var failures = 0

        check(ZoomSpeed.clampedPercentage(ZoomSpeed.defaultPercentage) == 100,
              "the default zoom speed is 100 percent", &failures)
        check(ZoomSpeed.clampedPercentage(0) == ZoomSpeed.minimumPercentage,
              "values below the supported range are clamped", &failures)
        check(ZoomSpeed.clampedPercentage(999) == ZoomSpeed.maximumPercentage,
              "values above the supported range are clamped", &failures)
        check(ZoomSpeed.multiplier(for: 50) == 0.5,
              "the minimum percentage maps to a half-speed multiplier", &failures)
        check(ZoomSpeed.multiplier(for: 150) == 1.5,
              "the multiplier preserves the persisted percentage", &failures)
        check(ZoomSpeed.snappedPercentage(for: 104.9) == 100,
              "slider values snap to the nearest ten percent", &failures)
        check(ZoomSpeed.snappedPercentage(for: 105.1) == 110,
              "slider values round upward at the midpoint", &failures)
        check(ZoomSpeed.snappedPercentage(for: 1000) == ZoomSpeed.maximumPercentage,
              "snapped slider values remain bounded", &failures)
        check(ZoomSpeed.snappedPercentage(for: .nan) == ZoomSpeed.defaultPercentage,
              "non-finite slider values fall back to the default", &failures)

        let defaultConfigURL = URL(fileURLWithPath: "Shared/Config/default_config.plist")
        guard let defaultConfig = NSDictionary(contentsOf: defaultConfigURL),
              let scroll = defaultConfig["Scroll"] as? NSDictionary,
              let constants = defaultConfig["Constants"] as? NSDictionary else {
            NSLog("FAIL: default config is readable")
            exit(EXIT_FAILURE)
        }
        check((scroll["zoomSpeed"] as? NSNumber)?.intValue == ZoomSpeed.defaultPercentage,
              "default config declares the default zoom speed", &failures)
        check((constants["configVersion"] as? NSNumber)?.intValue == 30,
              "default config includes the zoom-speed migration", &failures)

        if failures == 0 {
            NSLog("ZoomSpeedTests passed")
        }
        exit(failures == 0 ? EXIT_SUCCESS : EXIT_FAILURE)
    }
}
