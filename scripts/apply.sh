#!/usr/bin/env bash
# Turns off the packages of a debloat list, optionally one group at a time. Per package it tries
# pm disable-user, then pm uninstall -k --user 0 (the APK stays in /system), then suspend + appops.
# On build SC.1272 every package in the TiVo list is a core app, so all of them end up suspended.
#
# Usage:
#   scripts/apply.sh examples/tivo-stream-4k/debloat.txt
#   scripts/apply.sh examples/tivo-stream-4k/debloat.txt --only "Telemetry"
#   DRY_RUN=1 scripts/apply.sh ...      # only prints what it would do
source "$(dirname "$0")/_lib.sh"

LIST="${1:?usage: apply.sh <list> [--only <group>]}"
ONLY=""
[[ "${2:-}" == "--only" ]] && ONLY="${3:?--only needs a group name}"

if head -1 "$LIST" | grep -q DRAFT && [[ -z "${FORCE_DRAFT:-}" ]]; then
  echo "$LIST is still a DRAFT. Test the groups and remove the DRAFT line, or set FORCE_DRAFT=1." >&2
  exit 1
fi

connect
ENABLED="$(sh_tv pm list packages -e | sed 's/^package://')"
LOG="$ROOT/runs/$(stamp)-apply.log"; mkdir -p "$ROOT/runs"

while IFS=$'\t' read -r group pkg; do
  [[ -n "$ONLY" && "$group" != *"$ONLY"* ]] && continue
  if ! valid_pkg "$pkg"; then echo "ignored (invalid name): $pkg"; continue; fi
  if is_core "$pkg"; then echo "REFUSED (essential Android package): $pkg"; continue; fi
  if ! grep -qx "$pkg" <<<"$ENABLED"; then echo "skipped (missing or already disabled): $pkg"; continue; fi

  if [[ -n "${DRY_RUN:-}" ]]; then echo "[dry-run] $group :: $pkg"; continue; fi

  # Strongest reversible method first. This firmware refuses disable-user and refuses uninstall for
  # "core" apps, so each package falls through: disable-user -> uninstall --user 0 -> suspend + appops.
  out="$(sh_tv pm disable-user --user 0 "$pkg" 2>&1 || true)"
  if grep -qi 'new state: disabled' <<<"$out"; then
    method=disable
  else
    out="$(sh_tv pm uninstall -k --user 0 "$pkg" 2>&1 || true)"
    if grep -qx 'Success' <<<"$out"; then
      method="uninstall --user 0 (undo with install-existing)"
    else
      sh_tv pm suspend --user 0 "$pkg" >/dev/null 2>&1 || true
      sh_tv cmd appops set "$pkg" RUN_ANY_IN_BACKGROUND ignore >/dev/null 2>&1 || true
      sh_tv am force-stop "$pkg" >/dev/null 2>&1 || true
      method="suspend + appops (${out//$'\n'/ })"
    fi
  fi
  echo "$(date +%T) $group :: $pkg -> $method" | tee -a "$LOG"
done < <(list_packages "$LIST")

echo
echo "Done. Test with the remote, then reboot (adb -s $TARGET reboot)."
