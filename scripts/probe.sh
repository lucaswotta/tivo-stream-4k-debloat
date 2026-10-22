#!/usr/bin/env bash
# Read-only inventory of the TiVo. Changes nothing. Output: runs/<stamp>-probe/
#
# Uso: TV_HOST=192.168.0.50 scripts/probe.sh
source "$(dirname "$0")/_lib.sh"
connect

OUT="$ROOT/runs/$(stamp)-probe"
mkdir -p "$OUT"
echo "Salvando em $OUT"

{
  for p in ro.build.fingerprint ro.build.version.release ro.build.version.sdk \
           ro.build.version.security_patch ro.product.model ro.product.device \
           ro.product.manufacturer ro.board.platform ro.product.cpu.abi; do
    printf '%-34s %s\n' "$p" "$(sh_tv getprop "$p")"
  done
} | tee "$OUT/device.txt"

sh_tv pm list packages -s   | sed 's/^package://' | sort > "$OUT/packages-system.txt"
sh_tv pm list packages -3   | sed 's/^package://' | sort > "$OUT/packages-user.txt"
sh_tv pm list packages -d   | sed 's/^package://' | sort > "$OUT/packages-disabled.txt"
sh_tv pm list packages -e   | sed 's/^package://' | sort > "$OUT/packages-enabled.txt"
grep -iE 'tivo|nes\.|sei|droidlogic|partner|autoinstall|amlogic' "$OUT/packages-system.txt" \
  > "$OUT/packages-vendor.txt" || true

sh_tv cmd package query-activities --brief -a android.intent.action.MAIN \
  -c android.intent.category.HOME > "$OUT/home-claimants.txt" || true
sh_tv dumpsys wifi 2>/dev/null | grep -o 'cname=[^ ]*' | sort -u > "$OUT/wifi-owners.txt" || true
sh_tv dumpsys meminfo > "$OUT/meminfo.txt"
sh_tv ps -A -o NAME,RSS > "$OUT/processes.txt" 2>/dev/null || sh_tv ps -A > "$OUT/processes.txt"

if grep -qx com.nes.coreservice "$OUT/packages-system.txt"; then
  sh_tv dumpsys package com.nes.coreservice > "$OUT/coreservice-package.txt"
fi

# Does this firmware allow pm disable-user? Ask on a harmless package and undo right away.
TEST=com.android.printspooler
if grep -qx "$TEST" "$OUT/packages-enabled.txt"; then
  R="$(sh_tv pm disable-user --user 0 "$TEST" 2>&1 || true)"
  sh_tv pm enable "$TEST" >/dev/null 2>&1 || true
  echo "$R" > "$OUT/disable-test.txt"
fi

cat <<EOF

Resumo
  Android:            $(sh_tv getprop ro.build.version.release)
  Pacotes de sistema: $(wc -l < "$OUT/packages-system.txt")
  Pacotes do usuário: $(wc -l < "$OUT/packages-user.txt")
  Já desabilitados:   $(wc -l < "$OUT/packages-disabled.txt")
  Pacotes NES/vendor: $(wc -l < "$OUT/packages-vendor.txt")
  CoreService:        $(grep -qx com.nes.coreservice "$OUT/packages-system.txt" && echo presente || echo ausente)
  Wi-Fi pertence a:   $(tr '\n' ' ' < "$OUT/wifi-owners.txt")
  pm disable-user:    $(cat "$OUT/disable-test.txt" 2>/dev/null || echo 'não testado')
EOF
