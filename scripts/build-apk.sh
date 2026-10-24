#!/usr/bin/env bash
# Builds <folder>/<folder>.apk without Gradle: aapt2, javac, d8, zipalign, apksigner.
# The folder holds AndroidManifest.xml, res/ and src/. Usage: scripts/build-apk.sh homekey
# Needs JDK 17 and the Android SDK (build-tools 35.0.0, platform android-34).
# Uses the JDK and SDK in ~/.local/share/tivo-toolchain (override the folder with TOOLCHAIN).
set -euo pipefail
APP="${1:?usage: build-apk.sh <folder>}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT/$APP"
[[ "$APP" == bootclean && ! -f src/dev/lucaswotta/bootclean/Profile.java ]] && "$ROOT/scripts/bootclean-profile.sh" base

TOOLCHAIN="${TOOLCHAIN:-$HOME/.local/share/tivo-toolchain}"
JAVA_HOME="$TOOLCHAIN/jdk17"
ANDROID_HOME="$TOOLCHAIN/sdk"
# build-tools 35: the d8 in 34 crashes on the MethodParameters javac 17 writes for nested classes.
BT="$ANDROID_HOME/build-tools/35.0.0"
JAR="$ANDROID_HOME/platforms/android-34/android.jar"
export PATH="$JAVA_HOME/bin:$PATH"

OUT=build
rm -rf "$OUT"; mkdir -p "$OUT/compiled" "$OUT/classes"

"$BT/aapt2" compile --dir res -o "$OUT/compiled"
"$BT/aapt2" link -o "$OUT/base.apk" -I "$JAR" --manifest AndroidManifest.xml \
  --min-sdk-version 26 --target-sdk-version 31 "$OUT"/compiled/*.flat
# Java 8 bytecode, which d8 desugars for the TV's Android 12.
javac --release 8 -Xlint:-options -classpath "$JAR" -d "$OUT/classes" \
  $(find src -name '*.java')
"$BT/d8" --release --min-api 26 --lib "$JAR" --output "$OUT" $(find "$OUT/classes" -name '*.class')
(cd "$OUT" && zip -q -j base.apk classes.dex)
"$BT/zipalign" -f 4 "$OUT/base.apk" "$OUT/aligned.apk"

KEYSTORE="${KEYSTORE:-keystore.jks}"
if [ ! -f "$KEYSTORE" ]; then
  keytool -genkeypair -keystore "$KEYSTORE" -storepass $APP -keypass $APP \
    -alias $APP -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=$APP" >/dev/null
fi
"$BT/apksigner" sign --ks "$KEYSTORE" --ks-pass "pass:$APP" --key-pass "pass:$APP" \
  --out "$APP.apk" "$OUT/aligned.apk"
ls -l "$APP.apk"
