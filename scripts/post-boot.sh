#!/usr/bin/env bash
# Stops, after a boot, the processes the system restarts even though their packages are suspended and
# that the launcher in front does not need. An app cannot do this itself: killBackgroundProcesses from
# an app is accepted and ignored on this firmware, while the same call from the shell works.
#
# Usage: scripts/post-boot.sh      (wait ~2 min after boot, so the services have started)
# bootclean does the same on the TV by itself; this is the manual version from a computer.
source "$(dirname "$0")/_lib.sh"
connect

# Suspended packages still get their boot broadcasts and bindings, so these come back at every boot:
# the NES core and TiVo services, the stock launcher, Assistant and recommendations. tvrecommendations only
# stays down once its notification listener is off (scripts/apply-all.sh does that): while the listener is
# enabled, the system binds it again within a second of a force-stop.
STOP=(com.nes.coreservice com.tivo.sageservice com.google.android.tvlauncher com.google.android.katniss com.google.android.tvrecommendations com.nes.tvbugtracker)

for p in "${STOP[@]}"; do sh_tv am force-stop "$p"; done
sleep 3
alive="$(sh_tv ps -A | grep -E "$(IFS='|'; echo "${STOP[*]}")" | awk '{print $NF}' || true)"
echo "MemAvailable: $(sh_tv "awk '/MemAvailable/{print int(\$2/1024)}' /proc/meminfo") MB"
[[ -z "$alive" ]] && echo "Stopped: ${STOP[*]}" || echo "Still running (restarted by the system): $alive"
