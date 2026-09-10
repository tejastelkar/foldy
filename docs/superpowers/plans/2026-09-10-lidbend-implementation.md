# LidBend macOS App Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a native menu-bar macOS app that reads a compatible MacBook lid-angle sensor and renders a reversible live desktop fold effect as the lid closes.

**Architecture:** A small SwiftUI menu-bar shell coordinates protocol-backed sensor, capture, overlay, rendering, settings, and entitlement services. Pure angle mapping and HID report parsing stay independent of AppKit and Metal so safety behavior is exhaustively unit tested; unsupported hardware uses the same pipeline through a manual preview provider.

**Tech Stack:** Swift 6, SwiftUI, AppKit, IOKit HID, ScreenCaptureKit, Metal/MetalKit, ServiceManagement, XCTest, XcodeGen, macOS 14+

**Spec:** `docs/superpowers/specs/2026-09-10-lidbend-design.md`

## Global Constraints

- Target macOS 14 Sonoma or later and Apple silicon (`arm64`).
- Use only Apple frameworks; add no runtime third-party dependencies.
- Never claim affiliation with Apple, iPhone Duo, or the existing Bendy product.
- Never prevent system sleep or change lid/sleep behavior.
- Never persist or transmit captured frames, sensor readings, or analytics.
- Dismiss every overlay within one second after stale/invalid sensor data, capture failure, renderer failure, or app termination.
- Keep a manual preview available when the lid-angle sensor is unsupported.
- Production direct distribution uses Developer ID signing and notarization; credentials remain outside the repository.

## File Map

- `project.yml` — XcodeGen project, targets, deployment version, entitlements, and test configuration.
- `LidBend/App/LidBendApp.swift` — menu-bar app entry point and dependency construction.
- `LidBend/App/AppModel.swift` — main-actor UI state and commands.
- `LidBend/Domain/FoldState.swift` — normalized visual parameters.
- `LidBend/Domain/FoldStateMapper.swift` — angle-to-effect mapping and hysteresis.
- `LidBend/Sensor/LidAngleProviding.swift` — sensor stream abstraction.
- `LidBend/Sensor/AngleSmoother.swift` — noise reduction and stale-state detection.
- `LidBend/Sensor/HIDReportParser.swift` — pure three-byte feature-report decoder.
- `LidBend/Sensor/HIDAngleProvider.swift` — IOKit HID device discovery and polling.
- `LidBend/Sensor/PreviewAngleProvider.swift` — slider-driven unsupported-device source.
- `LidBend/Capture/ScreenCaptureServicing.swift` — capture abstraction and permission status.
- `LidBend/Capture/ScreenCaptureService.swift` — ScreenCaptureKit display stream.
- `LidBend/Rendering/FoldRenderParameters.swift` — GPU parameter layout.
- `LidBend/Rendering/FoldRenderer.swift` — Metal texture pipeline and failure reporting.
- `LidBend/Rendering/FoldShaders.metal` — perspective, crease, blur, shade, and dim shader.
- `LidBend/Overlay/OverlayCoordinating.swift` — overlay lifecycle abstraction.
- `LidBend/Overlay/OverlayCoordinator.swift` — click-through windows and fail-safe teardown.
- `LidBend/Overlay/FoldMetalView.swift` — MTKView bridge used by overlay windows.
- `LidBend/Settings/AppSettings.swift` — typed UserDefaults-backed preferences.
- `LidBend/Settings/LaunchAtLoginService.swift` — ServiceManagement wrapper.
- `LidBend/Entitlement/EntitlementStore.swift` — entitlement abstraction and state.
- `LidBend/Entitlement/LocalEntitlementStore.swift` — deterministic development unlock.
- `LidBend/Entitlement/DirectLicenseStore.swift` — signed license-file validation boundary.
- `LidBend/UI/MenuBarContentView.swift` — primary controls and status.
- `LidBend/UI/OnboardingView.swift` — first-run explanation, permission, compatibility.
- `LidBend/UI/PreviewView.swift` — angle slider and rendered demo.
- `LidBend/Resources/Assets.xcassets` — app accent and icon assets.
- `LidBend/LidBend.entitlements` — screen capture and hardened-runtime-compatible settings.
- `LidBendTests/*Tests.swift` — domain, parser, settings, entitlement, and safety tests.
- `scripts/make_app_icon.swift` — deterministic original icon generator.
- `scripts/package.sh` — Release archive export, DMG creation, and optional notarization.
- `Config/Secrets.example.xcconfig` — documented non-secret signing/license keys.
- `README.md` — setup, compatibility, privacy, build, signing, and release instructions.

