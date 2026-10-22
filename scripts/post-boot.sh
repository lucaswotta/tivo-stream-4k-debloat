#!/usr/bin/env bash
# Stops, after a boot, the processes the system restarts even though their packages are suspended and
# that the launcher in front does not need. An app cannot do this itself: killBackgroundProcesses from
# an app is accepted and ignored on this firmware, while the same call from the shell works.
#
# Uso: scripts/post-boot.sh        (a TV precisa estar ligada há ~2 min, para os serviços terem subido)
source "$(dirname "$0")/_lib.sh"
connect

# Suspended packages still get their boot broadcasts and bindings, so these come back at every boot:
# the NES core and TiVo services, the stock launcher and Assistant. com.google.android.tvrecommendations is left out: something else
# binds it and the system restarts it within a second of a force-stop.
STOP=(com.nes.coreservice com.tivo.sageservice com.google.android.tvlauncher com.google.android.katniss)

for p in "${STOP[@]}"; do sh_tv am force-stop "$p"; done
sleep 3
alive="$(sh_tv ps -A | grep -E "$(IFS='|'; echo "${STOP[*]}")" | awk '{print $NF}' || true)"
echo "MemAvailable: $(sh_tv "awk '/MemAvailable/{print int(\$2/1024)}' /proc/meminfo") MB"
[[ -z "$alive" ]] && echo "Parados: ${STOP[*]}" || echo "Ainda vivos (o sistema religou): $alive"
