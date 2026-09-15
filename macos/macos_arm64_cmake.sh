#!/usr/bin/env bash
# Configure and build TheDarkMod for macOS arm64. Requires macos_arm64_deps.sh first.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SRC="$ROOT/darkmod_src"
BUILD="$SRC/build/macos-arm64"
CONAN="$SRC/build/conan"
export PATH="/opt/homebrew/bin:$PATH"
mkdir -p "$BUILD" "$ROOT/darkmod"

cmake -S "$SRC" -B "$BUILD" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DTDM_THIRDPARTY_ARTEFACTS=OFF \
  -DCMAKE_PREFIX_PATH="$CONAN" \
  -DGAME_DIR="$ROOT/darkmod" \
  -DCOPY_EXE=ON \
  -DENABLE_TRACY=OFF \
  -DFORCE_COLORED_OUTPUT=ON

cmake --build "$BUILD" --parallel
"$ROOT/scripts/verify_binary.sh" "$BUILD/thedarkmod.arm64"
