#!/usr/bin/env bash
# Builds HomeKey.apk without Gradle: aapt2, javac, d8, zipalign, apksigner.
# Needs JDK 17 and the Android SDK (build-tools 34.0.0, platform android-34).
# Uses the JDK and SDK in ~/.local/share/tivo-toolchain (override the folder with TOOLCHAIN).
set -euo pipefail
cd "$(dirname "$0")"

TOOLCHAIN="${TOOLCHAIN:-$HOME/.local/share/tivo-toolchain}"
JAVA_HOME="$TOOLCHAIN/jdk17"
ANDROID_HOME="$TOOLCHAIN/sdk"
BT="$ANDROID_HOME/build-tools/34.0.0"
JAR="$ANDROID_HOME/platforms/android-34/android.jar"
export PATH="$JAVA_HOME/bin:$PATH"

OUT=build
rm -rf "$OUT"; mkdir -p "$OUT/compiled" "$OUT/classes"

"$BT/aapt2" compile --dir res -o "$OUT/compiled"
"$BT/aapt2" link -o "$OUT/base.apk" -I "$JAR" --manifest AndroidManifest.xml \
  --min-sdk-version 26 --target-sdk-version 31 "$OUT"/compiled/*.flat
# Java 8 bytecode: d8 8.2 crashes on class files targeting 17.
javac --release 8 -Xlint:-options -classpath "$JAR" -d "$OUT/classes" \
  $(find src -name '*.java')
"$BT/d8" --release --min-api 26 --lib "$JAR" --output "$OUT" $(find "$OUT/classes" -name '*.class')
(cd "$OUT" && zip -q -j base.apk classes.dex)
"$BT/zipalign" -f 4 "$OUT/base.apk" "$OUT/aligned.apk"

KEYSTORE="${KEYSTORE:-keystore.jks}"
if [ ! -f "$KEYSTORE" ]; then
  keytool -genkeypair -keystore "$KEYSTORE" -storepass homekey -keypass homekey \
    -alias homekey -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=homekey" >/dev/null
fi
"$BT/apksigner" sign --ks "$KEYSTORE" --ks-pass pass:homekey --key-pass pass:homekey \
  --out HomeKey.apk "$OUT/aligned.apk"
ls -l HomeKey.apk
