#!/usr/bin/env bash
# Shared helpers. Source from the other scripts; needs TV_HOST (IP of the TiVo).
set -euo pipefail

: "${TV_HOST:?defina TV_HOST com o IP do TiVo, ex.: export TV_HOST=192.168.0.50}"
command -v adb >/dev/null || { echo "adb não encontrado: instale o Android platform-tools" >&2; exit 1; }

TARGET="$TV_HOST"
[[ "$TARGET" == *:* ]] || TARGET="$TARGET:5555"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

connect() {
  adb connect "$TARGET" >/dev/null
  local state
  state="$(adb -s "$TARGET" get-state 2>/dev/null || true)"
  if [[ "$state" != "device" ]]; then
    echo "Sem conexão com $TARGET (estado: ${state:-nenhum}). Aceite a chave do PC na TV e tente de novo." >&2
    exit 1
  fi
}

sh_tv() { adb -s "$TARGET" shell "$@" | tr -d '\r'; }

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