---

### Task 1: Native Project and Menu-Bar Shell

**Files:**
- Create: `project.yml`
- Create: `LidBend/App/LidBendApp.swift`
- Create: `LidBend/App/AppModel.swift`
- Create: `LidBend/UI/MenuBarContentView.swift`
- Create: `LidBend/Resources/Assets.xcassets/Contents.json`
- Create: `LidBend/Resources/Assets.xcassets/AccentColor.colorset/Contents.json`
- Create: `LidBend/LidBend.entitlements`
- Test: `LidBendTests/AppModelTests.swift`

**Interfaces:**
- Consumes: none.
- Produces: `@MainActor final class AppModel: ObservableObject`, `func setEnabled(_ enabled: Bool)`, and the `LidBend` app target used by all later tasks.

- [ ] **Step 1: Select Xcode and install XcodeGen**

Run:

```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -license accept
brew install xcodegen
```

Expected: `xcodebuild -version` prints the installed Xcode version and `xcodegen --version` succeeds.

- [ ] **Step 2: Write the failing app-state test**

Create `LidBendTests/AppModelTests.swift` with a main-actor test that constructs `AppModel()`, asserts `isEnabled == false`, calls `setEnabled(true)`, and asserts `isEnabled == true`.

- [ ] **Step 3: Create the project definition and shell**

Set organization identifier `com.lidbend`, product bundle identifier `com.lidbend.app`, deployment target `14.0`, Swift version `6.0`, app category `public.app-category.entertainment`, `LSUIElement = true`, and test host `LidBend`. Implement `LidBendApp` with `MenuBarExtra("LidBend", systemImage: "macbook")` and `MenuBarContentView` containing the enable toggle and a Quit button.

- [ ] **Step 4: Generate and test the project**

Run:

```bash
xcodegen generate
xcodebuild test -project LidBend.xcodeproj -scheme LidBend -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO
```

Expected: the project generates and `AppModelTests` passes.

- [ ] **Step 5: Commit**

```bash
git add project.yml LidBend LidBendTests/AppModelTests.swift
git commit -m "feat: scaffold LidBend menu bar app"
```

### Task 2: Fold Mapping, Smoothing, and Safety State

**Files:**
- Create: `LidBend/Domain/FoldState.swift`
- Create: `LidBend/Domain/FoldStateMapper.swift`
- Create: `LidBend/Sensor/AngleSmoother.swift`
- Test: `LidBendTests/FoldStateMapperTests.swift`
- Test: `LidBendTests/AngleSmootherTests.swift`

**Interfaces:**
- Consumes: none.
- Produces: `struct FoldState: Equatable, Sendable`, `struct FoldStateMapper`, `func state(for angle: Double, previousVisible: Bool) -> FoldState`, `struct AngleSmoother`, `mutating func ingest(angle: Double, at time: TimeInterval) -> Double?`, and `func isStale(at time: TimeInterval) -> Bool`.

- [ ] **Step 1: Write failing mapping tests**

Test exact states for `openAngle: 110`, `closedAngle: 12`: 120° yields progress 0 and invisible; 61° yields progress 0.5; 12° yields progress 1; NaN yields invisible. Test 3° hysteresis so a visible effect remains visible until angle exceeds 113°.

