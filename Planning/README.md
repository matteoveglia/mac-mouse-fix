# Mac Mouse Fix Revival — Planning Documents

Working documents for reviving Mac Mouse Fix on macOS Tahoe (26) and Golden Gate (27),
maintained in `matteoveglia/mac-mouse-fix` (fork of `noah-nuebling/mac-mouse-fix`).

**Created:** 2026-08-22 · **Status:** Planning plus compatibility implementation in progress

## Documents

| Doc | Purpose |
|---|---|
| [01-situation-assessment.md](01-situation-assessment.md) | Where things stand: upstream state, releases, fork state, local environment |
| [02-macos-compat.md](02-macos-compat.md) | Tahoe/Golden Gate compatibility matrix — what's broken, what's fixed, where |
| [03-backlog-triage.md](03-backlog-triage.md) | Triage of the 1185 open issues and 27 open PRs |
| [04-roadmap.md](04-roadmap.md) | Phased execution plan + immediate next actions |
| [05-upstream-remediation-plan.md](05-upstream-remediation-plan.md) | Full upstream issue/PR remediation plan, corrected technical baseline, and release gates |
| [test-matrix.md](test-matrix.md) | Current automated evidence and required physical-hardware regression checks |

## TL;DR

1. **Upstream is not fully abandoned but stalled.** Last real commits: 2026-06-22. Last release: 3.1.0 Beta 1 (updated Jan 2026).
2. **Upstream master contains an unreleased, incomplete Dock-swipe change** — commit `f92d2d53a` adds the HID payload path, but the macOS 27 event bridge still uses hard-coded offsets. See doc 05.
3. Therefore the fastest path to a working app on Golden Gate is: **build the current fork, verify the bridge and helper lifecycle, then upstream small tested fixes.**
4. Build, signing, and Accessibility/TCC state must be verified against the current machine and documented in the test matrix; older notes may be stale.
5. The issue tracker is noisy (1185 open issues) but the Golden Gate–critical subset is small and well understood (see doc 02).
