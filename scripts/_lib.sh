#!/usr/bin/env bash
# Shared helpers. Source from the other scripts; needs TV_HOST (IP of the TiVo).
set -euo pipefail

: "${TV_HOST:?set TV_HOST to the TiVo IP, e.g. export TV_HOST=192.168.0.50}"
command -v adb >/dev/null || { echo "adb not found: install the Android platform-tools" >&2; exit 1; }

TARGET="$TV_HOST"
[[ "$TARGET" == *:* ]] || TARGET="$TARGET:5555"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

connect() {
  adb connect "$TARGET" >/dev/null
  local state
  state="$(adb -s "$TARGET" get-state 2>/dev/null || true)"
  if [[ "$state" != "device" ]]; then
    echo "No connection to $TARGET (state: ${state:-none}). Accept this computer's key on the TV and try again." >&2
    exit 1
  fi
}

# </dev/null: adb shell otherwise reads the stdin of the caller's `while read` loop and ends it after one item.
sh_tv() { adb -s "$TARGET" shell "$@" </dev/null | tr -d '\r'; }

stamp() { date +%Y-%m-%d_%H%M; }

# Prints "group<TAB>package" for every active line of a debloat list.
# A group is the last comment line that followed a blank line.
list_packages() {
  awk 'NR==1{sub(/^\357\273\277/,"")} {sub(/\r$/,"")}
       /^[[:space:]]*$/ {blank=1; next}
       /^[[:space:]]*#/ {if (blank) {g=$0; sub(/^[[:space:]]*#[[:space:]]*/,"",g)} blank=0; next}
       {blank=0; sub(/[[:space:]]+#.*$/,""); print g "\t" $1}' "$1"
}

valid_pkg() { [[ "$1" =~ ^[A-Za-z_][A-Za-z0-9_]*(\.[A-Za-z0-9_]+)+$ ]]; }

# Packages that can stop Android from booting. Never touched, whatever the list says.
is_core() {
  [[ "$1" =~ ^(android|com\.android\.systemui|com\.android\.shell|com\.android\.phone|com\.android\.settings|com\.android\.tv\.settings|com\.android\.vending|com\.google\.android\.gms|com\.android\.providers\..*|com\.(google\.)?android\.(permissioncontroller|packageinstaller|ext\.services|ext\.shared|modulemetadata))$ ]]
}

# Turns the given accessibility services on without dropping others already enabled. A force-stop of an
# app switches accessibility off and removes its services from the list, so call this after one too.
enable_services() {
  local current svc
  for svc in "$@"; do
    current="$(sh_tv settings get secure enabled_accessibility_services)"
    case ":$current:" in
      *":$svc:"*) ;;
      *:null:|*::) sh_tv settings put secure enabled_accessibility_services "$svc" ;;
      *) sh_tv settings put secure enabled_accessibility_services "$current:$svc" ;;
    esac
  done
  sh_tv settings put secure accessibility_enabled 1
}