- [ ] **Step 2: Run the mapper tests and confirm failure**

Run: `xcodebuild test -project LidBend.xcodeproj -scheme LidBend -destination 'platform=macOS' -only-testing:LidBendTests/FoldStateMapperTests CODE_SIGNING_ALLOWED=NO`

Expected: FAIL because `FoldStateMapper` does not exist.

- [ ] **Step 3: Implement deterministic visual mapping**

Define `FoldState(progress: CGFloat, perspective: CGFloat, crease: CGFloat, blurRadius: CGFloat, dimAmount: CGFloat, isVisible: Bool)`. Clamp progress to `0...1`; derive perspective as `0.08 * progress`, crease as `smoothstep(0.15, 0.85, progress)`, blur radius as `12 * progress * progress`, and dim amount as `0.75 * smoothstep(0.55, 1, progress)`.

- [ ] **Step 4: Write failing smoother tests**

Verify a five-sample exponential smoother with `alpha = 0.25` reduces a 100° to 60° jump to 90°, rejects values outside `0...180`, and reports stale exactly when more than `0.75` seconds elapsed since its last valid sample.

- [ ] **Step 5: Implement and run all domain tests**

Run: `xcodebuild test -project LidBend.xcodeproj -scheme LidBend -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO`

Expected: all mapping and smoothing tests pass.

- [ ] **Step 6: Commit**

```bash
git add LidBend/Domain LidBend/Sensor/AngleSmoother.swift LidBendTests
git commit -m "feat: map lid angles to safe fold states"
```

### Task 3: Lid Sensor and Manual Preview Provider

**Files:**
- Create: `LidBend/Sensor/LidAngleProviding.swift`
- Create: `LidBend/Sensor/HIDReportParser.swift`
- Create: `LidBend/Sensor/HIDAngleProvider.swift`
- Create: `LidBend/Sensor/PreviewAngleProvider.swift`
- Test: `LidBendTests/HIDReportParserTests.swift`
- Test: `LidBendTests/PreviewAngleProviderTests.swift`

**Interfaces:**
- Consumes: `AngleSmoother` from Task 2.
- Produces: `protocol LidAngleProviding: AnyObject`, `var availability: SensorAvailability { get }`, `var angles: AsyncStream<Double> { get }`, `func start() throws`, `func stop()`, `enum SensorAvailability`, and `static func HIDReportParser.angle(from bytes: [UInt8]) -> Double?`.

- [ ] **Step 1: Write failing HID decoding tests**

Assert `[0x01, 0x5A, 0x00]` decodes to 90°, `[0x01, 0xB4, 0x00]` to 180°, incorrect report IDs and buffers shorter than three bytes return nil, and decoded values above 180 return nil.

- [ ] **Step 2: Implement the parser and protocol**

Decode report ID 1 as an unsigned little-endian 16-bit degree value. Define availability cases `.unknown`, `.available`, and `.unavailable(reason: String)`.

- [ ] **Step 3: Implement hardware discovery and polling**

Use `IOHIDManagerCreate`, match Apple vendor `0x05AC`, product `0x8104`, sensor usage page `0x20`, and orientation usage `0x8A`. Open the matched device, request feature report ID 1 on a dedicated serial queue at 60 Hz, parse and smooth valid readings, and finish the async stream on `stop` or device removal. Do not use private framework symbols or disable sleep.

- [ ] **Step 4: Write and pass manual-provider tests**

Verify `PreviewAngleProvider.send(angle:)` yields values while started, clamps values to `0...180`, and finishes its stream when stopped.

- [ ] **Step 5: Run tests and a diagnostic build**

Run: `xcodebuild test -project LidBend.xcodeproj -scheme LidBend -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO`

Expected: parser/provider tests pass and IOKit code compiles on arm64 macOS.

- [ ] **Step 6: Commit**

