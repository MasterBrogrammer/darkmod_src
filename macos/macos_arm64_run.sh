#!/usr/bin/env bash
# Launch the arm64 TDM binary against ../darkmod assets. Windowed, skip intros.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
APPBIN="$ROOT/darkmod/TheDarkMod.app/Contents/MacOS/TheDarkMod"
BIN="$ROOT/darkmod/thedarkmod.arm64"
if [[ -x "$APPBIN" ]]; then
  BIN="$APPBIN"
fi
test -x "$BIN"
cd "$ROOT/darkmod"
exec "$BIN" \
  +set com_smp 0 \
  +set r_fullscreen 0 \
  +set r_glCoreProfile 2 \
  +set com_skipIntroVideos 1 \
  +set com_allowConsole 1 \
  "$@"
