#!/usr/bin/env bash
# Install an APK on the TV from this computer: a file, or a URL that is downloaded here first. It does the
# job of Downloader, whose package com.nes.coreservice removes at every boot (docs/03-coreservice.md).
# Shows the package name and version before installing; the APK is untrusted until you have checked it.
#
# Usage: scripts/install-apk.sh <file.apk | https://...apk>
source "$(dirname "$0")/_lib.sh"

SOURCE="${1:?usage: install-apk.sh <file.apk | https://...apk>}"
AAPT2="${AAPT2:-$HOME/.local/share/tivo-toolchain/sdk/build-tools/34.0.0/aapt2}"
work="$(mktemp -d)"; trap 'rm -rf "$work"' EXIT

if [[ "$SOURCE" == https://* ]]; then
  curl -fL --proto '=https' -o "$work/app.apk" "$SOURCE"
  apk="$work/app.apk"
else
  apk="$SOURCE"
fi
[[ -f "$apk" ]] || { echo "file not found: $apk" >&2; exit 1; }

echo "sha256: $(sha256sum "$apk" | cut -d' ' -f1)"
[[ -x "$AAPT2" ]] && "$AAPT2" dump badging "$apk" | grep -E "^(package|application-label:)" | cut -c1-120
connect
adb -s "$TARGET" install -r "$apk" </dev/null
