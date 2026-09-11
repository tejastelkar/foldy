#!/bin/zsh
set -euo pipefail

repo_root="${0:A:h:h}"
build_root="$repo_root/build"
developer_dir="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

cd "$repo_root"
export DEVELOPER_DIR="$developer_dir"

xcodegen generate
if [[ "${SKIP_TESTS:-0}" != "1" ]]; then
  xcodebuild test \
    -project Foldy.xcodeproj \
    -scheme Foldy \
    -destination 'platform=macOS' \
    -derivedDataPath "$build_root/TestData" \
    CODE_SIGNING_ALLOWED=NO
fi

xcodebuild build \
  -project Foldy.xcodeproj \
  -scheme Foldy \
  -configuration Release \
  -destination 'platform=macOS' \
  -derivedDataPath "$build_root/DerivedData" \
  CODE_SIGNING_ALLOWED=NO

app_source="$build_root/DerivedData/Build/Products/Release/Foldy.app"
app_output="$build_root/Foldy.app"
/usr/bin/ditto "$app_source" "$app_output"

if [[ -n "${CODE_SIGN_IDENTITY:-}" && -n "${DEVELOPMENT_TEAM:-}" ]]; then
  /usr/bin/codesign --force --deep --options runtime --timestamp \
    --sign "$CODE_SIGN_IDENTITY" "$app_output"
else
  /usr/bin/codesign --force --deep --sign - "$app_output"
fi

staging_dir="$build_root/dmg_staging"
/bin/rm -rf "$staging_dir"
/bin/mkdir -p "$staging_dir"
/usr/bin/ditto "$app_output" "$staging_dir/Foldy.app"
ln -s /Applications "$staging_dir/Applications"

if [[ -f "$repo_root/Foldy/Resources/Foldy.icns" ]]; then
  /bin/cp "$repo_root/Foldy/Resources/Foldy.icns" "$staging_dir/.VolumeIcon.icns"
  /usr/bin/SetFile -a C "$staging_dir" || true
fi

dmg_output="$build_root/Foldy.dmg"
zip_output="$build_root/Foldy.zip"
/bin/rm -f "$dmg_output" "$zip_output"
if ! /usr/bin/hdiutil create -ov -volname Foldy -srcfolder "$staging_dir" -format UDZO "$dmg_output"; then
  print "Disk image service unavailable; creating a ZIP instead."
  /usr/bin/ditto -c -k --sequesterRsrc --keepParent "$app_output" "$zip_output"
fi
/bin/rm -rf "$staging_dir"

if [[ -n "${NOTARY_PROFILE:-}" ]]; then
  xcrun notarytool submit "$dmg_output" --keychain-profile "$NOTARY_PROFILE" --wait
  xcrun stapler staple "$dmg_output"
fi

# Copy built DMG to website and public hub assets
if [[ -f "$dmg_output" ]]; then
  /bin/cp "$dmg_output" "$repo_root/website/assets/Foldy.dmg"
  if [[ -d "/Users/tejastelkar/Desktop/public/assets" ]]; then
    /bin/cp "$dmg_output" "/Users/tejastelkar/Desktop/public/assets/Foldy.dmg"
  fi
fi

print "Built app: $app_output"
if [[ -f "$dmg_output" ]]; then
  print "Built disk image: $dmg_output"
else
  print "Built ZIP archive: $zip_output"
fi
