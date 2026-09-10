# LidBend

LidBend is a native macOS menu-bar app that makes the live desktop tilt, blur, crease, and settle as a compatible MacBook lid closes. It includes a manual preview for unsupported hardware and visual testing.

LidBend is independent software. It is not affiliated with Apple or the Bendy product.

## Requirements

- macOS 14 Sonoma or later
- Apple-silicon Mac
- Automatic hinge tracking: 14-inch or 16-inch Apple-silicon MacBook Pro, or MacBook Air M2 and later, with an exposed lid-angle HID sensor
- Xcode 26.6
- XcodeGen 2.45 or later

Unsupported Macs can run the complete manual preview.

## Build and run

```bash
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
xcodegen generate
xcodebuild build -project LidBend.xcodeproj -scheme LidBend -destination 'platform=macOS' -derivedDataPath build/DebugData CODE_SIGNING_ALLOWED=NO
open build/DebugData/Build/Products/Debug/LidBend.app
```

Open the menu-bar MacBook icon, choose **Setup & privacy**, and grant Screen Recording. Turn on **Enable lid effect**, then lower the lid. Choose **Preview effect** to test without moving the lid.

## Privacy and safety

ScreenCaptureKit frames remain in memory and are sent directly to Metal. LidBend does not save screenshots, transmit frames or sensor readings, include analytics, prevent sleep, or modify system lid behavior. The overlay is click-through and automatically disappears when the sensor stream becomes stale or invalid.

## Tests

```bash
xcodebuild test -project LidBend.xcodeproj -scheme LidBend -destination 'platform=macOS' -derivedDataPath build/TestData CODE_SIGNING_ALLOWED=NO
```

## Package

```bash
./scripts/package.sh
```

Without credentials, packaging creates an unsigned local `build/LidBend.app` and `build/LidBend.dmg`. If macOS's disk-image service is unavailable, it falls back to `build/LidBend.zip`. For commercial distribution, install a Developer ID Application certificate and set `CODE_SIGN_IDENTITY`, `DEVELOPMENT_TEAM`, and optionally `NOTARY_PROFILE` in the environment. The script signs with the hardened runtime and notarizes when those values are present.

## $1.99 lifetime license

`DirectLicenseStore` validates Ed25519-signed license documents for product `lidbend-lifetime`; the private signing key never belongs in the app. Copy `Config/Secrets.example.xcconfig` to the ignored `Config/Secrets.xcconfig` and connect the checkout/customer portal from your payment provider. A production checkout cannot be activated until the repository owner supplies that provider account and public verification key.

## Sensor implementation

The app reads feature report 1 from Apple's `0x8104` HID device through public IOKit functions. The device/report contract is undocumented and may change with future hardware or macOS versions. Hardware discovery behavior was informed by Sam Henri Gold's Apache-2.0-licensed [LidAngleSensor](https://github.com/samhenrigold/LidAngleSensor) project.
