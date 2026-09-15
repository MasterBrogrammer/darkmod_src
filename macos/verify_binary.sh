#!/usr/bin/env bash
# Prove the Mac binary is native arm64 Mach-O, not ELF/x86/Wine.
set -euo pipefail
bin="${1:?usage: verify_binary.sh <path>}"
test -x "$bin"
info="$(file "$bin")"
echo "$info"
echo "$info" | grep -q 'Mach-O 64-bit executable arm64'
arch="$(lipo -archs "$bin" 2>/dev/null || true)"
if [[ -n "$arch" ]]; then
  echo "lipo: $arch"
  echo "$arch" | grep -qw arm64
fi
echo "ok $bin"
