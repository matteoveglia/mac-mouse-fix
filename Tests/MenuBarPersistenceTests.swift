import Foundation

@main
struct MenuBarPersistenceTests {
    static func main() {
        var failures = 0
        func check(_ condition: @autoclosure () -> Bool, _ message: String) {
            if !condition() {
                NSLog("FAIL: %@", message)
                failures += 1
            }
        }

        func source(_ path: String) -> String {
            (try? String(contentsOfFile: path, encoding: .utf8)) ?? ""
        }

        func functionBody(_ signature: String, in source: String) -> String? {
            guard let signatureRange = source.range(of: signature),
                  let openingBrace = source[signatureRange.upperBound...].firstIndex(of: "{") else { return nil }

            var depth = 0
            for index in source.indices[openingBrace...] {
                switch source[index] {
                case "{": depth += 1
                case "}":
                    depth -= 1
                    if depth == 0 { return String(source[openingBrace...index]) }
                default: break
                }
            }
            return nil
        }

        let menuBarSource = source("Helper/UI/MenuBarItem/MenuBarItem.swift")
        let buttonTabSource = source("App/UI/Main/Tabs/ButtonTab/ButtonTabController.swift")
        let scrollTabSource = source("App/UI/Main/Tabs/ScrollTabController.swift")

        let disableButtons = functionBody("func disableButtons", in: menuBarSource) ?? ""
        check(disableButtons.contains("setConfig(\"General.buttonKillSwitch\""),
              "the Buttons menu action stores its kill switch")
        check(disableButtons.contains("commitConfig()"),
              "the Buttons menu action persists its state")

        let disableScroll = functionBody("func disableScroll", in: menuBarSource) ?? ""
        check(disableScroll.contains("setConfig(\"General.scrollKillSwitch\""),
              "the Scrolling menu action stores its kill switch")
        check(disableScroll.contains("commitConfig()"),
              "the Scrolling menu action persists its state")

        let reload = functionBody("static func reload", in: menuBarSource) ?? ""
        check(!reload.contains("setConfig(\"General.buttonKillSwitch\""),
              "changing menu-bar visibility does not re-enable Buttons")
        check(!reload.contains("setConfig(\"General.scrollKillSwitch\""),
              "changing menu-bar visibility does not re-enable Scrolling")

        let buttonAppearance = functionBody("override func viewDidAppear", in: buttonTabSource) ?? ""
        check(!buttonAppearance.contains("setConfig(\"General.buttonKillSwitch\""),
              "opening Buttons settings does not re-enable Buttons")
        check(!buttonAppearance.contains("setConfig(\"General.scrollKillSwitch\""),
              "opening Buttons settings does not re-enable Scrolling")

        let scrollAppearance = functionBody("override func viewDidAppear", in: scrollTabSource) ?? ""
        check(!scrollAppearance.contains("setConfig(\"General.scrollKillSwitch\""),
              "opening Scrolling settings does not re-enable Scrolling")

        if failures == 0 { NSLog("MenuBarPersistenceTests passed") }
        exit(failures == 0 ? EXIT_SUCCESS : EXIT_FAILURE)
    }
}
