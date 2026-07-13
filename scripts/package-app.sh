#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIGURATION="${CONFIGURATION:-debug}"
CACHE_PATH="$ROOT_DIR/.build/swiftpm-cache"
BUILD_DIR="$ROOT_DIR/.build/arm64-apple-macosx/$CONFIGURATION"
EXECUTABLE="$BUILD_DIR/GreenlightApp"
APP_DIR="$ROOT_DIR/outputs/Greenlight.app"
ZIP_PATH="$ROOT_DIR/outputs/Greenlight-0.1.0.zip"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
ICONSET_DIR="$RESOURCES_DIR/Greenlight.iconset"
ICON_PATH="$RESOURCES_DIR/Greenlight.icns"
ICON_SOURCE="$ROOT_DIR/Assets/AppIconSource.png"

cd "$ROOT_DIR"

swift build \
  --disable-sandbox \
  --cache-path "$CACHE_PATH" \
  ${CONFIGURATION:+--configuration "$CONFIGURATION"}

if [[ ! -x "$EXECUTABLE" ]]; then
  echo "Expected executable was not found at $EXECUTABLE" >&2
  exit 1
fi

rm -rf "$APP_DIR"
rm -f "$ZIP_PATH"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

cp "$EXECUTABLE" "$MACOS_DIR/GreenlightApp"
chmod +x "$MACOS_DIR/GreenlightApp"

swift "$ROOT_DIR/scripts/make-app-icon.swift" "$ICON_SOURCE" "$ICONSET_DIR" "$ICON_PATH"
rm -rf "$ICONSET_DIR"

cat > "$CONTENTS_DIR/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleDisplayName</key>
    <string>Greenlight</string>
    <key>CFBundleExecutable</key>
    <string>GreenlightApp</string>
    <key>CFBundleIconFile</key>
    <string>Greenlight</string>
    <key>CFBundleIdentifier</key>
    <string>com.projectgreenlight.Greenlight</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>Greenlight</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>0.1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
</dict>
</plist>
PLIST

printf 'APPL????' > "$CONTENTS_DIR/PkgInfo"

if command -v xattr >/dev/null 2>&1; then
  xattr -cr "$APP_DIR" || true
fi

if command -v codesign >/dev/null 2>&1; then
  codesign --force --sign - "$APP_DIR" >/dev/null
fi

if command -v ditto >/dev/null 2>&1; then
  ditto -c -k --sequesterRsrc --keepParent "$APP_DIR" "$ZIP_PATH"
fi

echo "$APP_DIR"
