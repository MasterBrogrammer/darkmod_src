#!/usr/bin/env bash
# Build TDM third-party libs for macOS arm64 via Conan 2.
# Rerun-safe. Writes CMakeDeps into darkmod_src/build/conan.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SRC="$ROOT/darkmod_src"
TP="$SRC/ThirdParty"
OUT="$SRC/build/conan"
export PATH="/Users/stevenwoolery/Library/Python/3.13/bin:/opt/homebrew/bin:$PATH"

mkdir -p "$OUT" "$ROOT/darkmod"

cd "$TP"
python3 1_export_custom.py --unattended

# Linked Conan flow (no detached artefacts). Host = this Mac.
# os_macos profile disables pipe2; Apple's 26.x SDK marks it as 27.0.
export ac_cv_func_pipe2=no
export CFLAGS="-Wno-error=unguarded-availability-new ${CFLAGS:-}"
export CXXFLAGS="-Wno-error=unguarded-availability-new ${CXXFLAGS:-}"
conan install . \
  -pr:b profiles/base_macos \
  -pr profiles/os_macos \
  -pr profiles/arch_arm64 \
  -pr profiles/build_release \
  -of "$OUT" \
  -b missing \
  -s "thedarkmod/*:build_type=Release"

echo "conan deps ready in $OUT"
ls "$OUT" | head
