#!/usr/bin/env bash
# Baseline / after numbers for the README table. Changes nothing except closing the measured apps.
#
# Uso: scripts/bench.sh <fase> [--boot] [--runs N]
#   fase: rótulo livre, ex.: antes, depois, lote1
source "$(dirname "$0")/_lib.sh"

PHASE="${1:?uso: bench.sh <fase> [--boot] [--runs N]}"; shift
BOOT=""; RUNS=3
while [[ $# -gt 0 ]]; do
  case "$1" in
    --boot) BOOT=1 ;;
    --runs) RUNS="$2"; shift ;;
  esac; shift
done

APPS=(com.google.android.youtube.tv com.netflix.ninja com.amazon.amazonvideo.livingroom)

connect
OUT="$ROOT/runs/$(stamp)-bench-$PHASE"; mkdir -p "$OUT"
CSV="$OUT/results.csv"
echo "run,metric,value,unit" > "$CSV"
rec() { echo "$1,$2,$3,$4" >> "$CSV"; printf '  %-28s %s %s\n' "$2" "$3" "$4"; }

home_pkg() {
  sh_tv cmd package resolve-activity --brief -a android.intent.action.MAIN \
    -c android.intent.category.HOME | tail -1 | cut -d/ -f1
}

wait_boot() {
  local t0=$SECONDS
  adb -s "$TARGET" reboot
  sleep 15
  until adb connect "$TARGET" >/dev/null 2>&1 && [[ "$(sh_tv getprop sys.boot_completed 2>/dev/null)" == 1 ]]; do
    sleep 2
    (( SECONDS - t0 > 300 )) && { echo "a TV não voltou em 5 min" >&2; exit 1; }
  done
  echo $(( SECONDS - t0 ))
}

for r in $(seq 1 "$RUNS"); do
  echo "Rodada $r/$RUNS"
  if [[ -n "$BOOT" ]]; then
    rec "$r" boot_seconds "$(wait_boot)" s
    sleep 180   # deixa os serviços de boot assentarem antes de medir memória
  fi

  sh_tv input keyevent KEYCODE_HOME; sleep 5
  rec "$r" mem_available_mb "$(sh_tv cat /proc/meminfo | awk '/MemAvailable/{print int($2/1024)}')" MB
  rec "$r" processes "$(sh_tv ps -A | tail -n +2 | wc -l | tr -d ' ')" count
  rec "$r" packages_enabled "$(sh_tv pm list packages -e | wc -l | tr -d ' ')" count

  H="$(home_pkg)"
  rec "$r" "launcher_pss_mb($H)" "$(sh_tv dumpsys meminfo "$H" | awk '/TOTAL PSS:|^ *TOTAL /{print int($2/1024); exit}')" MB

  for app in "${APPS[@]}"; do
    sh_tv pm path "$app" >/dev/null 2>&1 || continue
    comp="$(sh_tv cmd package resolve-activity --brief -a android.intent.action.MAIN \
            -c android.intent.category.LEANBACK_LAUNCHER "$app" | tail -1)"
    [[ "$comp" == */* ]] || continue
    sh_tv am force-stop "$app"; sleep 2
    t="$(sh_tv am start -W -n "$comp" | awk -F': ' '/TotalTime/{print $2}')"
    rec "$r" "cold_start_ms($app)" "${t:-NA}" ms
    sleep 3; sh_tv am force-stop "$app"; sh_tv input keyevent KEYCODE_HOME; sleep 3
  done
  sh_tv dumpsys meminfo > "$OUT/meminfo-run$r.txt"
done

echo
echo "Medianas ($RUNS rodadas):"
# Portable median (macOS awk has no asort): sort numerically per metric, take the middle value.
tail -n +2 "$CSV" | cut -d, -f2 | sort -u | while read -r m; do
  vals="$(awk -F, -v m="$m" '$2==m && $3!="NA"{print $3}' "$CSV" | sort -n)"
  n="$(printf '%s\n' "$vals" | grep -c . || true)"
  med="$( [[ "$n" -gt 0 ]] && printf '%s\n' "$vals" | sed -n "$(( (n + 1) / 2 ))p" || echo NA)"
  unit="$(awk -F, -v m="$m" '$2==m{print $4; exit}' "$CSV")"
  printf '  %-40s %s %s\n' "$m" "$med" "$unit"
done | tee "$OUT/summary.txt"
echo "Dados em $OUT"
