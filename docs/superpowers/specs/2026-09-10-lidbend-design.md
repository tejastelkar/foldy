# LidBend macOS App Design

## Product

LidBend is a lightweight macOS menu-bar app that makes the visible desktop appear to bend, tilt, blur, darken, and settle as a compatible MacBook lid closes. It is a visual novelty intended for short social videos and everyday delight. The first release is a macOS-only MVP sold as a $1.99 lifetime unlock.

The app must use its own name, artwork, and copy. It will not claim affiliation with Apple, iPhone Duo, or the existing Bendy product.

## Supported Systems

- macOS 14 Sonoma or later.
- Apple-silicon MacBooks that expose the lid-angle HID sensor, initially targeting 14-inch and 16-inch MacBook Pro and MacBook Air M2 or later.
- Unsupported Macs remain usable through an on-screen drag-based demo, but automatic lid tracking is clearly marked unavailable.
- The sensor reader uses public IOKit functions to read an undocumented Apple HID report. This implementation is isolated behind a protocol because its report format or availability may change.

## User Experience

On first launch, a three-step onboarding explains the effect, requests Screen Recording permission, and checks sensor compatibility. The user can preview the effect using a slider before enabling it.

When enabled, moving the lid below a configurable start angle creates a full-screen, click-through overlay on each active display. The overlay shows a current desktop frame and progressively applies perspective compression, a center crease, edge shading, blur, and dimming based on normalized lid angle. Opening the lid reverses the animation. Near closure, the overlay becomes black before macOS sleeps the display.

The menu-bar popover contains an enable switch, live lid angle, effect intensity, preview button, launch-at-login option, compatibility status, and purchase/restore controls. Escape immediately dismisses a preview. A fail-safe timeout removes any overlay if sensor updates stop.

## Architecture

The SwiftUI app owns five focused services:

1. `LidAngleProviding` reads and smooths hinge measurements. `HIDAngleProvider` implements compatible hardware access, while `PreviewAngleProvider` supplies slider-driven values for previews and unsupported Macs.
2. `ScreenCaptureService` uses ScreenCaptureKit to obtain display frames after Screen Recording permission is granted.
3. `FoldRenderer` uses Metal to render a captured texture through a perspective fold shader. It converts lid angle into fold progress and exposes deterministic parameters that can be unit tested without a GPU.
4. `OverlayCoordinator` creates borderless, transparent, click-through windows at screen-saver level and removes them on recovery, timeout, or app exit.
5. `EntitlementStore` exposes locked, purchased, and trial states. Development builds use a deterministic local test entitlement. The direct release connects the same interface to a `$1.99` lifetime license from the selected payment provider. A future Mac App Store build can supply a separate StoreKit 2 implementation without changing the UI.

The menu-bar interface and onboarding depend on these protocols rather than hardware or payment implementations directly.

## Data Flow

The sensor publishes smoothed angle samples at up to 60 Hz. A pure `FoldStateMapper` converts the configured open and closed thresholds into progress from zero to one. The coordinator starts capture only when the effect becomes visible. Captured frames and fold parameters are passed to the Metal renderer, whose output fills the overlay. When progress returns to zero, the overlay and capture session are torn down.

User preferences are stored in `UserDefaults`. No screenshots, sensor readings, analytics, or personal data leave the Mac.

## Error Handling and Safety

- Missing sensor: show compatibility guidance and keep manual preview available.
- Screen Recording denied: deep-link to System Settings and never display a blank blocking overlay.
- Capture interruption or display change: tear down and recreate affected overlays.
- Stale or invalid sensor values: dismiss overlays within one second.
- Renderer failure: dismiss overlays and show a non-blocking menu-bar error.
- The app never prevents system sleep or changes lid/sleep behavior.

## Distribution

The preferred release is a Developer ID-signed, hardened-runtime, notarized DMG distributed directly. This avoids depending on Mac App Store acceptance of undocumented sensor access. The code remains sandbox-conscious, but the initial direct build does not depend on App Sandbox restrictions.

The repository will include build instructions, privacy copy, compatibility notes, and an example secrets configuration containing no credentials. Shipping a paid notarized build requires the owner's Apple Developer signing identity and payment-provider account; development and unsigned local builds do not.

## Testing and Acceptance

- Unit tests cover angle normalization, smoothing, hysteresis, fail-safe transitions, and entitlement gating.
- Renderer parameter tests cover fully open, midpoint, near-closed, and invalid readings.
- A manual preview mode allows visual testing without supported hardware.
- The project must compile with the installed Xcode, and all automated tests must pass.
- On compatible hardware, closing the lid must drive a reversible animation with no user input and opening it must restore the unobstructed desktop.
- Denying Screen Recording permission or losing sensor input must never leave the screen covered.

## MVP Exclusions

The first version does not modify the real macOS desktop, record or export social video, support Intel Macs, synchronize settings, collect analytics, or include subscriptions. Those can follow only after the core effect is validated.
