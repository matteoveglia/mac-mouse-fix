# 05 — Upstream Remediation Plan

Date: 2026-08-26
Scope: `noah-nuebling/mac-mouse-fix` upstream and this revival fork
Status: active plan; fork PR #1 merged the scrolling/configuration baseline, fork PR #2 carries the P0 compatibility series, `codex/remediation-p1` carries the first P1 architecture increments, fork PR #6 carries the generation-based scroll reset and helper-registration recovery work, `codex/remediation-login-items` carries the installed-path registration increment, `codex/remediation-policy-editor` carries the advanced app-selector authoring increment, `codex/remediation-lifecycle-closure` carries the current signed lifecycle verification, `codex/remediation-axis-direction-p1` carries the adapted axis-specific reverse-direction increment, `codex/remediation-next-p1` carries the per-app policy runtime identity increment, `codex/remediation-shortcut-release-p1` carries explicit one-shot shortcut modifier release, `codex/remediation-modifier-only-shortcuts-p1` carries modifier-only shortcut capture and playback, `codex/remediation-middle-click-latency-p1` carries deferred-click location stability, `codex/remediation-drag-threshold-p1` carries the adjustable gesture-activation distance, `codex/remediation-menu-state-p1` carries persistent menu-bar feature state, `codex/remediation-pointer-lock-closure-p1` records verified coverage of gesture pointer locking, and `codex/remediation-drag-shortcut-p1` carries drag-triggered keyboard shortcuts. This document supersedes `03-backlog-triage.md` and `04-roadmap.md` where they conflict.

## Executive decision

The first upstreamable work should be a small macOS 27 compatibility series:

1. Replace the macOS 27 Dock-swipe event attachment path with the supported runtime-resolved SkyLight setter, and correct the release-velocity sign.
2. Harden every event-tap creation, enable, disable, and re-enable path so a failed or stale tap cannot crash the helper or silently disable input.
3. Verify the scroll and synthetic-input implementation now merged in fork PR #1.
4. Only then take on device protocol work, per-application policy, and new actions.

None of the 27 open PRs should be merged wholesale. Several contain useful ideas, but the largest ones bundle unrelated features, carry generated build artifacts, or use private APIs without a safe fallback and a reproducible test. The plan below turns those ideas into small, reviewable work packages.

## 1. Inventory snapshot

The tracker was queried live on 2026-08-26. GitHub reports 1,214 open items in the repository metadata; that number includes pull requests. Filtering the REST results gives:

| Object | Count | Meaning |
|---|---:|---|
| Open issues | 1,187 | Full issue-triage scope |
| Open PRs | 27 | Full open-PR disposition below |
| All PRs, open or closed | 78 | 20 merged, 31 closed without merge, 27 open |
| Highest issue number | 1,983 | Tracker is sparse; issue number is not issue count |
| Highest PR number | 1,979 | The user’s own compatibility PR is excluded from upstream backlog decisions |

Upstream is not archived and is still receiving automated commits. The latest repository commits observed were generated `Acknowledgements.md` updates rather than new substantive maintainer work. The latest releases remain stable `3.0.8` (2025-09-12) and prerelease `3.1.0-Beta-1` (2025-11-29). This is a stalled project with occasional maintenance, not a formally abandoned repository; every proposed upstream PR should therefore be narrow and easy for the maintainer to review later.

The complete issue set was classified by labels, title/body search, duplicate families, platform, and actionable state. Labels overlap, so their counts are indicators rather than additive totals. The primary taxonomy below is the 2026-08-23 classification snapshot and still sums to 1,185; the two newer open issues have not yet been manually reclassified, so these category totals must not be read as the current tracker total:

The audit also assigned every open issue one primary, non-overlapping taxonomy category:

