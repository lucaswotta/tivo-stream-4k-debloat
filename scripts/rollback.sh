#!/usr/bin/env bash
# Undo everything apply.sh did for a list (or for one package), whichever method was used.
#
# Usage:
#   scripts/rollback.sh examples/tivo-stream-4k/debloat.txt
#   scripts/rollback.sh --pkg com.google.android.videos
#   scripts/rollback.sh <lista> --home com.google.android.tvlauncher   # also gives the Home back to the stock launcher
source "$(dirname "$0")/_lib.sh"
connect

restore() {
  local p="$1"
  valid_pkg "$p" || return 0
  sh_tv cmd package install-existing "$p" >/dev/null 2>&1 || true
  sh_tv pm enable "$p" >/dev/null 2>&1 || true
  sh_tv pm unsuspend --user 0 "$p" >/dev/null 2>&1 || true
  sh_tv cmd appops reset --user 0 "$p" >/dev/null 2>&1 || true
  echo "restored: $p"
}

if [[ "${1:-}" == "--pkg" ]]; then
  restore "${2:?--pkg needs a package name}"
  exit 0
fi

LIST="${1:?usage: rollback.sh <list> | --pkg <package>}"
# Restores commented-out packages too, so a line you commented after applying still comes back.
grep -oE '^[[:space:]]*#?[[:space:]]*[A-Za-z_][A-Za-z0-9_]*(\.[A-Za-z0-9_]+)+' "$LIST" \
  | sed -E 's/^[[:space:]]*#?[[:space:]]*//' | sort -u | while read -r p; do restore "$p"; done

if [[ "${2:-}" == "--home" ]]; then
  restore "${3:?--home needs the Home package}"
  sh_tv cmd package set-home-activity "$3" >/dev/null 2>&1 || true
fi
echo "Reboot the TV to be sure: adb -s $TARGET reboot"
