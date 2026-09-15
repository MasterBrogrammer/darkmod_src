#!/usr/bin/env bash
# Build TheDarkMod.app next to the game pk4s. Rerun-safe.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
GAME="$ROOT/darkmod"
BIN="$GAME/thedarkmod.arm64"
APP="$GAME/TheDarkMod.app"
MACOS="$APP/Contents/MacOS"
RES="$APP/Contents/Resources"
test -x "$BIN"

rm -rf "$APP"
mkdir -p "$MACOS" "$RES"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>en</string>
	<key>CFBundleExecutable</key>
	<string>TheDarkMod</string>
	<key>CFBundleIdentifier</key>
	<string>com.thedarkmod.macos</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>The Dark Mod</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>2.14</string>
	<key>CFBundleVersion</key>
	<string>2.14</string>
	<key>LSMinimumSystemVersion</key>
	<string>12.0</string>
	<key>NSHighResolutionCapable</key>
	<true/>
	<key>CFBundleIconFile</key>
	<string>AppIcon</string>
</dict>
</plist>
PLIST

cp "$BIN" "$MACOS/TheDarkMod"
chmod +x "$MACOS/TheDarkMod"

if [[ -f "$GAME/TDM_icon.ico" ]]; then
  TMP="$(mktemp -d)"
  if sips -s format png "$GAME/TDM_icon.ico" --out "$TMP/icon.png" >/dev/null 2>&1; then
    mkdir -p "$TMP/AppIcon.iconset"
    sips -z 16 16 "$TMP/icon.png" --out "$TMP/AppIcon.iconset/icon_16x16.png" >/dev/null
    sips -z 32 32 "$TMP/icon.png" --out "$TMP/AppIcon.iconset/icon_16x16@2x.png" >/dev/null
    sips -z 32 32 "$TMP/icon.png" --out "$TMP/AppIcon.iconset/icon_32x32.png" >/dev/null
    sips -z 64 64 "$TMP/icon.png" --out "$TMP/AppIcon.iconset/icon_32x32@2x.png" >/dev/null
    sips -z 128 128 "$TMP/icon.png" --out "$TMP/AppIcon.iconset/icon_128x128.png" >/dev/null
    sips -z 256 256 "$TMP/icon.png" --out "$TMP/AppIcon.iconset/icon_128x128@2x.png" >/dev/null
    sips -z 256 256 "$TMP/icon.png" --out "$TMP/AppIcon.iconset/icon_256x256.png" >/dev/null
    iconutil -c icns "$TMP/AppIcon.iconset" -o "$RES/AppIcon.icns" >/dev/null 2>&1 || true
  fi
  rm -rf "$TMP"
fi

# Linux x64 leftover from the installer is not launchable here.
if [[ -f "$GAME/thedarkmod.x64" ]]; then
  chmod a-x "$GAME/thedarkmod.x64" || true
fi

echo "app $APP"
ls -la "$MACOS/TheDarkMod" "$BIN"