```bash
git add LidBend/Sensor LidBendTests
git commit -m "feat: read MacBook lid angle with manual fallback"
```

### Task 4: Metal Fold Renderer and Preview

**Files:**
- Create: `LidBend/Rendering/FoldRenderParameters.swift`
- Create: `LidBend/Rendering/FoldRenderer.swift`
- Create: `LidBend/Rendering/FoldShaders.metal`
- Create: `LidBend/Overlay/FoldMetalView.swift`
- Create: `LidBend/UI/PreviewView.swift`
- Test: `LidBendTests/FoldRenderParametersTests.swift`

**Interfaces:**
- Consumes: `FoldState` and `FoldStateMapper` from Task 2; `PreviewAngleProvider` from Task 3.
- Produces: `struct FoldRenderParameters`, `init(state: FoldState, viewportSize: CGSize)`, `final class FoldRenderer: NSObject, MTKViewDelegate`, and `FoldMetalView: NSViewRepresentable`.

- [ ] **Step 1: Write failing GPU-parameter tests**

Assert a hidden state produces identity scale, zero crease/blur/dim, finite values for a zero-sized viewport, and a fully closed state clamps every normalized parameter to `0...1`.

- [ ] **Step 2: Implement the parameter bridge**

Keep the Swift/Metal memory layout to eight aligned `Float` values: progress, perspective, crease, blur, dim, aspectRatio, padding0, padding1. Sanitize non-finite inputs before upload.

- [ ] **Step 3: Implement the shader**

Render a full-screen quad. Compress vertical UV coordinates toward the bottom hinge using perspective; offset horizontal UVs around the center crease; sample nine taps along the vertical axis for progressive blur; add a narrow center highlight with adjacent shadow; dim toward black after 55% progress. Clamp UVs so no captured pixels wrap at edges.

- [ ] **Step 4: Implement the renderer and SwiftUI preview**

Create a Metal device, command queue, render pipeline, and a generated checkerboard fallback texture. `PreviewView` displays `FoldMetalView` plus a 0°–120° slider routed through `FoldStateMapper`, allowing full visual QA with no compatible sensor.

- [ ] **Step 5: Test and capture a preview screenshot**

Run tests, then launch the unsigned Debug app and use the preview slider at 60°.

Expected: tests pass; the preview shows perspective compression, crease, blur, and dimming without a crash or black frame.

- [ ] **Step 6: Commit**

```bash
git add LidBend/Rendering LidBend/Overlay/FoldMetalView.swift LidBend/UI/PreviewView.swift LidBendTests
git commit -m "feat: render interactive Metal fold effect"
```

### Task 5: Screen Capture and Fail-Safe Desktop Overlays

**Files:**
- Create: `LidBend/Capture/ScreenCaptureServicing.swift`
- Create: `LidBend/Capture/ScreenCaptureService.swift`
- Create: `LidBend/Overlay/OverlayCoordinating.swift`
- Create: `LidBend/Overlay/OverlayCoordinator.swift`
- Modify: `LidBend/Rendering/FoldRenderer.swift`
- Modify: `LidBend/App/AppModel.swift`
- Test: `LidBendTests/OverlaySafetyTests.swift`

**Interfaces:**
- Consumes: `FoldState`, `FoldRenderer`, and `LidAngleProviding`.
- Produces: `protocol ScreenCaptureServicing`, `func start(displayID: CGDirectDisplayID) async throws`, `func stop() async`, `var frames: AsyncStream<CVPixelBuffer> { get }`, `protocol OverlayCoordinating`, `func apply(_ state: FoldState) async`, and `func dismissAll() async`.

- [ ] **Step 1: Write failing safety tests with fakes**

Use fake sensor, capture, and overlay implementations. Verify hidden states do not start capture, visible states create overlays, returning to progress zero dismisses them, stale data dismisses within one second using an injectable clock, and capture/renderer errors call `dismissAll()`.

- [ ] **Step 2: Implement ScreenCaptureKit streaming**

