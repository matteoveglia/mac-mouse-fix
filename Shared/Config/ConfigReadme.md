#  Notes on config

- When you copy over a real `config.plist` to `default_config.plist`, make sure to reset the `State` values
- `Remaps` in `default_config.plist` should be empty.
    - It will be programmatically replaced with one of the `defaultRemaps`


## Version Changes

Here, we document, what exactly changed as we increased the configVersion

**26 -> 27**

- Existing canonical policies containing executable, wrapper, or process-name selectors now open in the explicit `advanced` Trackpad Simulation scope.
- Legacy scope changes continue to preserve those advanced selectors for later reuse, while the helper evaluates only the selected scope.

**25 -> 26**

- Added the canonical `Scroll.applicationPolicy` snapshot used by the helper at scroll-series boundaries.
- Migrated the existing `all`/`include`/`exclude` scope and bundle-ID list without removing those legacy keys from the current settings UI.
- Invalid explicitly stored legacy policy values migrate to a deny-by-default snapshot instead of enabling Trackpad Simulation globally.

**24 -> 25**

- Split the legacy shared `Scroll.smooth` and `Scroll.speed` values into vertical and horizontal settings, preserving the user's existing values for both axes.
- Added the `Scroll.trackpadSimulationScope` (`all`) and `Scroll.trackpadSimulationApps` (empty) defaults.
- Removed the experimental `Scroll.horizontalScale` setting, which was not included in the final scrolling implementation.

**21 -> 22**

- "License.trial.lastUseDate" is now stored in `SecureStorage` instead of config. 
    - This is to prevent bug where trial counter would go up too fast when the user switched between machines frequently (I think it resolves this) (See https://github.com/noah-nuebling/mac-mouse-fix/discussions/743#discussioncomment-8050398)
    - This should require any config repairing.


    Update: [Jun 7 2025] ... Oup we forgot to ever update this. It's probably better to keep comments like these local to the updating code. 
