# Foldy Apple-style Settings Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. The user explicitly prohibited subagents. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship a fully Foldy-branded macOS menu-bar app with a native Apple-style Settings window and renderer-connected appearance controls.

**Architecture:** Persist typed appearance preferences in `AppSettings`, expose them as an immutable `FoldAppearance` snapshot, and pass that snapshot through preview and overlay views into Metal render parameters. Keep the HID-to-fold mapping and safety controller intact while renaming the app, targets, modules, packaging, and documentation from Foldy to Foldy.

**Tech Stack:** Swift 6, SwiftUI, AppKit, MetalKit, ScreenCaptureKit, IOKit HID, XCTest, XcodeGen.

**Spec:** `docs/superpowers/specs/2026-09-10-foldy-apple-settings-redesign.md`

## Global Constraints

- Work directly on `main`; do not create a branch or worktree.
- Do not dispatch subagents.
- The only current product name is Foldy and the bundle identifier is `com.foldy.app`.
- Remove unused payment and direct-license code.
- Use native semantic macOS surfaces, SF Pro, SF Symbols, and Apple system blue.
- Every appearance control must affect the preview and live Metal overlay.
- ScreenCaptureKit frames remain in memory and stale/invalid sensor input dismisses overlays within 750 milliseconds.

---

### Task 1: Typed appearance preferences

**Files:**
- Create: `Foldy/Settings/FoldAppearance.swift` (renamed with the source tree in Task 2)
- Modify: `Foldy/Settings/AppSettings.swift`
- Test: `FoldyTests/AppSettingsTests.swift`

**Interfaces:**
- Produces: `enum FoldStyle: String, CaseIterable, Codable, Sendable`
- Produces: `struct FoldAppearance: Equatable, Sendable`
- Produces: `AppSettings.appearance: FoldAppearance`
- Produces: `AppSettings.apply(style:)` and `AppSettings.resetAppearance()`

- [x] **Step 1: Write failing preference tests**

Add literal assertions that a fresh settings suite uses Silk, follows the lid, and yields perspective `1.0`, blur `0.65`, shadow `0.55`, and clear angle `135`. Add tests that selecting Shade writes its literal preset values and reset restores the defaults.

```swift
func testFreshInstallUsesSilkAppearanceDefaults() {
    let settings = AppSettings(defaults: defaults)
    XCTAssertEqual(settings.appearanceStyle, .silk)
    XCTAssertTrue(settings.followLid)
    XCTAssertEqual(settings.perspective, 1.0)
    XCTAssertEqual(settings.variableBlur, 0.65)
    XCTAssertEqual(settings.shadow, 0.55)
    XCTAssertEqual(settings.clearAngle, 135)
}
```

- [x] **Step 2: Run the focused tests and verify RED**

Run the existing `FoldyTests` target. The expected failure is missing `appearanceStyle`, `followLid`, `perspective`, `variableBlur`, `shadow`, and `clearAngle` members.

- [x] **Step 3: Implement the model and persisted settings**

Define the three styles and their presets:

```swift
enum FoldStyle: String, CaseIterable, Codable, Sendable {
    case silk, shade, frost
}

struct FoldAppearance: Equatable, Sendable {
    var style: FoldStyle
    var perspective: Double
    var variableBlur: Double
    var shadow: Double
}
```

Clamp persisted percentages to `0...1` and clear angle to `90...145`. `apply(style:)` must write preset values; `resetAppearance()` must restore the Silk defaults.

- [x] **Step 4: Run the focused tests and verify GREEN**

Expected: all `AppSettingsTests` pass with no failures.

- [x] **Step 5: Commit**

```bash
git add Foldy/Settings FoldyTests/AppSettingsTests.swift
git commit -m "feat: add Foldy appearance preferences"
```

### Task 2: Complete Foldy rename and remove obsolete licensing

**Files:**
- Rename: `Foldy/` to `Foldy/`
- Rename: `FoldyTests/` to `FoldyTests/`
- Rename: `Foldy/App/FoldyApp.swift` to `Foldy/App/FoldyApp.swift`
- Rename: `Foldy/Foldy.entitlements` to `Foldy/Foldy.entitlements`
- Delete: `Foldy/Entitlement/`
- Delete: `FoldyTests/EntitlementStoreTests.swift`
- Delete: `Config/`
- Modify: `project.yml`
- Regenerate: `Foldy.xcodeproj`

**Interfaces:**
- Produces: app target and module `Foldy`
- Produces: test target and module `FoldyTests`
- Produces: executable `Foldy` with bundle identifier `com.foldy.app`

- [x] **Step 1: Rename directories and primary files**

Use filesystem moves so Git records history, then update `@main struct FoldyApp`, test imports to `@testable import Foldy`, entitlements path, product names, scheme, and bundle identifiers in `project.yml`.

- [x] **Step 2: Remove dormant licensing code and old generated project**