| Primary category | Issues | Representative evidence |
|---|---:|---|
| Compatibility/platform | 210 | [#1871](https://github.com/noah-nuebling/mac-mouse-fix/issues/1871), [#1015](https://github.com/noah-nuebling/mac-mouse-fix/issues/1015), [#1141](https://github.com/noah-nuebling/mac-mouse-fix/issues/1141) |
| Reliability/core | 39 | [#988](https://github.com/noah-nuebling/mac-mouse-fix/issues/988), [#192](https://github.com/noah-nuebling/mac-mouse-fix/issues/192), [#1147](https://github.com/noah-nuebling/mac-mouse-fix/issues/1147) |
| Device/input | 225 | [#226](https://github.com/noah-nuebling/mac-mouse-fix/issues/226), [#253](https://github.com/noah-nuebling/mac-mouse-fix/issues/253), [#450](https://github.com/noah-nuebling/mac-mouse-fix/issues/450) |
| Scrolling/gestures | 299 | [#1512](https://github.com/noah-nuebling/mac-mouse-fix/issues/1512), [#989](https://github.com/noah-nuebling/mac-mouse-fix/issues/989), [#746](https://github.com/noah-nuebling/mac-mouse-fix/issues/746) |
| Per-app/configuration | 157 | [#933](https://github.com/noah-nuebling/mac-mouse-fix/issues/933), [#973](https://github.com/noah-nuebling/mac-mouse-fix/issues/973), [#903](https://github.com/noah-nuebling/mac-mouse-fix/issues/903) |
| Actions/shortcuts | 188 | [#364](https://github.com/noah-nuebling/mac-mouse-fix/issues/364), [#476](https://github.com/noah-nuebling/mac-mouse-fix/issues/476), [#1679](https://github.com/noah-nuebling/mac-mouse-fix/issues/1679) |
| UX/localization/docs | 15 | [#1638](https://github.com/noah-nuebling/mac-mouse-fix/issues/1638), [#265](https://github.com/noah-nuebling/mac-mouse-fix/issues/265), [#1799](https://github.com/noah-nuebling/mac-mouse-fix/issues/1799) |
| Licensing/distribution | 36 | [#954](https://github.com/noah-nuebling/mac-mouse-fix/issues/954), [#1819](https://github.com/noah-nuebling/mac-mouse-fix/issues/1819), [#817](https://github.com/noah-nuebling/mac-mouse-fix/issues/817) |
| Low-information/support/duplicates | 16 | [#1976](https://github.com/noah-nuebling/mac-mouse-fix/issues/1976), [#1866](https://github.com/noah-nuebling/mac-mouse-fix/issues/1866), [#269](https://github.com/noah-nuebling/mac-mouse-fix/issues/269) |
| **Total** | **1,185** | Every open issue assigned |

This primary taxonomy is non-overlapping; the label table below is intentionally overlapping and is used to find related reports. The audit found eight exact-title duplicate groups covering 18 records, including the recurring “can’t enable” family ([#192](https://github.com/noah-nuebling/mac-mouse-fix/issues/192), [#269](https://github.com/noah-nuebling/mac-mouse-fix/issues/269), [#648](https://github.com/noah-nuebling/mac-mouse-fix/issues/648), [#1619](https://github.com/noah-nuebling/mac-mouse-fix/issues/1619), [#1849](https://github.com/noah-nuebling/mac-mouse-fix/issues/1849), [#1864](https://github.com/noah-nuebling/mac-mouse-fix/issues/1864)). Consolidate those records before implementation while preserving unique crash logs and device details.

| Existing upstream label | Open issues | Remediation signal |
|---|---:|---|
| Logitech Button Support | 25 | Device protocol/capture family; high-value but hardware-heavy |
| Middle-Drag Incompatibility | 24 | Capture semantics and app compatibility |
| App-Specific Disabling | 23 | Policy model; overlaps current fork work |
| Tilt Wheel as Buttons | 22 | HID report mapping and capture UI |
| Hold & Click Level Timing / Delay | 14 | Gesture state-machine/UX work |
| App-Specific Settings for MMF 3 | 11 | Configuration migration and app identity |
| Pointer Speed | 11 | System setting translation and device behavior |
| Core | 11 | Reliability, lifecycle, and architecture |
| Other Brand Support | 9 | Device-specific investigation |
| Logitech Other Support | 8 | HID++/vendor behavior |
| Click and Drag Invert | 8 | Gesture semantics |
| App-Specific Executables/Java Support | 8 | App identity and policy edge cases |
| Disabled On Restart/Intermittently | 6 | Helper/event-tap lifecycle |
| Universal Control | 6 | Virtual input and device switching |
| Horizontal Scroll Invert | 6 | Axis configuration migration |
| Profiles / Presets / Specific Settings | 6 | Configuration architecture |
| 3.0.2 Scrolling Crashes & Issues | 5 | Scroll regression suite |
| Alternative Space Switching Methods | 4 | Dock-swipe fallback behavior |
| iPhone Mirroring Problems | 4 | Virtual display/input compatibility |
| Remote Desktop Issues | 3 | Synthetic-event policy |
| High Polling Rate Issues | 2 | Event volume/back-pressure |

### Coverage rule

The 1,185 issues are not all independent bugs. The remediation ledger must give every issue one of these dispositions, with a canonical root-cause issue or a reason for closure:

- **P0 active:** blocks a supported OS, causes a crash, or prevents core input.
- **P1 scheduled:** recurring behavior with a defined implementation path after P0.
- **P2 candidate:** useful feature or device support with no current release blocker.
- **Duplicate/related:** link to the canonical issue and preserve any unique evidence.
- **Needs reproduction:** insufficient logs, device details, or steps.
- **Obsolete/unsupported:** behavior is superseded by macOS or the current product contract; close only after a clear explanation.
- **Resolved/unverifiable:** test against the current build before closing; do not infer resolution from age alone.

This prevents a high-volume label or a new Golden Gate report from hiding older evidence. A future tracker pass should export issue number, title, labels, OS, device, app, reproduction quality, duplicate target, priority, owner, and test result to a versioned ledger.

## 2. Corrections to the earlier planning documents

### The June Dock-swipe change is incomplete

Commit [`f92d2d53a0`](https://github.com/noah-nuebling/mac-mouse-fix/commit/f92d2d53a0) adds the macOS 27 HID-event payload generation and test harness, but it does not replace the unsafe event attachment bridge. `Shared/IOKit/CGEventHIDEventBridge.m` still writes through hard-coded private `CGEvent` offsets. `Helper/Core/Touch/TouchSimulator.m` calls `CGEventSetHIDEvent`, which reaches that bridge. `Tests/FixDockSwipes.m` explicitly demonstrates that the SkyLight setter works while the CG variant does not.

The practical conclusion is: upstream master contains a useful payload-generation half-fix, not a shippable macOS 27 Dock-swipe fix. Issues saying Dock swipes are still dead or rebound remain valid until the bridge is changed and tested on the affected OS.

### There are nine open Dock-swipe PRs, not eight

The earlier list omitted [#1875](https://github.com/noah-nuebling/mac-mouse-fix/pull/1875). It is important because it supplies a discrete SymbolicHotKey fallback, but it also documents the behavioral cost: threshold-triggered switching is not equivalent to continuous click-and-drag simulation. It must not silently become the default path.

### Issue #1926 is a dual-symptom report

The title is about five-button behavior on macOS 27, but a comment includes a helper crash with `EXC_BAD_ACCESS` in `CFMachPortGetContext`/`SLEventTapEnable`. Other comments report that plain clicks work while click-drag and click-scroll do not. Treat it as both an event-tap lifecycle crash and an input-path compatibility report, not as a simple Logitech feature request.

### Fork PR #1 establishes the new scrolling baseline

Fork [PR #1](https://github.com/matteoveglia/mac-mouse-fix/pull/1), `Restore macOS compatibility across app, helper, and configuration`, merged into `master` as `4fac63364` on 2026-08-23. It consolidates the earlier app-enable and keychain safety fixes with software-KVM/synthetic mouse and scroll handling, signed synthetic wheel deltas, axis-specific speed/smoothness controls, and the first app-scoped trackpad-simulation configuration. Horizontal scaling appeared in intermediate commits but is not in the final merged tree.

This replaces the previous assumption that scrolling work was merely in progress. The implementation is now the baseline for WP3 and WP5; do not overwrite it or cherry-pick [#1865](https://github.com/noah-nuebling/mac-mouse-fix/pull/1865). Fork commits `70efcfd8c`, `4a12aed0b`, `90b031544`, and `bcc424068` add the macOS 27 Dock-swipe bridge/release-velocity correction, tap creation and desired-state guards, startup command gating, and owned-source shutdown teardown. `878603c25` makes helper disable wait for ServiceManagement completion and requests termination after a successful unregister. Signed Debug App and unsigned `Tests` harness builds pass with Xcode 27. Hardware, TCC, sleep/wake, and Dock behavior remain manual P0 gates.

## 3. Priority order

### P0 — release-blocking compatibility and reliability

| Workstream | Canonical evidence | Exit condition |
|---|---|---|
| macOS 27 Dock/Spaces/Mission Control | [#1919](https://github.com/noah-nuebling/mac-mouse-fix/issues/1919), [#1931](https://github.com/noah-nuebling/mac-mouse-fix/issues/1931), [#1935](https://github.com/noah-nuebling/mac-mouse-fix/issues/1935), [#1943](https://github.com/noah-nuebling/mac-mouse-fix/issues/1943), [#1945](https://github.com/noah-nuebling/mac-mouse-fix/issues/1945), [#1947](https://github.com/noah-nuebling/mac-mouse-fix/issues/1947), [#1954](https://github.com/noah-nuebling/mac-mouse-fix/issues/1954), [#1961](https://github.com/noah-nuebling/mac-mouse-fix/issues/1961), [#1967](https://github.com/noah-nuebling/mac-mouse-fix/issues/1967), [#1974](https://github.com/noah-nuebling/mac-mouse-fix/issues/1974), [#1978](https://github.com/noah-nuebling/mac-mouse-fix/issues/1978) | Continuous swipe works on macOS 27, including release, reverse direction, multiple displays, and all supported Dock actions |
| Helper startup/event taps | [#1926](https://github.com/noah-nuebling/mac-mouse-fix/issues/1926), [#1923](https://github.com/noah-nuebling/mac-mouse-fix/issues/1923), [#1909](https://github.com/noah-nuebling/mac-mouse-fix/issues/1909) | No crash or silent disable after launch, permission changes, sleep/wake, or re-enable |
| Core scroll reliability | [#746](https://github.com/noah-nuebling/mac-mouse-fix/issues/746), [#875](https://github.com/noah-nuebling/mac-mouse-fix/issues/875), [#943](https://github.com/noah-nuebling/mac-mouse-fix/issues/943), [#988](https://github.com/noah-nuebling/mac-mouse-fix/issues/988), [#989](https://github.com/noah-nuebling/mac-mouse-fix/issues/989), [#1081](https://github.com/noah-nuebling/mac-mouse-fix/issues/1081), [#1103](https://github.com/noah-nuebling/mac-mouse-fix/issues/1103), [#1106](https://github.com/noah-nuebling/mac-mouse-fix/issues/1106), [#1147](https://github.com/noah-nuebling/mac-mouse-fix/issues/1147), [#1915](https://github.com/noah-nuebling/mac-mouse-fix/issues/1915), [#1922](https://github.com/noah-nuebling/mac-mouse-fix/issues/1922) | Implementation baseline merged in fork PR #1; no dead-scroll, heavy-scroll crash, browser jerkiness, or incorrect system speed behavior in the regression matrix |
| Device capture and extra buttons | [#226](https://github.com/noah-nuebling/mac-mouse-fix/issues/226), [#253](https://github.com/noah-nuebling/mac-mouse-fix/issues/253), [#520](https://github.com/noah-nuebling/mac-mouse-fix/issues/520), [#775](https://github.com/noah-nuebling/mac-mouse-fix/issues/775), [#847](https://github.com/noah-nuebling/mac-mouse-fix/issues/847), [#885](https://github.com/noah-nuebling/mac-mouse-fix/issues/885), [#1214](https://github.com/noah-nuebling/mac-mouse-fix/issues/1214), [#1220](https://github.com/noah-nuebling/mac-mouse-fix/issues/1220), [#1508](https://github.com/noah-nuebling/mac-mouse-fix/issues/1508), [#1932](https://github.com/noah-nuebling/mac-mouse-fix/issues/1932) | Capture behavior is deterministic for supported devices; unsupported HID reports fail visibly rather than fabricating or dropping actions |
| Virtual/remote input | [#1015](https://github.com/noah-nuebling/mac-mouse-fix/issues/1015), [#1779](https://github.com/noah-nuebling/mac-mouse-fix/pull/1779), [#1952](https://github.com/noah-nuebling/mac-mouse-fix/issues/1952) | Universal Control, iPhone Mirroring, and the supported remote-input cases do not strand the helper or leave stale state |

### P1 — recurring behavior and architecture

- Per-app disabling and settings: the `App-Specific Disabling`, `App-Specific Settings for MMF 3`, `Profiles / Presets / Specific Settings`, and Java/executable issue families; current fork work and [#1865](https://github.com/noah-nuebling/mac-mouse-fix/pull/1865) overlap here.
- Axis direction, speed, acceleration, and gesture semantics: [#1803](https://github.com/noah-nuebling/mac-mouse-fix/pull/1803), [#1512](https://github.com/noah-nuebling/mac-mouse-fix/issues/1512), [#533](https://github.com/noah-nuebling/mac-mouse-fix/issues/533), [#1131](https://github.com/noah-nuebling/mac-mouse-fix/issues/1131), [#753](https://github.com/noah-nuebling/mac-mouse-fix/issues/753), [#655](https://github.com/noah-nuebling/mac-mouse-fix/issues/655), [#519](https://github.com/noah-nuebling/mac-mouse-fix/issues/519), [#1922](https://github.com/noah-nuebling/mac-mouse-fix/issues/1922), and [#1956](https://github.com/noah-nuebling/mac-mouse-fix/issues/1956).
- Button/hold/drag state semantics: the `Hold & Click Level Timing / Delay`, `Click and Drag Invert`, and `Tilt Wheel as Buttons` families, plus [#1903](https://github.com/noah-nuebling/mac-mouse-fix/issues/1903), [#1907](https://github.com/noah-nuebling/mac-mouse-fix/issues/1907), [#1911](https://github.com/noah-nuebling/mac-mouse-fix/issues/1911), [#1929](https://github.com/noah-nuebling/mac-mouse-fix/issues/1929), [#1933](https://github.com/noah-nuebling/mac-mouse-fix/issues/1933), [#1964](https://github.com/noah-nuebling/mac-mouse-fix/issues/1964), and [#1970](https://github.com/noah-nuebling/mac-mouse-fix/issues/1970).
- Menu-bar state and persistence: [#1972](https://github.com/noah-nuebling/mac-mouse-fix/issues/1972), [#1975](https://github.com/noah-nuebling/mac-mouse-fix/issues/1975), and any report where the UI says disabled after restart. Verify storage, activation, and helper state separately.

### P2 — valuable features and isolated maintenance

- Logitech HID++ support, new scroll/drag actions, momentum arrest, volume/brightness, and window manipulation after the P0 input path is stable.
- Safe translation and UI corrections such as [#1836](https://github.com/noah-nuebling/mac-mouse-fix/pull/1836), after checking the current string catalog.
- Packaging and release automation such as [#1814](https://github.com/noah-nuebling/mac-mouse-fix/pull/1814), adapted for this fork’s own signing and update policy.

### P3 — close, redirect, or defer

Old pre-Ventura behavior, issues superseded by native macOS functionality, empty reports, duplicate language reports, and stale “fixed in beta” reports should be closed only with a canonical link, current-version test result, and a request to reopen with new evidence. Examples include [#14](https://github.com/noah-nuebling/mac-mouse-fix/issues/14), [#77](https://github.com/noah-nuebling/mac-mouse-fix/issues/77), and [#192](https://github.com/noah-nuebling/mac-mouse-fix/issues/192). This is tracker hygiene, not permission to dismiss active compatibility reports.

## 4. Implementation work packages

### WP0 — reproducible baseline and release safety

1. Pin the upstream commit, fork branch, SDK, Xcode version, and build configuration used for each test result.
2. Build App and Helper from a clean checkout in Debug and Release. Check that local signing, entitlements, bundle identifiers, Sparkle configuration, and helper registration match the intended distribution model.
3. Add a macOS CI workflow that builds both targets and runs non-UI tests. Keep hardware and Accessibility tests as explicitly labelled manual jobs.
4. Record a baseline before each functional change. The current feature work from the other chat is part of that baseline; do not reset, stash, or rebase it without coordination.

5. Test Debug and Release signing separately. Local Debug entitlements intentionally lack the shared keychain group, while the Release configuration and app/helper keychain-sharing behavior remain unverified.

Current implementation: `.github/workflows/build.yml` compiles the unsigned Debug and Release App/Helper plus the Dock-swipe harness on pushes, pull requests, and manual dispatch. It builds from a disposable runner copy because the existing Release build phase increments the source plist version; CI verifies the checked-out version plists remain unchanged. The shared Helper Debug and Release schemes now build the Helper target directly and use product-relative runnables instead of a former contributor's absolute DerivedData path. A locally signed Release build is deliberately blocked: the fork retains upstream's `com.nuebling.*` identifiers and Release keychain access group, which cannot be provisioned by this Apple team. Choose owned bundle identifiers and a keychain migration before attempting a distributable signed Release artifact.

### WP1 — macOS 27 Dock-swipe bridge

Implement this as a standalone, upstreamable change in `Shared/IOKit/CGEventHIDEventBridge.m` and the touch simulation call path.

- Resolve `SLEventSetIOHIDEvent` at runtime through the project’s existing symbol-loader utility or an equivalent `dlsym` path. Do not require a private SkyLight link at build time.
- On macOS 27 and later, use the SkyLight setter. If the symbol is unavailable, fail closed with a diagnostic rather than writing guessed object offsets into a changed private structure.
- Keep the legacy offset path only for OS versions where it is known to work, and isolate it behind an explicit availability check.
- Establish the ownership contract for the HID event. Test whether the setter retains or consumes the object; avoid both leaks and use-after-free.
- Preserve the payload work from `f92d2d53a0`, but validate the display coordinate, event phase, button flags, progress, and end-event fields.
- Unflip both progress deltas and release velocity when the gesture is inverted. The current code only corrects the origin delta; the exit-speed sign is implicated in rebound/stutter reports.
- Do not make the SymbolicHotKey implementation from [#1875](https://github.com/noah-nuebling/mac-mouse-fix/pull/1875) or [#1950](https://github.com/noah-nuebling/mac-mouse-fix/pull/1950) the default. It is a discrete emergency fallback that loses continuous drag behavior and may interfere with overlay heuristics.

Acceptance tests:

- Continuous click-drag into Spaces/Mission Control, Show Desktop, Launchpad, and move-between-spaces.
- Normal and inverted directions, natural scrolling settings, horizontal and vertical inputs, multiple displays, display arrangement changes, and a release at low and high velocity.
- Start, reverse, pause, and end without a stuck transition, rebound, duplicate end event, or overlay mismatch.
- Symbol absent, Accessibility denied, helper restarted mid-gesture, and macOS 26 behavior remain safe.

Relevant prior art is [#1920](https://github.com/noah-nuebling/mac-mouse-fix/pull/1920), [#1936](https://github.com/noah-nuebling/mac-mouse-fix/pull/1936), [#1938](https://github.com/noah-nuebling/mac-mouse-fix/pull/1938), and [#1950](https://github.com/noah-nuebling/mac-mouse-fix/pull/1950). [#1924](https://github.com/noah-nuebling/mac-mouse-fix/pull/1924) adds an extra retain whose ownership contract is not established; treat it as a comparison, not code to copy. The raw serialization approaches in [#1895](https://github.com/noah-nuebling/mac-mouse-fix/pull/1895) and [#1918](https://github.com/noah-nuebling/mac-mouse-fix/pull/1918) are reference material only.

Current implementation and verification: the Dock-swipe reducer now owns accumulated progress, previous-delta release velocity, reversal-to-cancellation behavior, zero-delta suppression, and the distinct legacy/modern inversion coordinate spaces. A separate injectable attachment router proves that the macOS 27 path calls only the SkyLight setter, fails closed when it is absent or refuses attachment, and never falls back to legacy offsets. `CGEventSetHIDEvent` reports attachment failure so `TouchSimulator` cannot post or retry a payload-less modern event. Both suites and the GitHub build pass, and the signed Xcode 27 Debug build passed local Spaces, Mission Control, Show Desktop, and Launchpad testing in normal and inverted directions, including reversal and slow/fast release without rebound or a stuck transition. Multiple-display arrangements and deliberately overlapping gesture producers remain broader runtime gates; one-machine verification is not enough to close the full issue cluster.

### WP2 — event-tap lifecycle and helper stability (owned lifecycle implemented; runtime matrix pending)

Audit and then centralize the lifecycle of every event tap. The audit includes `Helper/Utility/ModificationUtility.m`, `Helper/Core/Buttons/ButtonInputReceiver.m`, `Helper/Core/Scroll/Scroll.m`, `Helper/Utility/PointerFreeze.m`, `Helper/Utility/GlobalEventTapThread.m`, and the switch/master input paths.

- Completed in the current increment: `Scroll`, `ButtonInputReceiver`, `Modifiers`, `ModifiedDrag`, `PointerFreeze`, `KeyCaptureMode`, and `ModificationUtility` reject failed tap/source creation, avoid `CGEventTapIsEnabled`/`CGEventTapEnable` on null taps, and do not re-enable after a caller has requested stop. New taps are disabled before their run-loop source is attached.
- Completed in the follow-up increment: the helper now admits only health-check, Accessibility-check, and termination messages until all post-Accessibility modules are initialized; configuration, device, remap, and event-tap commands are rejected during the startup gap.
- Runtime-verified on the local signed Debug bundle: ServiceManagement launched the embedded helper, a direct `launchctl kill SIGTERM` restart changed its PID, and the replacement process remained active from the same Debug bundle.
- Completed in the shutdown increment: each active tap owner now retains its source, and helper termination disables, invalidates, removes, and releases taps on their owning main or global input run loop. The global input thread supports bounded synchronous work for this teardown path.
- Completed in the disable-state increment: disabling is idempotent when System Settings has already disabled the ServiceManagement registration but a helper process remains. The app now treats any non-enabled service status as already disabled, terminates the helper, and updates the UI to off instead of trapping the switch on. Verified in the signed Debug app: the live toggle removed the ServiceManagement job and helper process.
- Completed in the key-capture increment: shortcut recording now verifies every enable, disable, and timeout recovery operation; a failed operation clears its desired state instead of leaving an inert capture mode armed.
- Completed in the helper-service increment: ServiceManagement register/unregister work now runs on one serial queue, preserving rapid enable/disable request order instead of racing on a global concurrent queue.
- Verified after that change in the signed Debug app: the active helper was disabled through the live General-tab toggle; the UI disabled its Buttons and Scrolling tabs, and the ServiceManagement job and helper process were absent afterward.
- Completed in the UI-completion increment: the asynchronous helper-registration callback now returns to the main queue before General-tab controllers can update AppKit state, timers, or failure toasts.
- Completed in the pointer-freeze increment: a failed tap enable restores the default global cursor-suppression interval, timeout recovery and normal unfreeze now serialize on the pointer queue, a failed timeout recovery explicitly unfreezes the pointer, and helper teardown restores the real cursor/removes the puppet cursor if disable interrupts a drag.
- Completed in the owned-lifecycle increment: `MFEventTapHandle` now owns tap creation, the run-loop source, desired state, idempotent enable/disable, timeout recovery state, and one-time teardown. `Scroll`, `ButtonInputReceiver`, `Modifiers`, `ModifiedDrag`, `PointerFreeze`, and `KeyCaptureMode` use the handle on their existing main/global run loops and no longer query or enable raw taps from their caller queues.
- Deterministic fake-backend tests cover tap/source creation failure, inert creation, idempotent enable, refused enable, late-enable rejection, stable teardown order, and exactly-once release. Debug, Release, and the existing Tests target build successfully with Xcode 27 after the migration.
- Runtime-verified in the signed lifecycle build: rapid disable/enable cycling, quit/reopen, shortcut capture, normal buttons and scrolling, and modified-drag teardown all passed without a stuck or hidden pointer.
- Login Items setup evidence: a disposable build was not discoverable in System Settings, while the signed app became discoverable after it was moved into the user’s `~/Applications` folder. Use a stable installed app path for ServiceManagement and launch-at-login verification; do not treat a temporary build location as a product failure or as a valid cold-launch test.
- Completed in the Login Items increment: registration now rejects disposable build locations, validates that the current app resolves its embedded helper and agent plist from the same bundle, and reconciles `SMAppService` status after register/unregister. A successful API call with `RequiresApproval`, `NotRegistered`, or `NotFound` is no longer reported to the UI as an enabled helper. Pure tests cover installed, moved, duplicate, and disposable bundle paths plus enable/disable status transitions; macOS still owns the final registration state.
- Completed in the menu-state increment for [#1972](https://github.com/noah-nuebling/mac-mouse-fix/issues/1972): opening the Buttons or Scrolling settings tab and hiding the menu-bar item no longer clear the persisted feature kill switches. Add Mode temporarily bypasses a feature kill switch for input capture without changing its saved value, while inactive-session and helper-lockdown checks remain authoritative. Focused persistence/source-policy and capture-policy suites pass, as do the signed Debug App/Helper build and deep signature verification. The user confirmed independent Buttons/Scrolling state survives quit/reopen, opening both settings tabs, and hiding/showing the menu item; Add Mode still captures while ordinary remapping remains disabled afterward.
- Remaining runtime work: exercise forced timeout recovery, permission revocation/regrant, sleep/wake, fast-user switching, and a longer click/scroll soak.
- Treat a null tap, invalid Mach port, or missing run-loop source as a recoverable state with structured logging, not as a valid tap.
- Make enable/disable/re-enable idempotent and serialized. Remove sources before releasing taps; never re-enable a tap after ownership has ended.
- Handle Accessibility/TCC denial, revocation, fast user switching, sleep/wake, and helper registration failure with a retry/back-off path and an accurate menu-bar state.
- Record the tap type, creation result, OS version, permission state, and retry count without logging sensitive event contents.
- Reproduce the `CFMachPortGetContext`/`SLEventTapEnable` crash signature from [#1926](https://github.com/noah-nuebling/mac-mouse-fix/issues/1926) before and after the fix.

Acceptance tests include cold launch, launch at login, permission grant/revoke, app disable/re-enable, helper restart, sleep/wake, user switch, device disconnect/reconnect, and a several-hour scroll/click soak. A failed tap must leave the helper alive and make the disabled state actionable. The build-only checks do not replace this matrix.

### WP3 — scroll and synthetic-input reliability (implementation landed; verification active)

Fork PR #1 landed the synthetic KVM, signed-delta, axis-control, and app-scope implementation. Preserve and regression-test that baseline before making further architectural changes.

- Trace one input from hardware or virtual source through capture, transformation, acceleration/smoothing, axis scaling, and output injection.
- Make signed deltas, zero deltas, low smoothness, high polling rate, axis-specific configuration, and synthetic timestamps explicit test cases.
- Verify that `senderID == 0` and unattached input do not accidentally admit unsupported real hardware events; cover Wacom/tablet input, no-device startup, Accessibility denial, and hot-plug after a failed HID lookup.
- The shared sender-ID-to-`IOHIDDeviceRef` cache now serializes all reads and misses because it is called from both event-tap and asynchronous scroll processing. This removes concurrent `NSMutableDictionary` mutation while preserving cached positive and negative lookups.
- The sender-device cache is cleared whenever an attached device is removed. This prevents a late event or reused sender ID from resolving to a disconnected `IOHIDDeviceRef` after USB/Bluetooth hot-unplug.
- `StrangeDevice`, used for admitted synthetic button events, now returns a stable non-nil placeholder ID instead of a null Objective-C pointer; this keeps click-cycle identity valid without dereferencing a physical HID device.
- Compare configured speed with the system scroll-speed setting on Razer and Logitech devices; do not assume the system value is a device-independent multiplier.
- Re-test Firefox, Chrome/Google Maps, Preview, Mission Control, iPhone Mirroring, Remote Desktop, and Java/Electron apps.
- Add a state-reset test for heavy scroll, app switch, helper restart, and device hot-unplug so momentum cannot survive into the next session.
- Completed in the scroll-reset increment: reset boundaries advance an atomic generation before canceling queued scroll work, smooth-scroll animation callbacks, and gesture momentum callbacks. Enable/disable transitions, shutdown, modifier changes, and removal of an attached device synchronously clear analyzer counters, cached configuration, subpixel state, momentum input history, and any Command-Tab modifier held by the active scroll series. The generation reducer has deterministic stale-work, repeated-reset, and wraparound coverage in CI; Debug and Release Helper builds pass. The user’s signed installed build passed the runtime scroll-reset checks with a remote mouse; browser maps, iPhone Mirroring, and broader device/source combinations remain explicit gates.
- The Scroll event tap now has a null-safe create/enable/disable/recovery path; run the P0 manual matrix before claiming scroll reliability.
- The asynchronous scroll diagnostics no longer dereference a sending `IOHIDDeviceRef`: that object can be stale after a disconnect, and the existing crash signature was in `IOHIDDeviceGetProperty`. Diagnostics log the event's copied sender ID instead. The real device disconnect/reconnect matrix remains an explicit runtime gate.
- Separate a true scroll-path regression from a dead event tap or an app-specific incompatibility before changing math.

### WP4 — Logitech and other device input

Treat [#1710](https://github.com/noah-nuebling/mac-mouse-fix/pull/1710), [#1856](https://github.com/noah-nuebling/mac-mouse-fix/pull/1856), [#1848](https://github.com/noah-nuebling/mac-mouse-fix/pull/1848), [#1823](https://github.com/noah-nuebling/mac-mouse-fix/pull/1823), [#1928](https://github.com/noah-nuebling/mac-mouse-fix/pull/1928), and the Logitech part of [#1938](https://github.com/noah-nuebling/mac-mouse-fix/pull/1938) as competing protocol research, not merge candidates.

1. Choose one small HID++ transport/protocol layer and define ownership, timeouts, report parsing, and device disconnect behavior.
2. Start with virtual report fixtures for M650/L, MX Master, Lift, M720, and Logi Bolt/Unifying variants. Add real-hardware tests only after fixtures cover the state machine.
3. Keep button capture separate from optional DPI/gesture reprogramming. A device that cannot be reprogrammed must still receive ordinary button handling.
4. Do not add generated `.build`/DerivedData artifacts, a large hidapi subtree, or unrelated drag effects to the first device PR.
5. Verify click, click-drag, and click-scroll for buttons 4/5; cover wireless reconnect and Logi Options/other vendor software interactions.

Current implementation: `Shared/Devices/HIDPP` now contains a deliberately transport-agnostic HID++ frame and request lifecycle core. It strictly accepts only 7-byte `0x10` and 20-byte `0x11` reports, owns immutable request identities, permits one in-flight request, and defines deterministic timeout, cancellation, disconnect, stop, and late-response behavior. The production helper compiles the parser/client only; the fixture transport is test-only and cannot write to hardware. Synthetic fixtures exercise short/long reports and lifecycle races in CI. This completes the safe protocol foundation, not model support: no Logitech product is claimed supported until real captures identify the required features and a reviewed IOKit transport passes the physical-device matrix.

### WP5 — per-application policy and configuration

Finish the active fork feature separately from this compatibility series, then compare it with [#1865](https://github.com/noah-nuebling/mac-mouse-fix/pull/1865). Reimplement the desired behavior rather than importing its polluted branch.

- Define app identity precedence: bundle identifier, executable path, Java/application wrappers, and fallback process name.
- Define include/exclude semantics, defaults, inheritance, and what happens when the target app changes while a gesture is in progress.
- Completed in the scrolling increment: the versioned 24→25 configuration migration now preserves legacy shared scroll speed/smoothness while seeding the vertical, horizontal, and app-scoped trackpad defaults before normal helper operation. It also removes the experimental horizontal-scale key, which is intentionally not part of this fork.
- Extend app identity beyond a bundle identifier before treating this feature family as resolved: executable paths, Java/wrapper processes, and a controlled process-name fallback need explicit behavior.
- Keep policy decisions in the app/config layer; the helper should receive a validated immutable snapshot and a clear update boundary.
- Test a missing/uninstalled app, multiple matching processes, app relaunch, full-screen apps, iPhone Mirroring, and permission denial.

Current implementation: config version 27 adds a bounded immutable application-policy snapshot with exact bundle-ID, executable-path, wrapper-bundle, wrapper-path, and controlled process-name selectors. Matching precedence is bundle ID, executable path, wrapper metadata, then process name; process-name fallback is only eligible when no stable identity is available. Legacy `all`/`include`/`exclude` data migrates losslessly to the canonical schema, while the 26→27 migration marks existing exact-selector policies as Advanced. In Advanced mode, the helper ignores the legacy app list and evaluates only the exact advanced selectors with an allow-by-default fallback; switching to a legacy mode preserves those selectors for later reuse without applying them. Malformed data fails closed, and the current bundle-list UI keeps canonical and legacy values synchronized. Scroll policy is captured at the start of a consecutive scroll series, so changing the application under the pointer does not change behavior halfway through a gesture. Deterministic tests cover precedence, validation, migration, round-trip encoding, and fallback behavior. The Scrolling tab exposes a spacious Advanced Application Rules sheet through the persistent Apply To → Advanced mode, whose contextual button is Edit Rules…; inline validation, selector-specific examples, and a Choose App… action fill exact executable, wrapper, or bundle values. Ordinary bundle-ID rules remain under Edit Apps…. Signed UI interaction and the physical Java/iPhone-Mirroring/full-screen matrix remain runtime gates.

The current axis-direction increment adapts [#1803](https://github.com/noah-nuebling/mac-mouse-fix/pull/1803) to this config chain without disturbing the application-policy keys: config version 28 migrates the legacy shared reverse-direction preference to independent vertical and horizontal keys, `Scroll.m` selects the setting from the input axis for both direction calculations, `SwitchMaster` keeps capture active when either axis is modified, and the Scrolling tab exposes both controls. Pure selector tests, default-config validation, signed Debug build, and UI smoke inspection pass; the four-combination physical input matrix and modifier-remapped horizontal behavior remain manual gates.

The next per-app policy increment closes the runtime identity handoff. The scroll event tap captures WindowServer's event-handler window number before dispatching to the worker queue, preferring `kCGMouseEventWindowUnderMousePointerThatCanHandleThisEvent` and falling back to the visual window field. The worker resolves that exact window through `CGWindowListCopyWindowInfo` with the required above-window option and explicit window-number filtering. Some physical, software, and remote scroll sources omit those mouse-specific event fields, so an unresolved fast lookup now falls back once per scroll series to the established point-based application lookup; this restores legacy and Advanced deny rules without putting AppKit work inside the active event-tap callback. Deterministic tests cover field precedence, missing IDs, non-first window entries, and missing window lists; the full local remediation suite and signed Xcode 27 Debug build pass. Legacy All Apps Except Safari and an Advanced Safari wrapper-path deny rule both pass on the signed fallback build. Java/wrapper runtimes beyond Safari, full-screen, missing-app, app-switch, and iPhone Mirroring remain gates.

### WP6 — actions, gesture semantics, and UX

After P0/P1 reliability, implement small features one at a time. Momentum arrest, gaming-mode toggle, directional scroll controls, and new button actions should each have a state-machine test and a way to cancel safely. Window movement/resize, rotate/zoom, media/brightness, and timeline scrubbing require app compatibility tests and should not be bundled together. The existing click-cycle hold/level-expiry timers now verify that the original device and button still own the active cycle before firing; a release or replacement cycle is treated as cancellation rather than a force-unwrapped crash or a stale action.

- Completed in the P1 architecture increment: click-cycle hold and level-expiry callbacks carry generation and ownership tokens. Release, device replacement, expiration, and repeated teardown invalidate stale timers; teardown is idempotent and no callback force-unwraps vanished state. A deterministic reducer suite covers stale hold/expiry callbacks, release, replacement cycles, and repeated cancellation. `forceKill()` remains outside this increment because it has no established production contract.

- Completed in the current increment: settings-tab resize transitions are interruptible. A click during the window's spring-resize now cancels the previous timer and frame animation, restores its temporary constraints, and selects the requested tab instead of discarding the click. Signed Debug App and unsigned `Tests` harness builds pass; the launched Debug app switches General and About with one click in each direction. Rapid physical clicking remains part of the manual UX matrix.

- Completed in the shortcut-release increment: one-shot keyboard shortcuts now synthesize explicit modifier-down events, tap the primary key, and release modifiers in reverse order. This closes the stuck-modifier mechanism reported in [#1907](https://github.com/noah-nuebling/mac-mouse-fix/issues/1907) while retaining non-key-state event flags and mixed ANSI/JIS keyboard-type handling. Deterministic tests cover Command-Tab, a three-modifier chord, reverse release order, and unmodified/non-key-state flags; the full remediation suite and signed Debug App/Helper build pass. The user confirmed the signed build's app-switching shortcut repeatedly completes without leaving modifiers or the switcher stuck.
- Completed in the modifier-only shortcut increment: shortcut capture now retains a solitary Control, Option, Shift, Command, or Fn press when that modifier is released, preserving its left/right virtual key code. A second modifier rejects the candidate until the chord is fully released, while ordinary shortcuts continue through the existing key-down path. Modifier-only actions use the existing keyboard-shortcut dictionary with zero surrounding flags; playback posts the primary modifier down with its flag and releases it without the flag, and the UI renders the corresponding glyph directly. Reducer and event-plan tests cover single-modifier capture, side identity, multi-modifier rejection/rearming, and modifier-only playback for [#1903](https://github.com/noah-nuebling/mac-mouse-fix/issues/1903). The deterministic suite, signed Debug App/Helper build, and deep signature verification pass. The user confirmed modifier-only capture/playback and ordinary modifier-key chords work in the signed build.
- Completed in the deferred-click location increment for [#1933](https://github.com/noah-nuebling/mac-mouse-fix/issues/1933): synthetic mouse-button actions retain the physical press location while the click cycle resolves an ambiguous single-versus-double-click mapping. The stock three-button preset intentionally waits about 260 ms because button 3 has both first- and second-click actions; removing that delay globally would break the second-click action. Preserving the press location prevents a delayed middle click from following later pointer movement and closing a different tab. Focused click-cycle/location tests, the signed Debug App/Helper build, and deep signature verification pass. The user confirmed the delayed middle click targets the intended tab while second-click, hold, and drag behavior remain functional.
- Completed in the gesture-activation increment for the first half of [#1964](https://github.com/noah-nuebling/mac-mouse-fix/issues/1964): Buttons → Options exposes a 3–40 px activation-distance control while preserving the previous 7 px default through config version 29. Values are clamped at the config boundary, and the helper snapshots the setting when a modified drag begins so changing it cannot alter an active gesture. Focused migration and clamping tests, the signed Debug App/Helper build, Interface Builder compilation, and deep signature verification pass. The user confirmed low and high thresholds behave correctly with physical input, including the surrounding click, hold, drag, click-scroll, and pointer-lock checks. Support for additional physical buttons is separate device/protocol work under WP4.
- Verified as existing behavior for [#1970](https://github.com/noah-nuebling/mac-mouse-fix/issues/1970): Buttons → Options already exposes Lock Mouse Pointer During Click and Drag Gestures. The two- and three-finger gesture outputs freeze at activation and unfreeze on normal completion, cancellation, event-tap recovery failure, and helper teardown. Owned-lifecycle tests and the signed lifecycle build cover the safety paths, and the user confirmed the option prevents pointer movement without regressing click, hold, drag, or click-scroll behavior in the signed threshold build. No duplicate setting or output path is required.
- Completed in the drag-shortcut increment for [#1911](https://github.com/noah-nuebling/mac-mouse-fix/issues/1911): a Click and Drag row can use the existing Record Keyboard Shortcut capture UI, including Apple media keys. The captured action dictionary remains in the established remap format and is routed to a dedicated drag output only after validation. Crossing the configured activation distance executes it once; duplicate activation, later movement, release, and cancellation cannot repeat it. Malformed or unsupported persisted action dictionaries fail closed. The deterministic event-plan suite, clean signed Debug App/Helper build, and deep signature verification pass. The user confirmed physical shortcut capture and one-shot playback with and without a keyboard-modifier precondition, including no action below the threshold and no repeats after activation.

### WP7 — distribution and upstream handoff

- Choose whether the fork publishes signed builds, unsigned developer builds, or both. Document certificates, Sparkle feed ownership, bundle IDs, and helper registration.
- Adapt [#1814](https://github.com/noah-nuebling/mac-mouse-fix/pull/1814) only if it builds or packages this fork’s own artifacts; do not silently redistribute upstream binaries.
- Keep compatibility fixes as separate commits with a short reproduction, test matrix, and OS/API rationale.
- Open upstream PRs one work package at a time. Include the affected issue cluster, tested OS builds, fallback behavior, and known limitations.

## 5. Disposition of all 27 open PRs

| PR | Scope | Disposition |
|---|---|---|
| [#1950](https://github.com/noah-nuebling/mac-mouse-fix/pull/1950) | macOS 27 Dock drag | Extract SkyLight/velocity ideas; do not adopt SymbolicHotKey as default |
| [#1938](https://github.com/noah-nuebling/mac-mouse-fix/pull/1938) | Dock fix plus Lift DPI/button support | Split into WP1 and WP4; no wholesale merge |
| [#1936](https://github.com/noah-nuebling/mac-mouse-fix/pull/1936) | Dock fix and release rebound | Strongest WP1 reference; reimplement with fail-closed symbol handling and tests |
| [#1928](https://github.com/noah-nuebling/mac-mouse-fix/pull/1928) | M720/Bluetooth/Unifying HID++ | Research only; reject generated artifacts and the 75-file bundle |
| [#1924](https://github.com/noah-nuebling/mac-mouse-fix/pull/1924) | Dock fix | Reject as superseded; inspect the extra-retain ownership assumption only |
| [#1918](https://github.com/noah-nuebling/mac-mouse-fix/pull/1918) | Raw Dock event serialization | Reject wholesale; inspect payload observations only |
| [#1916](https://github.com/noah-nuebling/mac-mouse-fix/pull/1916) | Dock fix | Reference only; unsafe offset fallback on macOS 27 |
| [#1912](https://github.com/noah-nuebling/mac-mouse-fix/pull/1912) | Dock fix | Reference only; direct SkyLight linkage needs a safer project-compatible design |
| [#1904](https://github.com/noah-nuebling/mac-mouse-fix/pull/1904) | Large drag/HID++/inertia bundle | Reject as a bundle; split ideas into WP3/WP4/WP6 |
| [#1895](https://github.com/noah-nuebling/mac-mouse-fix/pull/1895) | Hand-parsed private event data | Reject; historical reverse-engineering reference only |
| [#1875](https://github.com/noah-nuebling/mac-mouse-fix/pull/1875) | SymbolicHotKey Dock fallback | Emergency fallback experiment only; document discrete-behavior limitation |
| [#1865](https://github.com/noah-nuebling/mac-mouse-fix/pull/1865) | Per-app settings and UI-thread fixes | Reimplement/coordinate with current fork WIP; do not cherry-pick polluted branch |
| [#1862](https://github.com/noah-nuebling/mac-mouse-fix/pull/1862) | Rotate/zoom drag effects | Defer to WP6; add isolated gesture tests first |
| [#1861](https://github.com/noah-nuebling/mac-mouse-fix/pull/1861) | Resize window scroll effect | Defer to WP6; app compatibility and cancellation required |
| [#1860](https://github.com/noah-nuebling/mac-mouse-fix/pull/1860) | Move window drag effect | Defer to WP6; avoid mixing with Dock gesture work |
| [#1859](https://github.com/noah-nuebling/mac-mouse-fix/pull/1859) | Toggle Mac Mouse Fix action | Reimplement after a tested kill-switch/state model |
| [#1858](https://github.com/noah-nuebling/mac-mouse-fix/pull/1858) | Stop Scroll action | Reimplement after Scroll state-reset tests |
| [#1857](https://github.com/noah-nuebling/mac-mouse-fix/pull/1857) | Arrow-key timeline scroll | Defer; app-specific behavior and focus safety needed |
| [#1856](https://github.com/noah-nuebling/mac-mouse-fix/pull/1856) | Logitech ReprogControlsV4 | Reject the fixed-index/global-response implementation; retain protocol ideas for WP4 fixtures |
| [#1855](https://github.com/noah-nuebling/mac-mouse-fix/pull/1855) | Brightness/volume | Defer; private DisplayServices/DDC/OSD APIs need explicit compatibility policy |
| [#1854](https://github.com/noah-nuebling/mac-mouse-fix/pull/1854) | Momentum arrest | Defer to WP6; test against current scroll math and cancellation |
| [#1836](https://github.com/noah-nuebling/mac-mouse-fix/pull/1836) | Simplified Chinese translation | Adopt/cherry-pick as an isolated P2 change after verifying the current catalog |
| [#1814](https://github.com/noah-nuebling/mac-mouse-fix/pull/1814) | DMG workflow from upstream assets | Reimplement with pinned actions/tools, provenance, permissions, and this fork’s signing/notarization policy |
| [#1803](https://github.com/noah-nuebling/mac-mouse-fix/pull/1803) | Separate axis reverse controls | Adapted in `codex/remediation-axis-direction-p1` with a 27→28 migration, independent runtime/UI settings, and deterministic selector tests; do not cherry-pick the upstream patch wholesale |
| [#1779](https://github.com/noah-nuebling/mac-mouse-fix/pull/1779) | Universal Control | Reproduce with current synthetic/KVM changes; do not trust the unverified branch |
| [#1739](https://github.com/noah-nuebling/mac-mouse-fix/pull/1739) | Directional drag media/volume | Defer; author describes it as AI-assisted and unverified |
| [#1710](https://github.com/noah-nuebling/mac-mouse-fix/pull/1710) | HID++ via hidapi | Reject/close as unsafe/obsolete; retain protocol knowledge and the post-sleep failure evidence |

Most open PRs have no meaningful review discussion or CI evidence. The exceptions reinforce the dispositions: comments on #1875 describe the loss of continuous gesture behavior, #1779 contains “not works”/verification concerns, and #1710/#1856/#1938 show competing HID++ approaches rather than a settled design. The API audit found no check-runs on any of the 27 open PR heads, so author-reported validation is not a release gate.

## 6. Relevant closed PRs and historical decisions

- [#1979](https://github.com/noah-nuebling/mac-mouse-fix/pull/1979) is the user’s own compatibility PR. It is not upstream backlog and must not be modified, closed, or used as evidence that this plan’s work is complete.
- [#1920](https://github.com/noah-nuebling/mac-mouse-fix/pull/1920) is strong prior art for `SLEventSetIOHIDEvent` and an out-of-process macOS 27 test, but its fallback to hard-coded offsets on symbol failure must be improved to fail closed.
- [#1848](https://github.com/noah-nuebling/mac-mouse-fix/pull/1848) and [#1823](https://github.com/noah-nuebling/mac-mouse-fix/pull/1823) are earlier ReprogControlsV4 work; compare them with #1856 and #1938 rather than maintaining duplicate protocol implementations.
- [#1852](https://github.com/noah-nuebling/mac-mouse-fix/pull/1852) and [#1853](https://github.com/noah-nuebling/mac-mouse-fix/pull/1853) are earlier momentum/brightness work and should not be resurrected as bundles.
- [#1592](https://github.com/noah-nuebling/mac-mouse-fix/pull/1592) contains a potentially useful keyboard-hold synchronization idea, but it is a later action/hold candidate.
- The remaining 24 closed-unmerged PRs are stale translations, dependency changes, old compatibility attempts, or superseded experiments. Merged PRs are already part of the code baseline and need no remediation unless a regression is found.

## 7. Issue-cluster remediation ledger

The following canonical clusters cover the recurring themes found across the full issue set. Individual issues retain their own evidence and are linked to the cluster in the eventual ledger.

| Cluster | Representative issue family | Plan |
|---|---|---|
| Golden Gate Dock swipe | #1871, #1873, #1876, #1878, #1882, #1887, #1891, #1892, #1919, #1931, #1935, #1943, #1945, #1947, #1954, #1961, #1967, #1974, #1978 | WP1; consolidate duplicates after the bridge fix is testable |
| Helper crash/disabled state | #1909, #1923, #1926, plus `Disabled On Restart/Intermittently` | WP2; reproduce separately from gesture failures |
| Scroll crashes/jerk/dead scroll | #875, #988, #1081, #1103, #1106, #1147, #1915, #1922 | WP2/WP3; preserve logs and app/device combinations |
| Logitech buttons and DPI | #110, #226, #253, #316, #334, #335, #354, #356, #391, #435, #450, #498, #520, #555, #578, #649, #666, #772, #775, #847, #1154, #1277, #1505, #1508, #1932 | WP4; use protocol fixtures and separate ordinary capture from reprogramming |
| Middle-drag incompatibility | #58, #141, #179, #209, #216, #231, #291, #292, #294, #311, #322, #340, #349, #407, #451, #458, #538, #543, #598, #609, #621, #632, #682, #767 | WP3/WP6; classify app-specific versus global state-machine failures |
| Tilt-wheel mapping | #86, #158, #163, #207, #272, #328, #379, #387, #405, #446, #465, #483, #484, #528, #601, #614, #618, #630, #699, #706, #790, #1156 | WP4/WP6; capture report mapping before adding UI options |
| Per-app disable/settings/profiles | #107, #355, #361, #396, #407, #439, #598, #613, #621, #650, #671, #690, #695, #763, #762, #788, #794, #859, #892, #973, #1082, #1095, #1100, #1130, #1211, #1314, #1332, #1362, #1500, #1921, #1927, #1953, #1966, #1971 | WP5; reconcile with current fork feature work |
| Axis direction/speed/feel | #14, #115, #254, #278, #403, #409, #460, #482, #517, #519, #527, #533, #542, #564, #655, #734, #753, #1131, #1512, #1753, #1893, #1922, #1956 | WP3/WP5; #14 may be obsolete after Sonoma, but verify before closure |
| Hold/click/drag timing | #157, #213, #220, #295, #301, #303, #390, #398, #399, #573, #633, #683, #689, #708, #1903, #1907, #1911, #1929, #1933, #1964, #1970 | WP6; formalize gesture state transitions and cancellation |
| Universal Control/remote/iPhone Mirroring | #277, #365, #526, #554, #765, #1015, #1128, #1146, #1148, #1153, #1235, #1481, #1779, #1952 | WP3; test virtual-device identity and handoff |
| Coexistence and virtual display/input | #990, #1015, #1141, #1239, #277, #365 | WP3; preserve the distinction between an unsupported source and a broken helper state |
| Alternative Space switching | #90, #284, #352, #446, #1875 | WP1; only expose a discrete fallback if the user opts in or the continuous path is unavailable |
| Licensing/activation and persistence | #1939, #1941, #1957, #1959, #1972, #1975 | WP2/WP7; distinguish keychain/storage failure from license-server behavior |
| Translation/UI/low-information | #265, #1638, #1958, #1963, #1968, #1973, #1976 and older language PRs | P2/P3; resolve in isolated changes with current-version verification; do not ignore high-discussion localization reports |

For every issue in a cluster, the response template should record: current reproduction status, affected OS/build, device and connection mode, target app, current fork commit, logs or crash signature, duplicate/canonical issue, planned work package, and the test that will close it. A title-only search is not sufficient for a final closure.

## 8. Test and observability matrix

### Operating systems and environments

- macOS 26.x, including the 26.5/26.6 reports, to prevent a Golden Gate fix from regressing Tahoe behavior.
- macOS 27 beta/current build, with every compatibility result recording the exact build number.
- Apple silicon and Intel where available; at minimum, ensure private API and pointer-authentication failures are not architecture-specific.
- Clean Accessibility/TCC state and an upgraded installation with existing preferences, license, and helper registration.

### Devices and input modes

- Generic USB/Bluetooth mouse and trackpad simulation, including a real zero-sender source if one is available.
- Logitech M650/L, MX Master 3S, Lift, M720, Logi Bolt, and Unifying receiver where available.
- Razer Basilisk V3 X, Attack Shark X11, high-polling-rate devices, and software KVM/virtual mouse events.
- Universal Control, iPhone Mirroring, Remote Desktop, and a disconnected/reconnected device.

### Interaction matrix

- Ordinary left/right/middle/side buttons; click, hold, click-drag, click-scroll, and release.
- Smooth vertical/horizontal scroll, acceleration/speed, inversion, low smoothness, zero delta, momentum, and stop-scroll.
- Dock swipe continuous motion, reversal, low/high release velocity, natural/inverted direction, multiple displays, display changes, Spaces, Mission Control, Show Desktop, Launchpad, and move-between-spaces.
- App switches during a gesture, helper restart, sleep/wake, Accessibility revoke, fast user switching, device hot-unplug, no-device startup, delayed HID-device discovery, and login launch.

### Target applications

Finder, Mission Control, Safari, Chrome/Google Maps, Firefox, Preview, a Java/Electron application, iPhone Mirroring, a Remote Desktop client, and at least one full-screen application.

### Required evidence

- No crash, dead tap, duplicate event, stuck transition, rebound, or unexplained input loss.
- Structured logs for tap creation/enable failures, symbol lookup, OS path selection, device connection state, and helper retry state.
- Unit/fixture coverage for event payload and gesture state math; manual UI coverage for Dock behavior and Accessibility/TCC.
- A before/after result attached to the relevant issue cluster, not only a green build.

## 9. First execution sequence

1. Preserve the current branch and feature work; record `git status`, commit, SDK, Xcode, and build commands.
2. Build App and Helper from the current fork in Debug and Release and record the baseline matrix.
3. Reproduce one Dock-swipe failure and the #1926 event-tap failure signature on the same OS build if possible.
4. Add the runtime SkyLight setter path and an explicit macOS 27 fail-closed branch.
5. Add payload/ownership/velocity tests and run the Dock-swipe harness.
6. Harden event-tap null checks and lifecycle serialization across all helper tap owners.
7. Re-run scroll, synthetic KVM, high-polling, browser, and app-switch regressions, preserving the fork’s existing fixes.
8. Publish a small compatibility PR/patch with the test matrix and links to the canonical issue cluster.
9. Start the device protocol comparison using virtual HID++ fixtures, not a large hardware-support merge.
10. Reconcile and finish the current per-app/trackpad configuration work, then compare its data model with the requirements extracted from #1865.

## 10. Definition of done

The revival is ready for a public fork release and an upstream handoff when:

- App and Helper build from a clean checkout in the declared configurations, including Debug and Release signing/entitlement checks.
- macOS 26 and 27 core input paths pass the matrix, including Dock swipes and helper restart/permission scenarios.
- No event tap is enabled or queried after failed creation or teardown.
- The macOS 27 bridge has a runtime API path, a safe missing-symbol behavior, and a documented legacy path for older systems.
- Existing fork changes and the other chat’s feature changes have explicit regression results.
- Each active P0 issue has a test result or a documented external blocker; duplicate reports point to canonical issues.
- The first upstream PR is narrow, has no generated artifacts or unrelated features, and explains private API risk, fallback behavior, and tested OS builds.

## 11. Reproducible inventory commands and source links

The audit can be refreshed without relying on a browser session:

```sh
gh api repos/noah-nuebling/mac-mouse-fix/issues --paginate -f state=open -f per_page=100
gh api repos/noah-nuebling/mac-mouse-fix/pulls --paginate -f state=open -f per_page=100
gh api repos/noah-nuebling/mac-mouse-fix/pulls --paginate -f state=all -f per_page=100
gh api repos/noah-nuebling/mac-mouse-fix/releases --paginate
gh api repos/noah-nuebling/mac-mouse-fix/commits --paginate -f per_page=100
```

Primary references:

- [Upstream repository](https://github.com/noah-nuebling/mac-mouse-fix)
- [June macOS 27 commit](https://github.com/noah-nuebling/mac-mouse-fix/commit/f92d2d53a0)
- [Dock-swipe issue cluster](https://github.com/noah-nuebling/mac-mouse-fix/issues/1931)
- [Helper/event-tap crash evidence](https://github.com/noah-nuebling/mac-mouse-fix/issues/1926)
- [Scroll regression evidence](https://github.com/noah-nuebling/mac-mouse-fix/issues/988)
- [Logitech button family](https://github.com/noah-nuebling/mac-mouse-fix/issues/847)
- [Per-app configuration family](https://github.com/noah-nuebling/mac-mouse-fix/issues/1130)
