# Foldy Apple-style Settings redesign

## Goal

Turn the current menu-bar prototype into a cohesive Foldy-branded macOS app whose controls, settings hierarchy, visual language, and live preview feel native to the Apple ecosystem. Every appearance control must affect both the preview and the real lid-driven Metal effect.

## Product identity

- The only product name is **Foldy**.
- Rename the Xcode project, app target, test target, product, executable, bundle identifier, Swift app entry point, source folders, documentation, package names, and user-facing copy.
- Remove obsolete LidBend-branded files rather than keeping compatibility aliases.
- Remove the unused direct-payment and license scaffolding. Monetization is outside this release.
- Keep the existing original fold icon, regenerated and catalogued under Foldy naming.

## Visual system

Foldy uses native macOS controls and semantic materials instead of imitating a web application.

- Accent: Apple system blue, `#0A84FF` in dark appearance and the system accent equivalent in adaptive contexts.
- Surfaces: `windowBackgroundColor`, sidebar material, grouped control backgrounds, separators, and semantic label colors.
- Typography: San Francisco through SwiftUI system fonts, using native title, headline, body, caption, and monospaced-digit styles.
- Icons: SF Symbols only. Appearance uses `circle.lefthalf.filled`, General uses `gearshape.fill`, and About uses `info.circle.fill`.
- Layout: a 780 × 560 resizable Settings window with a 190-point sidebar and a single aligned detail column. Blue is reserved for selection, active controls, and status.
- Motion: only the live fold preview animates continuously. Settings navigation and controls use native SwiftUI behavior.

## Settings architecture

### General

- Enable Foldy.
- Launch at login.
- Play an opening sound when the desktop clears.
- Screen Recording permission status and a direct button to open the correct System Settings privacy pane.
- Sensor status and a concise compatibility message.

### Appearance

- A large live MacBook preview at the top.
- Angle slider showing the current or manually selected degree value.
- Follow Lid toggle. When enabled, the preview follows live sensor readings; when disabled, the slider controls it.
- Three selectable style cards:
  - **Silk:** balanced perspective, smooth blur, gentle shadow.
  - **Shade:** stronger perspective and shadow, restrained blur.
  - **Frost:** softer perspective, stronger variable blur, cool highlight.
- Independent sliders with percentages for Perspective, Variable Blur, and Shadow.
- Clear Angle control defining when the overlay fully disappears as the lid opens.
- Reset Appearance button restoring the documented defaults.

### About

- Foldy icon, product name, current bundle version, compatibility summary, and privacy statement.
- State clearly that desktop frames remain in memory and are not saved or transmitted.
- Link to the GitHub project for support and source information.

## Runtime data flow

`AppSettings` remains the persisted source of truth and gains typed appearance values: selected style, follow-lid state, perspective, variable blur, shadow, clear angle, and sound preference. A value-type appearance snapshot is passed into both preview and overlay rendering.

The HID provider publishes lid angles. `AppModel` maps those angles to fold progress and publishes the current angle. The Settings preview either consumes this live value or its manual slider value. `OverlayCoordinator` creates a Metal view for each screen and applies the same persisted appearance snapshot used by the preview.

Style presets provide initial tuning values but do not hide the advanced sliders. Selecting a style updates all three tuning controls; adjusting an individual slider preserves the selected style label while applying the custom value immediately.

## Renderer changes

Extend `FoldRenderParameters` with style and tuning values while keeping the layout GPU-safe and covered by tests. The shader will:

- scale perspective deformation from the Perspective slider;
- vary blur radius over fold depth from Variable Blur;
- deepen the crease, horizon, and surrounding shade from Shadow;
- add a restrained cool highlight for Frost;
- retain smooth clamping and full-screen safety behavior.

No control is decorative. Every setting must cause an observable parameter or runtime behavior change.

## Menu-bar experience

The compact menu remains the operational surface:

- Foldy identity and sensor status.
- Enable Foldy toggle.
- Open Settings command.
- Preview Effect command.
- Quit Foldy command.

Detailed sliders move out of the menu and into Settings to match normal macOS information hierarchy.

## Safety and privacy

- ScreenCaptureKit remains required because the real desktop pixels are rendered through Metal.
- Captured frames stay in memory and are excluded from analytics, storage, and networking.
- The overlay remains click-through and excluded from its own capture stream.
- Invalid or stale sensor readings dismiss every overlay within 750 milliseconds.
- Disabling Foldy, capture errors, application termination, and display changes must leave no blocking overlay behind.

## Migration

Existing preferences are read where their meaning remains compatible. New appearance preferences receive safe defaults. The product rename uses bundle identifier `com.foldy.app`; therefore macOS treats Foldy as a new app for privacy permission and launch-at-login registration.

The old generated project and old-named product artifacts are removed from the repository. A fresh `Foldy.xcodeproj` is generated from `project.yml`.

## Verification

- Unit tests cover defaults, persistence, style preset values, setting-to-render-parameter mapping, angle behavior, and reset behavior.
- Existing HID parsing, smoothing, fold mapping, and stale-overlay safety tests remain green under the renamed test module.
- Release build succeeds with no old product name in the current source tree.
- Visual inspection checks light and dark appearance, sidebar selection, all three style cards, slider updates, manual preview, and menu-bar labels.
- The packaged Foldy app passes code-signature verification and launches its Settings window.

## Acceptance criteria

- The app and repository contain no current `LidBend` branding or executable artifacts.
- Foldy displays a native Apple-style Settings window with General, Appearance, and About destinations.
- Silk, Shade, Frost, Perspective, Variable Blur, Shadow, Follow Lid, and manual angle controls all work.
- Preview and live overlay use the same settings.
- The app builds, tests, packages, and is committed and pushed on `main`.