Delete only the unused entitlement source/tests, example payment configuration, and `Foldy.xcodeproj`. Generate `Foldy.xcodeproj` with `xcodegen generate`.

- [x] **Step 3: Run a clean build to verify the rename**

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild build \
  -project Foldy.xcodeproj -scheme Foldy -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath build/RenameData CODE_SIGNING_ALLOWED=NO
```

Expected: `BUILD SUCCEEDED` and product path ending in `Foldy.app`.

- [x] **Step 4: Scan current source for obsolete branding**

Run `rg -n -i 'foldy' --glob '!docs/superpowers/**' --glob '!.git/**' --glob '!build/**' .` and update every result. The command must return no current product-code matches.

- [x] **Step 5: Commit**

```bash
git add -A
git commit -m "refactor: rename the app to Foldy"
```

### Task 3: Renderer-connected appearance controls

**Files:**
- Modify: `Foldy/Rendering/FoldRenderParameters.swift`
- Modify: `Foldy/Rendering/FoldRenderer.swift`
- Modify: `Foldy/Rendering/FoldShaders.metal`
- Modify: `Foldy/Overlay/FoldMetalView.swift`
- Modify: `Foldy/Overlay/OverlayCoordinator.swift`
- Test: `FoldyTests/FoldRenderParametersTests.swift`

**Interfaces:**
- Consumes: `FoldAppearance`
- Produces: `FoldRenderParameters.init(state:viewportSize:appearance:)`
- Produces: `FoldMetalView(state:appearance:)`
- Produces: `OverlayCoordinator.update(appearance:)`

- [x] **Step 1: Write failing render-parameter tests**

Use hand-derived literal expectations proving that zero perspective disables perspective, maximum blur maps to the full shader blur range, Shade increases shadow, and Frost sets style mode `2`.

```swift
func testFrostAppearanceMapsToFrostShaderMode() {
    let appearance = FoldAppearance(style: .frost, perspective: 0.7, variableBlur: 1, shadow: 0.4)
    let parameters = FoldRenderParameters(state: .closed, viewportSize: CGSize(width: 800, height: 500), appearance: appearance)
    XCTAssertEqual(parameters.styleMode, 2)
    XCTAssertEqual(parameters.blur, 1)
}
```

- [x] **Step 2: Run focused tests and verify RED**

Expected: compile failure because the appearance initializer and `styleMode` do not exist.

- [x] **Step 3: Extend CPU/GPU parameters**

Keep CPU and Metal structs byte-for-byte aligned. Map Silk/Shade/Frost to `0/1/2`, multiply the existing effect values by clamped appearance percentages, and use the shadow value for crease and horizon shade strength.

- [x] **Step 4: Update the runtime shader**

Use the same shader source in the editable `.metal` file and runtime source string. Shade receives stronger horizon darkening; Frost receives a subtle cool highlight; variable blur changes with fold depth. Do not add frame capture, storage, or networking behavior.

- [x] **Step 5: Pass appearance through preview and overlays**

Update every `FoldMetalView` construction and have `OverlayCoordinator` retain the latest appearance snapshot so all display panels render consistently.

- [x] **Step 6: Run focused and full tests and verify GREEN**

Expected: render parameter tests and existing fold/safety tests pass.

- [x] **Step 7: Commit**

```bash
git add Foldy/Rendering Foldy/Overlay FoldyTests/FoldRenderParametersTests.swift
git commit -m "feat: add configurable Foldy render styles"
```

### Task 4: Native Apple-style Settings experience

**Files:**
- Create: `Foldy/UI/Settings/SettingsRootView.swift`
- Create: `Foldy/UI/Settings/GeneralSettingsView.swift`
- Create: `Foldy/UI/Settings/AppearanceSettingsView.swift`
- Create: `Foldy/UI/Settings/AboutSettingsView.swift`
- Create: `Foldy/UI/Settings/StyleCard.swift`
- Create: `Foldy/UI/Settings/MacBookPreview.swift`
- Modify: `Foldy/UI/PreviewView.swift`

**Interfaces:**
- Consumes: `AppModel`, `AppSettings`, `FoldAppearance`
- Produces: `SettingsRootView(model:settings:)`
- Produces: reusable `MacBookPreview(angle:appearance:)`

- [x] **Step 1: Build the navigation shell**

Use `NavigationSplitView` with fixed 190-point sidebar selection and three cases: General, Appearance, About. Use semantic backgrounds and `.tint(Color(nsColor: .controlAccentColor))` so Apple system blue adapts correctly.

- [x] **Step 2: Build General**

Wire Enable Foldy to `AppModel`, launch at login to `LaunchAtLoginService`, sound to persisted settings, and permission status to the existing capture permission service. Use native `Form`, `Section`, `Toggle`, and `LabeledContent`.

- [x] **Step 3: Build Appearance**

Place `MacBookPreview` above the angle/follow-lid row, three equal-width `StyleCard` buttons, and four labeled sliders with trailing monospaced percentages/degrees. Selecting a style calls `settings.apply(style:)`; reset calls `settings.resetAppearance()`.

- [x] **Step 4: Build About**

Display the app icon, version from `CFBundleShortVersionString`, supported hardware summary, privacy copy, and the repository link `https://github.com/tejastelkar/foldy`.

