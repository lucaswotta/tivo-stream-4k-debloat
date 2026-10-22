#!/usr/bin/env bash
# Builds the cleanyourtv launcher (Gathin23/cleanyourtv, MIT) at a pinned commit with
# the patches in launcher/ applied, and the HomeKey service APK next to it.
# Needs JDK 17 and the Android SDK in ~/.local/share/tivo-toolchain; Gradle and the AndroidX
# libraries are downloaded by the project's own Gradle wrapper on the first run.
#
# Uso: scripts/build-launcher.sh      -> launcher/cleanyourtv.apk, homekey/homekey.apk e bootclean/bootclean.apk
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TOOLCHAIN="${TOOLCHAIN:-$HOME/.local/share/tivo-toolchain}"
SRC="$TOOLCHAIN/cleanyourtv-src"
PIN=30626a8e4714f86bf837384b109b5c73ee736917
# Always the toolchain JDK 17: Gradle 8.9 does not run on a newer JAVA_HOME inherited from the shell.
export JAVA_HOME="$TOOLCHAIN/jdk17"
export ANDROID_HOME="$TOOLCHAIN/sdk"
export PATH="$JAVA_HOME/bin:$PATH"

if [[ ! -d "$SRC/.git" ]]; then
  git init -q "$SRC"
  git -C "$SRC" remote add origin https://github.com/Gathin23/cleanyourtv
fi
git -C "$SRC" fetch -q --depth 1 origin "$PIN"
git -C "$SRC" checkout -q -f "$PIN"
git -C "$SRC" clean -qfd
for patch in "$ROOT"/launcher/*.patch; do git -C "$SRC" apply "$patch"; done

cd "$SRC/launcher"
echo "sdk.dir=$ANDROID_HOME" > local.properties
./gradlew --no-daemon assembleRelease -q --console=plain
cp app/build/outputs/apk/release/app-release.apk "$ROOT/launcher/cleanyourtv.apk"
ls -l "$ROOT/launcher/cleanyourtv.apk"

"$ROOT/scripts/build-apk.sh" homekey | tail -1
"$ROOT/scripts/build-apk.sh" bootclean | tail -1
