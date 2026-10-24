#!/usr/bin/env bash
# Installs the launcher (launcher/cleanyourtv.apk), the Home key service (homekey/homekey.apk) and bootclean
# (bootclean/bootclean.apk), and turns on two accessibility services: dev.lucaswotta.homekey for the Home key
# and the launcher's own HomeKeyService for app_keys and the Settings key (scripts/push-theme.sh). Reinstalling
# clears the service setting, so every install enables it again; other enabled accessibility services are kept.
# Build the APKs first with scripts/build-launcher.sh.
#
# Usage: scripts/install-launcher.sh
#        scripts/install-launcher.sh --remove   # turns the services off and uninstalls the three; Home goes back to the stock launcher
source "$(dirname "$0")/_lib.sh"

LAUNCHER=com.gathin.tvhome
KEY_PKG=dev.lucaswotta.homekey
SERVICE="$KEY_PKG/.HomeKeyService"
OLD_PKG=dev.lucaswotta.homelite     # first prototype, replaced by the cleanyourtv launcher
connect

drop_services() {   # removes every given service from enabled_accessibility_services
  local current rest
  current="$(sh_tv settings get secure enabled_accessibility_services)"
  rest="$(tr ':' '\n' <<<"$current" | grep -v -e null -e '^$' | grep -vE "^($(IFS='|'; echo "$*"))$" | paste -sd: - || true)"
  if [[ -n "$rest" ]]; then sh_tv settings put secure enabled_accessibility_services "$rest"
  else sh_tv settings delete secure enabled_accessibility_services; sh_tv settings put secure accessibility_enabled 0; fi
}

if [[ "${1:-}" == "--remove" ]]; then
  drop_services "$SERVICE" "$LAUNCHER/.HomeKeyService" "$OLD_PKG/.HomeKeyService"
  for p in "$KEY_PKG" "$LAUNCHER" "$OLD_PKG" dev.lucaswotta.bootclean; do sh_tv pm uninstall "$p" >/dev/null 2>&1 || true; done
  sh_tv am start -a android.intent.action.MAIN -c android.intent.category.HOME >/dev/null
  echo "Removed. Home: $(sh_tv cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME | tail -1)"
  exit 0
fi

for apk in launcher/cleanyourtv.apk homekey/homekey.apk bootclean/bootclean.apk; do
  [[ -f "$ROOT/$apk" ]] || { echo "missing $apk: run scripts/build-launcher.sh" >&2; exit 1; }
done

drop_services "$OLD_PKG/.HomeKeyService"
sh_tv pm uninstall "$OLD_PKG" >/dev/null 2>&1 || true
adb -s "$TARGET" install -r "$ROOT/launcher/cleanyourtv.apk" </dev/null
adb -s "$TARGET" install -r "$ROOT/homekey/homekey.apk" </dev/null
adb -s "$TARGET" install -r "$ROOT/bootclean/bootclean.apk" </dev/null

enable_services "$SERVICE" "$LAUNCHER/.HomeKeyService"

bound_ok=""
for _ in 1 2 3 4 5; do
  sleep 2
  # dumpsys prints one bound service per line, so read the first two.
  if sh_tv dumpsys accessibility | grep -A1 "Bound services" | grep -q "Home Key"; then bound_ok=1; break; fi
done
[[ -n "$bound_ok" ]] || { echo "The service did not start. Check Settings > Accessibility." >&2; exit 1; }
echo "Service running."

# bootclean stops the processes the system restarts at every boot. Its first run asks the TV for ADB
# permission: accept with "Always allow" (the screensaver must not be on, or the prompt is denied).
sh_tv am broadcast -n dev.lucaswotta.bootclean/.BootReceiver -a dev.lucaswotta.bootclean.RUN >/dev/null
echo "Look at the TV: accept bootclean's USB debugging prompt with 'Always allow'."
