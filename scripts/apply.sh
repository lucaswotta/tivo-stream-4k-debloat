#!/usr/bin/env bash
# Disable the packages of a debloat list, optionally one group at a time.
# Falls back to suspend + appops when the firmware refuses pm disable-user (as on the Nokia 8000).
#
# Uso:
#   scripts/apply.sh examples/tivo-stream-4k/debloat.txt
#   scripts/apply.sh examples/tivo-stream-4k/debloat.txt --only "Telemetry"
#   DRY_RUN=1 scripts/apply.sh ...      # só mostra o que faria
source "$(dirname "$0")/_lib.sh"

LIST="${1:?uso: apply.sh <lista> [--only <grupo>]}"
ONLY=""
[[ "${2:-}" == "--only" ]] && ONLY="${3:?--only precisa do nome do grupo}"

if head -1 "$LIST" | grep -q DRAFT && [[ -z "${FORCE_DRAFT:-}" ]]; then
  echo "$LIST ainda é rascunho (DRAFT). Teste os lotes e tire a linha DRAFT, ou use FORCE_DRAFT=1." >&2
  exit 1
fi

connect
ENABLED="$(sh_tv pm list packages -e | sed 's/^package://')"
LOG="$ROOT/runs/$(stamp)-apply.log"; mkdir -p "$ROOT/runs"

while IFS=$'\t' read -r group pkg; do
  [[ -n "$ONLY" && "$group" != *"$ONLY"* ]] && continue
  if ! valid_pkg "$pkg"; then echo "ignorado (nome inválido): $pkg"; continue; fi
  if is_core "$pkg"; then echo "RECUSADO (pacote essencial do Android): $pkg"; continue; fi
  if ! grep -qx "$pkg" <<<"$ENABLED"; then echo "pulado (não existe ou já desabilitado): $pkg"; continue; fi

  if [[ -n "${DRY_RUN:-}" ]]; then echo "[dry-run] $group :: $pkg"; continue; fi

  out="$(sh_tv pm disable-user --user 0 "$pkg" 2>&1 || true)"
  if grep -qi 'new state: disabled' <<<"$out"; then
    method=disable
  else
    sh_tv pm suspend --user 0 "$pkg" >/dev/null 2>&1 || true
    sh_tv cmd appops set "$pkg" RUN_ANY_IN_BACKGROUND ignore >/dev/null 2>&1 || true
    sh_tv am force-stop "$pkg" >/dev/null 2>&1 || true
    method="suspend (disable recusado: ${out//$'\n'/ })"
  fi
  echo "$(date +%T) $group :: $pkg -> $method" | tee -a "$LOG"
done < <(list_packages "$LIST")

echo
echo "Feito. Teste com o controle, reinicie (adb -s $TARGET reboot) e anote em docs/diario.md."
