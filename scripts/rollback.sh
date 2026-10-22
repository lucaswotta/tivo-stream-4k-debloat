#!/usr/bin/env bash
# Undo everything apply.sh did for a list (or for one package), whichever method was used.
#
# Uso:
#   scripts/rollback.sh examples/tivo-stream-4k/debloat.txt
#   scripts/rollback.sh --pkg com.google.android.videos
#   scripts/rollback.sh <lista> --home com.google.android.tvlauncher   # devolve também a Home original
source "$(dirname "$0")/_lib.sh"
connect

restore() {
  local p="$1"
  valid_pkg "$p" || return 0
  sh_tv cmd package install-existing "$p" >/dev/null 2>&1 || true
  sh_tv pm enable "$p" >/dev/null 2>&1 || true
  sh_tv pm unsuspend --user 0 "$p" >/dev/null 2>&1 || true
  sh_tv cmd appops reset --user 0 "$p" >/dev/null 2>&1 || true
  echo "restaurado: $p"
}

if [[ "${1:-}" == "--pkg" ]]; then
  restore "${2:?--pkg precisa do nome do pacote}"
  exit 0
fi

LIST="${1:?uso: rollback.sh <lista> | --pkg <pacote>}"
# Restores commented-out packages too, so a line you commented after applying still comes back.
grep -oE '^[[:space:]]*#?[[:space:]]*[A-Za-z_][A-Za-z0-9_]*(\.[A-Za-z0-9_]+)+' "$LIST" \
  | sed -E 's/^[[:space:]]*#?[[:space:]]*//' | sort -u | while read -r p; do restore "$p"; done

if [[ "${2:-}" == "--home" ]]; then
  restore "${3:?--home precisa do pacote da Home}"
  sh_tv cmd package set-home-activity "$3" >/dev/null 2>&1 || true
fi
echo "Reinicie a TV para garantir: adb -s $TARGET reboot"