- [x] **Step 5: Preserve a standalone preview route**

Refactor `PreviewView` to use `MacBookPreview` and the current settings snapshot so the menu command and Settings preview cannot drift visually.

- [x] **Step 6: Build and inspect compiler diagnostics**

Expected: no Swift errors or concurrency warnings introduced by the new views.

- [x] **Step 7: Commit**

```bash
git add Foldy/UI
git commit -m "feat: add Apple-style Foldy settings"
```

### Task 5: Application wiring and lifecycle

**Files:**
- Modify: `Foldy/App/FoldyApp.swift`
- Modify: `Foldy/App/AppDelegate.swift`
- Modify: `Foldy/App/AppModel.swift`
- Modify: `Foldy/UI/MenuBarContentView.swift`
- Modify: `Foldy/UI/OnboardingView.swift`
- Test: `FoldyTests/AppModelTests.swift`

**Interfaces:**
- Consumes: persisted `AppSettings.appearance`
- Produces: `AppModel.updateAppearance(_:)`
- Produces: window scene ID `settings`

- [x] **Step 1: Write failing model tests**

Add a test proving a settings update reaches a recording overlay coordinator through `updateAppearance(_:)` and a closing angle still applies a visible state.

- [x] **Step 2: Run focused tests and verify RED**

Expected: failure because the model and overlay protocol do not expose appearance updates.

- [x] **Step 3: Wire settings into runtime**

Add appearance updating to `OverlayCoordinating`, call it on app launch and whenever appearance preferences change, and configure the mapper from `clearAngle`.

- [x] **Step 4: Replace menu and onboarding copy**

The menu contains only Foldy status, enable, Settings, Preview Effect, and Quit Foldy. Onboarding explains Screen Recording accurately and uses Foldy branding throughout.

- [x] **Step 5: Add the Settings window scene**

Open a native titled Settings window at 780 × 560 from the menu and first launch. Keep the menu-bar-only activation policy after windows close.

- [x] **Step 6: Run focused and full tests and verify GREEN**

Expected: all model, safety, settings, rendering, and sensor tests pass.

- [x] **Step 7: Commit**

```bash
git add Foldy/App Foldy/UI Foldy/Overlay FoldyTests/AppModelTests.swift
git commit -m "feat: wire Foldy settings into the live effect"
```

### Task 6: Documentation, packaging, visual verification, and deployment

**Files:**
- Modify: `README.md`
- Modify: `.gitignore`
- Modify: `scripts/package.sh`
- Rename: `scripts/make_app_icon.swift` output references
- Modify: current design/plan documentation where it describes the shipped product

**Interfaces:**
- Produces: `build/Foldy.app`, `build/Foldy.dmg` or `build/Foldy.zip`

- [x] **Step 1: Update documentation and scripts**

Document Foldy controls, permission rationale, compatible hardware, build/test commands, and packaging. Remove payment instructions. Package and sign `Foldy.app`; fall back to `Foldy.zip` when the disk-image service is unavailable.

- [x] **Step 2: Run the full test suite**

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test \
  -project Foldy.xcodeproj -scheme Foldy -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath build/TestData CODE_SIGNING_ALLOWED=NO
```

If the restricted test-manager service cannot launch, run the built XCTest bundle directly with `xcrun xctest` after copying `Foldy.debug.dylib` into the test bundle Frameworks directory. Expected: zero failures.

- [x] **Step 3: Build and package Release**

Run `SKIP_TESTS=1 ./scripts/package.sh` only after Step 2 has fresh green evidence. Expected: `BUILD SUCCEEDED`, a valid `Foldy.app`, and a DMG or ZIP.

- [x] **Step 4: Verify the package**

Run `codesign --verify --deep --strict --verbose=2 build/Foldy.app`, inspect `Info.plist` product/bundle values, and calculate SHA-256 for the archive.

- [x] **Step 5: Visually inspect**

Launch the packaged app with the preview/settings route. Check the Apple-blue sidebar and controls, light/dark semantic surfaces, every style card, sliders, follow-lid toggle, menu copy, and About page. Correct visual defects before proceeding.

- [x] **Step 6: Enforce branding acceptance**

Run `rg -n -i 'foldy' --glob '!docs/superpowers/specs/2026-09-10-foldy-design.md' --glob '!docs/superpowers/plans/2026-09-10-foldy-implementation.md' --glob '!.git/**' --glob '!build/**' .`. Rename the historical documents to Foldy and update their content if any current-source matches remain.

- [x] **Step 7: Commit and push main**

```bash
git add -A
git commit -m "release: ship Foldy Apple-style settings"
git push origin main
```

Verify `HEAD` and `refs/remotes/origin/main` resolve to the same full commit SHA.
