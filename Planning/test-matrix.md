# Remediation Test Matrix

Updated: 2026-08-24 · Branches: `codex/remediation-p0`, `codex/remediation-p1`, `codex/remediation-lifecycle`, `codex/remediation-dock-payload`, `codex/remediation-scroll-reset`, `codex/remediation-login-items`, `codex/remediation-policy-editor`

This records current evidence for the compatibility remediation. A successful
build is not evidence that the input path works on physical hardware, so those
checks remain explicitly open.

| Area | Current result | Evidence / next check |
|---|---|---|
| Debug App and embedded Helper | Pass | Signed `xcodebuild -scheme App -configuration Debug -destination 'platform=macOS' build` with Xcode 27. |
| Regression harness | Pass | Unsigned `xcodebuild -scheme Tests -configuration Debug -destination 'platform=macOS' build CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO`. The target is a harness, not XCTest. |
| Static analysis | Pass with legacy findings | `xcodebuild -scheme App ... analyze` completed. Existing warnings are tracked separately; none came from the current cache, helper-service, key-capture, or pointer-freeze changes. |
| Helper enable | Pass | A native pointer click in the signed Debug app started the ServiceManagement job and helper process; Buttons and Scrolling became available. |
| Helper disable | Pass | In the signed Debug app, the General toggle disabled Buttons and Scrolling, removed the ServiceManagement job, and terminated the helper process. |
| Settings navigation | Pass | One-click navigation between tabs was verified in the signed Debug app. |
| Per-app policy core | Pass | Direct Swift suite verifies canonical decode/encode, v25 legacy semantics, selector precedence, stable-identity fallback rules, duplicate/invalid input rejection, and bounded rule count. The App/Helper Debug and Release builds compile the runtime integration. |
| Per-app policy authoring | Deterministic core pass; UI partial | The Scrolling tab exposes a spacious Advanced Application Rules sheet from the Apply To menu’s Advanced… action, with inline validation, dynamic selector examples, and a Choose App… action for exact paths/bundle IDs. The main row shows Edit Apps… only for the list-based scopes. Finder can be selected to fill `/System/Library/CoreServices/Finder.app/Contents/MacOS/Finder`; signed Java/wrapper/full-screen runtime behavior remains a manual gate. |
| Per-app runtime/UI | Partial pass | The signed P1 build passed All Apps, Only These Apps, and All Except These Apps runtime testing. Java/wrapper, full-screen, missing-app, app-switch-mid-series, and iPhone Mirroring cases remain explicit gates. |
| Click-cycle cancellation | Pass | Deterministic Swift reducer tests cover release, replacement cycle, stale hold/expiry callbacks, and idempotent teardown. |
| Button gesture semantics | Pass | The signed P1 build passed single/double click, hold, click-drag, and click-scroll remap testing. Automated coverage remains focused on timer cancellation; app-specific compatibility stays in the broader matrix. |
| HID++ protocol core | Pass (synthetic only) | Objective-C fixture suite verifies strict short/long parsing, one in-flight request, timeout, disconnect, idempotent stop, and rejection of late responses. The fixture transport has no IOKit or hardware-write path. |
| Logitech model support | Hardware blocked | No model is claimed supported yet. Capture M650/L, MX Master, Lift, and M720 reports over relevant Bolt/Unifying/Bluetooth transports before adding an IOKit adapter or reprogramming controls. Ordinary CGEvent button capture remains independent. |
| Device hot-unplug | Pass | The signed P1 build retained button remapping and helper operation across the requested unplug/reconnect check. Transport-specific Logitech HID++ reprogramming remains outside this result. |
| Event-tap ownership core | Pass | Fake-backend tests cover failed tap/source creation, inert creation, idempotent toggles, refused enable, late-enable rejection, stable teardown order, and exactly-once release. The signed lifecycle build also passed rapid disable/enable cycling, quit/reopen, shortcut capture, normal buttons/scrolling, and modified-drag teardown. |
| Pointer-freeze / two-finger drag | Pass | The signed lifecycle build completed modified-drag testing without leaving the real pointer frozen or hidden. Extended soak and interruption testing remains part of the broader lifecycle matrix. |
| Scroll and virtual/remote input | Pass for tested signed build | Fast scrolling and the scroll-reset interruption checks passed on the user’s signed build using a mouse remote to this machine. The branch deterministically rejects stale queued/animation generations and compiles in Debug and Release. Browser maps, iPhone Mirroring, other remote sources, and wider hardware combinations remain broader compatibility gates. Do not assess horizontal scaling: it is intentionally not part of this fork. |
| Dock swipes | Pass on local signed build | Reducer and bridge suites pass. The signed Xcode 27 build passed Spaces, Mission Control, Show Desktop, and Launchpad in normal/inverted directions, including reversal and slow/fast release, with no rebound or stuck transition. Multiple-display arrangements and deliberately overlapping scroll/drag attempts remain broader compatibility gates. |
| Login Items registration | Deterministic core pass; runtime partial | The login-items branch rejects disposable build locations before registration, validates the embedded helper path, reconciles `SMAppServiceStatusRequiresApproval`/`NotRegistered`/`NotFound` instead of reporting them as enabled, and passes pure path/status tests for installed, moved, duplicate, and disposable copies. The user confirmed that Login Items became discoverable after moving the signed app into `~/Applications`; cold logout/login, move, duplicate-copy, and System Settings approval remain manual gates. |
| Accessibility / lifecycle | Partial pass | Rapid disable/enable cycling and quit/reopen passed in the signed lifecycle build. Transient/disposable build locations are not valid Login Items test targets. Cold permission revoke/regrant, sleep/wake, login launch from a cold boot, and fast-user switching remain pending. |
| Release distribution | Blocked by product decision | The fork retains upstream `com.nuebling.*` IDs and keychain group. Choose owned bundle IDs and keychain migration before signed Release distribution. |

## Test protocol

1. Build and install the signed Debug App from this branch at a stable location, preferably `~/Applications/Mac Mouse Fix.app`; do not use a disposable `/tmp` bundle for Login Items or launch-at-login tests.
2. Enable Mac Mouse Fix from the General tab and wait for Buttons and Scrolling to become available.
3. Run one row at a time. If an input path fails, capture the app version, macOS build, device/connection type, target app, and the smallest reproducible sequence.
4. Disable Mac Mouse Fix at the end and verify the helper job is gone if the test intentionally leaves it disabled.

Do not mark a pending hardware row as passed based solely on a build or static-analysis result.
