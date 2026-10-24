#!/usr/bin/env bash
# Downloads what the launcher builds need into ~/.local/share/tivo-toolchain: JDK 17 (Eclipse Temurin) and the
# Android SDK pieces (cmdline-tools, build-tools 34 and 35, platform 34). Checksums come from the vendors'
# own metadata and are verified before anything is unpacked. No sudo, nothing written outside that folder,
# no change to your shell profile.
#
# Usage: scripts/setup-toolchain.sh             (asks before accepting the Android SDK licenses)
#      ACCEPT_LICENSES=1 scripts/setup-toolchain.sh
#      TOOLCHAIN=/other/folder scripts/setup-toolchain.sh
set -euo pipefail

TOOLCHAIN="${TOOLCHAIN:-$HOME/.local/share/tivo-toolchain}"
for tool in curl python3 unzip tar sha1sum sha256sum; do
  command -v "$tool" >/dev/null || { echo "missing command: $tool" >&2; exit 1; }
done
[[ "$(uname -s)" == Linux ]] || { echo "Linux only (tested on x86_64); elsewhere, install JDK 17 and the Android SDK by hand and point TOOLCHAIN at them" >&2; exit 1; }
case "$(uname -m)" in
  x86_64)  ADOPTIUM_ARCH=x64 ;;
  aarch64) ADOPTIUM_ARCH=aarch64 ;;
  *) echo "unsupported architecture: $(uname -m)" >&2; exit 1 ;;
esac

mkdir -p "$TOOLCHAIN"
work="$(mktemp -d "$TOOLCHAIN/dl.XXXXXX")"; trap 'rm -rf "$work"' EXIT

if [[ ! -x "$TOOLCHAIN/jdk17/bin/java" ]]; then
  echo "JDK 17 (Temurin)..."
  curl -fsSL "https://api.adoptium.net/v3/assets/latest/17/hotspot?architecture=$ADOPTIUM_ARCH&image_type=jdk&os=linux&vendor=eclipse" -o "$work/jdk.json"
  read -r url sha < <(python3 -I -c '
import json,sys
p=json.load(open(sys.argv[1]))[0]["binary"]["package"]
print(p["link"], p["checksum"])' "$work/jdk.json")
  curl -fL --proto '=https' -o "$work/jdk.tgz" "$url"
  echo "$sha  $work/jdk.tgz" | sha256sum -c - >/dev/null || { echo "JDK checksum mismatch" >&2; exit 1; }
  mkdir -p "$TOOLCHAIN/jdk17"; tar -xzf "$work/jdk.tgz" -C "$TOOLCHAIN/jdk17" --strip-components=1
fi
"$TOOLCHAIN/jdk17/bin/java" -version 2>&1 | head -1

if [[ ! -x "$TOOLCHAIN/sdk/cmdline-tools/latest/bin/sdkmanager" ]]; then
  echo "Android command-line tools..."
  curl -fsSL https://dl.google.com/android/repository/repository2-3.xml -o "$work/repo.xml"
  read -r zip sha1 < <(python3 -I -c '
import sys, xml.etree.ElementTree as ET
root = ET.parse(sys.argv[1]).getroot()
for pkg in root.iter("remotePackage"):
    if pkg.get("path") != "cmdline-tools;latest": continue
    for a in pkg.iter("archive"):
        if (a.findtext("host-os") or "") == "linux":
            c = a.find("complete")
            print(c.findtext("url"), c.findtext("checksum")); raise SystemExit
raise SystemExit("cmdline-tools not found in the repository index")' "$work/repo.xml")
  curl -fL --proto '=https' -o "$work/cmdline.zip" "https://dl.google.com/android/repository/$zip"
  echo "$sha1  $work/cmdline.zip" | sha1sum -c - >/dev/null || { echo "command-line tools checksum mismatch" >&2; exit 1; }
  mkdir -p "$TOOLCHAIN/sdk/cmdline-tools"
  unzip -q "$work/cmdline.zip" -d "$work/cmdline"
  mv "$work/cmdline/cmdline-tools" "$TOOLCHAIN/sdk/cmdline-tools/latest"
fi

export JAVA_HOME="$TOOLCHAIN/jdk17"
sdkmanager="$TOOLCHAIN/sdk/cmdline-tools/latest/bin/sdkmanager"
if [[ ! -d "$TOOLCHAIN/sdk/licenses" ]]; then
  if [[ -z "${ACCEPT_LICENSES:-}" ]]; then
    read -r -p "Accept the Android SDK licenses (https://developer.android.com/studio/terms)? [y/N] " answer
    [[ "$answer" == [yY]* ]] || { echo "licenses not accepted; nothing else was downloaded" >&2; exit 1; }
  fi
  yes | "$sdkmanager" --sdk_root="$TOOLCHAIN/sdk" --licenses >/dev/null 2>&1 || true
fi
echo "build-tools 34 and 35, platform 34..."
"$sdkmanager" --sdk_root="$TOOLCHAIN/sdk" "build-tools;34.0.0" "build-tools;35.0.0" "platforms;android-34" >/dev/null
[[ -x "$TOOLCHAIN/sdk/build-tools/35.0.0/d8" && -f "$TOOLCHAIN/sdk/platforms/android-34/android.jar" ]] \
  || { echo "the SDK is incomplete" >&2; exit 1; }
echo "Ready: $TOOLCHAIN"