Request shareable content, select the matching display, exclude LidBend-owned windows, configure `SCStreamConfiguration` for native pixel size and 30 FPS, and yield only complete `.screen` sample buffers. Convert permission denial and stopped-stream errors into typed errors and finish the frame stream.

- [ ] **Step 3: Implement overlay windows**

Create one borderless `NSPanel` per active display with `.screenSaver` level, transparent background, `ignoresMouseEvents = true`, `collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]`, and an embedded `FoldMetalView`. Never make overlays key or main. Observe display reconfiguration and app termination to call `dismissAll()`.

- [ ] **Step 4: Connect live frames to Metal**

Use `CVMetalTextureCacheCreateTextureFromImage` to update the renderer texture without copying pixels to disk. Serialize lifecycle changes on the main actor and rendering work on the MTKView render loop.

- [ ] **Step 5: Connect AppModel orchestration and fail-safe timer**

When enabled, start the selected angle provider and consume its stream. Map samples into fold states, apply visible states, and tear down at zero. Check staleness every 250 ms; dismiss after 750 ms without a valid sample. Disable and dismiss on Escape, app termination, stream completion, or any thrown error.

- [ ] **Step 6: Run safety tests**

Run: `xcodebuild test -project LidBend.xcodeproj -scheme LidBend -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO`

Expected: all safety tests pass, including stale-stream and capture-error teardown.

- [ ] **Step 7: Commit**

```bash
git add LidBend/Capture LidBend/Overlay LidBend/Rendering/FoldRenderer.swift LidBend/App/AppModel.swift LidBendTests
git commit -m "feat: bend the live desktop with safe overlays"
```

### Task 6: Onboarding, Preferences, Login, and Entitlement Boundary

**Files:**
- Create: `LidBend/Settings/AppSettings.swift`
- Create: `LidBend/Settings/LaunchAtLoginService.swift`
- Create: `LidBend/Entitlement/EntitlementStore.swift`
- Create: `LidBend/Entitlement/LocalEntitlementStore.swift`
- Create: `LidBend/Entitlement/DirectLicenseStore.swift`
- Create: `LidBend/UI/OnboardingView.swift`
- Modify: `LidBend/UI/MenuBarContentView.swift`
- Modify: `LidBend/App/AppModel.swift`
- Test: `LidBendTests/AppSettingsTests.swift`
- Test: `LidBendTests/EntitlementStoreTests.swift`

**Interfaces:**
- Consumes: compatibility and error state from `AppModel` and `LidAngleProviding`.
- Produces: `@MainActor final class AppSettings`, `protocol EntitlementStore`, `var state: EntitlementState { get }`, `func purchase() async throws`, `func restore() async throws`, and `enum EntitlementState` with `.locked`, `.unlocked`, and `.checking`.

- [ ] **Step 1: Write failing settings and entitlement tests**

Verify defaults are effect enabled false, start angle 110°, intensity 1.0, launch at login false, onboarding incomplete. Verify a development entitlement unlocks only when the `LIDBEND_DEVELOPMENT_UNLOCK` build setting is true. Verify an invalid direct license remains locked.

- [ ] **Step 2: Implement preferences and login management**

Store only typed scalar preferences in a dedicated UserDefaults suite. Use `SMAppService.mainApp.register()` and `.unregister()` for launch at login, surfacing registration errors without changing the stored UI state optimistically.

- [ ] **Step 3: Implement the entitlement boundary**

Define a signed license payload containing license ID, product ID `lidbend-lifetime`, issued date, and Ed25519 signature. Validate using CryptoKit against a base64 public key from build settings. `purchase()` opens the configured HTTPS checkout URL; `restore()` opens the provider customer portal. Development builds use `LocalEntitlementStore` and never embed a private key.

- [ ] **Step 4: Build onboarding and complete menu content**

