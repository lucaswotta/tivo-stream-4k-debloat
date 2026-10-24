#!/usr/bin/env bash
# Read-only snapshot of the TV against the validated state. Changes nothing.
#
# Usage: TV_HOST=<ip> scripts/status.sh              (base, scripts/apply-all.sh)
#        TV_HOST=<ip> scripts/status.sh --personal   (base + scripts/personal.sh)
source "$(dirname "$0")/_lib.sh"
PERSONAL=""; [[ "${1:-}" == --personal ]] && PERSONAL=1
connect

ok() { [[ "$2" == "$3" ]] && echo "  ok      $1" || echo "  MISSING $1 (expected '$3', got '$2')"; }

echo "device: $(sh_tv getprop ro.product.model) / Android $(sh_tv getprop ro.build.version.release) / uptime $(sh_tv uptime -p) / profile checked: $([[ -n "$PERSONAL" ]] && echo personal || echo base)"
echo "launcher and services:"
ok "launcher installed (com.gathin.tvhome)" "$(sh_tv pm list packages com.gathin.tvhome | wc -l | tr -d ' ')" 1
ok "homekey installed" "$(sh_tv pm list packages dev.lucaswotta.homekey | wc -l | tr -d ' ')" 1
ok "bootclean installed" "$(sh_tv pm list packages dev.lucaswotta.bootclean | wc -l | tr -d ' ')" 1
# The launcher's service label follows the TV language, so match the components and our own label only.
a11y="$(sh_tv dumpsys accessibility)"
enabled=0
for svc in com.gathin.tvhome/com.gathin.tvhome.HomeKeyService dev.lucaswotta.homekey/dev.lucaswotta.homekey.HomeKeyService; do
  grep 'Enabled services' <<<"$a11y" | grep -qF "{$svc}" && enabled=$((enabled + 1))
done
ok "key services enabled" "$enabled" 2
ok "homekey service bound" "$(grep -A1 'Bound services' <<<"$a11y" | grep -c 'label=Home Key')" 1
ok "no notification listeners" "$(sh_tv settings get secure enabled_notification_listeners)" ""
ok "screensaver is the launcher clock" "$(sh_tv settings get secure screensaver_components)" "com.gathin.tvhome/.ClockDream"
if [[ -n "$PERSONAL" ]]; then
  ok "Assistant points to homekey" "$(sh_tv settings get secure assistant)" "dev.lucaswotta.homekey/.AssistActivity"
  ok "voice_interaction_service empty" "$(sh_tv settings get secure voice_interaction_service)" ""
  ok "personal theme on the TV" "$(sh_tv 'grep -c reduced_motion /sdcard/Android/data/com.gathin.tvhome/files/config.json 2>/dev/null')" 1
fi
echo "focused: $(sh_tv dumpsys activity activities | grep -m1 mFocusedApp | sed -E 's/.*u0 ([^ ]+) .*/\1/')"

SUSPENDED=(com.google.android.feedback com.google.android.partnersetup com.nes.tvbugtracker com.nes.coreservice com.nes.daemon
  com.tivo.sageservice com.google.android.tvrecommendations android.autoinstalls.config.sei com.android.printspooler
  com.google.android.marvin.talkback com.google.android.tvlauncher com.google.android.backdrop com.android.camera2 com.android.gallery3d)
STOPPED=(com.nes.coreservice com.tivo.sageservice com.google.android.tvlauncher com.google.android.tvrecommendations com.nes.tvbugtracker)
if [[ -n "$PERSONAL" ]]; then SUSPENDED+=(com.google.android.katniss com.google.android.tts); STOPPED+=(com.google.android.katniss); fi

echo "expected suspended (${#SUSPENDED[@]}):"
for p in "${SUSPENDED[@]}"; do
  [[ "$(sh_tv dumpsys package "$p" | grep -oE 'suspended=[a-z]+' | head -1)" == suspended=true ]] || echo "  MISSING suspend $p"
done
echo "processes bootclean should have stopped (running = problem, except in the first minutes after boot):"
for p in "${STOPPED[@]}"; do
  [[ -n "$(sh_tv pidof "$p")" ]] && echo "  running: $p"
done
echo "MemAvailable: $(sh_tv "awk '/MemAvailable/{print int(\$2/1024)}' /proc/meminfo") MB"
