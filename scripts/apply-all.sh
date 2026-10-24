#!/usr/bin/env bash
# Applies everything this project validated on a TiVo Stream 4K, in an order that cannot leave the TV
# without a way to open apps: tools, build, install, theme, settings, debloat, and the stock launcher last.
# Every step is reversible (scripts/rollback.sh, scripts/install-launcher.sh --remove, docs/10-bootclean.md).
#
# Usage: TV_HOST=<ip> scripts/apply-all.sh              (explains and asks first)
#        TV_HOST=<ip> scripts/apply-all.sh --dry-run    (only prints the plan and what apply.sh would do)
#        TV_HOST=<ip> scripts/apply-all.sh --yes        (no questions)
#        --with-owner-removals   also removes the apps listed under "Already removed by the owner"
#        --skip-build            uses the APKs already in launcher/, homekey/ and bootclean/
# The owner's choices (focus zoom, remote buttons, Assistant off) are in scripts/personal.sh.
source "$(dirname "$0")/_lib.sh"

DRY="" YES="" OWNER="" SKIP_BUILD=""
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY=1 ;; --yes) YES=1 ;; --with-owner-removals) OWNER=1 ;; --skip-build) SKIP_BUILD=1 ;;
    *) echo "unknown option: $arg" >&2; exit 1 ;;
  esac
done
LIST="$ROOT/examples/tivo-stream-4k/debloat.txt"
TOOLCHAIN="${TOOLCHAIN:-$HOME/.local/share/tivo-toolchain}"
step() { echo; echo "== $*"; }
run() { if [[ -n "$DRY" ]]; then echo "[dry-run] $*"; else "$@"; fi; }

connect
MODEL="$(sh_tv getprop ro.product.model)"; BUILD="$(sh_tv getprop ro.build.display.id)"; SDK="$(sh_tv getprop ro.build.version.sdk)"
echo "Device: $MODEL, build $BUILD, SDK $SDK"
if [[ "$MODEL" != "TiVo Stream 4K" || "$SDK" != 31 ]]; then
  echo "WARNING: validated only on the TiVo Stream 4K with Android 12 (build 1272). This device is different." >&2
  [[ -n "$YES" || -n "$DRY" ]] || { read -r -p "Continue anyway? [y/N] " a; [[ "$a" == [yY]* ]] || exit 1; }
fi

cat <<'TXT'

What will be done (the base; the personal layer is scripts/personal.sh):
  1. Download JDK 17 and the Android SDK (official sources, checksums verified), if not present yet.
  2. Build the cleanyourtv launcher without the HOME category, the Home key service and bootclean.
  3. Install the three and turn on the accessibility services.
  4. Push a plain theme (dock with Netflix, Prime Video and YouTube; menu on hold OK).
  5. Turn off the tvrecommendations notification listener and use the launcher clock as screensaver.
  6. Suspend 14 packages (telemetry, NES and TiVo services, recommendations, stock screensaver, unused apps).
  7. Take the HOME role away from the stock launcher and suspend it (last).
It does not touch the Google Assistant, the remote buttons or the focus zoom.
Effects you have to accept:
  - bootclean keeps a USB debugging key authorized for good and runs fixed commands at every boot.
  - Downloader and 52 other apps on coreservice's factory list are still removed at every boot.
TXT
if [[ -z "$YES" && -z "$DRY" ]]; then read -r -p "Apply? [y/N] " a; [[ "$a" == [yY]* ]] || { echo "nothing was changed"; exit 0; }; fi

step "1/7 build tools"
if [[ -n "$SKIP_BUILD" ]]; then echo "skipped (--skip-build)"
elif [[ -x "$TOOLCHAIN/sdk/build-tools/35.0.0/d8" && -x "$TOOLCHAIN/jdk17/bin/java" ]]; then echo "already in $TOOLCHAIN"
else run "$ROOT/scripts/setup-toolchain.sh"; fi

step "2/7 build"
if [[ -n "$SKIP_BUILD" ]]; then echo "skipped (--skip-build)"; else run "$ROOT/scripts/build-launcher.sh"; fi

step "3/7 install launcher, Home key service and bootclean"
if [[ -n "$DRY" ]]; then echo "[dry-run] scripts/install-launcher.sh"; else
  echo "Look at the TV: the first time, accept bootclean's USB debugging prompt with 'Always allow' (TV awake, no screensaver)."
  "$ROOT/scripts/install-launcher.sh"
fi

step "4/7 theme"
run "$ROOT/scripts/push-theme.sh"

step "5/7 tvrecommendations notification listener and screensaver"
run sh_tv cmd notification disallow_listener com.google.android.tvrecommendations/com.google.android.tvrecommendations.NotificationsService
run sh_tv "settings put secure screensaver_components com.gathin.tvhome/.ClockDream; settings put secure screensaver_default_component com.gathin.tvhome/.ClockDream; settings put secure screensaver_enabled 1"

step "6/7 debloat"
[[ -n "$DRY" ]] && export DRY_RUN=1
for group in "Telemetry and feedback" "App blocker and NES services" "Recommendations, partner rows" "Preloaded apps"; do
  "$ROOT/scripts/apply.sh" "$LIST" --only "$group" | grep -v '^$' | grep -v '^Done'
done
[[ -n "$OWNER" ]] && "$ROOT/scripts/apply.sh" "$LIST" --only "Already removed" | grep -v '^$' | grep -v '^Done'

step "7/7 stock launcher (last, once the new one is installed)"
# The stock launcher owns the HOME role, and Android refuses to suspend the role holder.
run sh_tv cmd package set-home-activity --user 0 com.android.tv.settings/.system.FallbackHome
"$ROOT/scripts/apply.sh" "$LIST" --only "Stock launcher and unused" | grep -v '^$' | grep -v '^Done'

if [[ -z "$DRY" ]]; then
  step "check"
  sleep 20
  "$ROOT/scripts/status.sh"
  echo
  echo "Press Home on the remote. Then reboot the TV and run scripts/status.sh about 6 minutes later. Personal layer: scripts/personal.sh."
fi
