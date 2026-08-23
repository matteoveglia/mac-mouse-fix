# Remediation Test Matrix

Updated: 2026-08-23 · Branch: `codex/remediation-p0`

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
| Device hot-unplug | Manual pending | With MMF enabled: use a side button, unplug/reconnect the mouse, then confirm the same button still remaps and the helper remains running. |
| Pointer-freeze / two-finger drag | Manual pending | Start the gesture, move briefly, then release. The real cursor must reappear and move normally. |
| Scroll and virtual/remote input | Partial pass | Fast scrolling works with a mouse remote to this machine. Ordinary scrolling, browser maps, iPhone Mirroring/other remote sources if available, and helper restart remain pending. Do not assess horizontal scaling: it is intentionally not part of this fork. |
| Dock swipes | Manual pending | Test normal/inverted drag into Spaces, Mission Control, Show Desktop, Launchpad, multiple displays, reversals, and releases at low/high velocity. |
| Accessibility / lifecycle | Manual pending | Cold launch, grant/revoke Accessibility, disable/re-enable, sleep/wake, login launch, fast-user switching, and device disconnect/reconnect. |
| Release distribution | Blocked by product decision | The fork retains upstream `com.nuebling.*` IDs and keychain group. Choose owned bundle IDs and keychain migration before signed Release distribution. |

## Test protocol

1. Build the signed Debug App from this branch.
2. Enable Mac Mouse Fix from the General tab and wait for Buttons and Scrolling to become available.
3. Run one row at a time. If an input path fails, capture the app version, macOS build, device/connection type, target app, and the smallest reproducible sequence.
4. Disable Mac Mouse Fix at the end and verify the helper job is gone if the test intentionally leaves it disabled.

Do not mark a pending hardware row as passed based solely on a build or static-analysis result.