Onboarding has three pages: effect explanation, Screen Recording permission with `CGRequestScreenCaptureAccess()`, and compatibility/preview. The menu displays live angle, compatibility, enable toggle, intensity slider, preview, launch at login, purchase/restore when locked, Screen Recording settings link when denied, About, and Quit.

- [ ] **Step 5: Run tests and manually verify denied permission**

Expected: denying Screen Recording displays instructions and no full-screen overlay; the preview still works; local Debug unlock enables the effect.

- [ ] **Step 6: Commit**

```bash
git add LidBend/Settings LidBend/Entitlement LidBend/UI LidBend/App/AppModel.swift LidBendTests
git commit -m "feat: add onboarding settings and lifetime unlock"
```

### Task 7: Original Icon, Packaging, Documentation, and Release Verification

**Files:**
- Create: `scripts/make_app_icon.swift`
- Create: `scripts/package.sh`
- Create: `Config/Secrets.example.xcconfig`
- Create: `README.md`
- Modify: `LidBend/Resources/Assets.xcassets/AppIcon.appiconset/Contents.json`
- Create: generated icon PNGs under `LidBend/Resources/Assets.xcassets/AppIcon.appiconset/`

**Interfaces:**
- Consumes: the complete `LidBend` target.
- Produces: an unsigned local `LidBend.app`, a Release archive/export path, and an optional notarized `LidBend.dmg` when valid owner credentials are supplied.

- [ ] **Step 1: Generate an original app icon**

Use a Swift CoreGraphics script to draw a midnight-blue rounded square containing two cyan-to-violet panels bending around a bright vertical hinge. Render 16, 32, 64, 128, 256, 512, and 1024 pixel PNGs with `CGImageDestination`; do not use Apple logos, device silhouettes, SF Symbols, or Bendy artwork.

- [ ] **Step 2: Add deterministic packaging**

`scripts/package.sh` must run tests, archive with `xcodebuild archive`, export a Developer ID application when `DEVELOPMENT_TEAM` and `CODE_SIGN_IDENTITY` are set, create a compressed DMG with `hdiutil`, submit with `xcrun notarytool submit --wait` when `NOTARY_PROFILE` is set, and staple with `xcrun stapler staple`. With no credentials, it must create and report the unsigned local `.app` instead of failing.

- [ ] **Step 3: Document setup and privacy**

Document Xcode selection, XcodeGen generation, supported Mac models, Screen Recording permission, manual preview, sensor limitations, local-only data handling, development unlock, payment-provider build keys, Developer ID signing, notarization, and the fact that the app does not alter sleep behavior.

- [ ] **Step 4: Run the complete verification suite**

Run:

```bash
xcodegen generate
xcodebuild clean test -project LidBend.xcodeproj -scheme LidBend -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO
xcodebuild build -project LidBend.xcodeproj -scheme LidBend -configuration Release -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO
./scripts/package.sh
git status --short
```

Expected: all tests pass, Release build succeeds, packaging emits an app or signed DMG according to available credentials, and only expected generated/output files remain untracked.

- [ ] **Step 5: Inspect the built app**

Launch the app, confirm menu-bar UI and manual preview, drag through fully open/midpoint/near-closed states, press Escape during preview, deny Screen Recording once, and confirm no overlay survives quit. On compatible hardware, close and reopen the lid through the configured threshold and confirm the animation reverses smoothly.

- [ ] **Step 6: Commit**

```bash
git add scripts Config README.md LidBend/Resources
git commit -m "build: package and document LidBend release"
```

## Owner-Supplied Release Inputs

The development build, tests, unsigned `.app`, icon, and packaging workflow require no user secrets. A sellable notarized build additionally requires:

- Apple Developer Team ID and an installed Developer ID Application certificate.
- A notarization keychain profile created locally with `notarytool store-credentials`.
- A payment-provider checkout URL, customer-portal URL, product identifier, and Ed25519 public verification key.

Private signing keys, API credentials, and payment-provider secrets must never be pasted into source files or committed.
