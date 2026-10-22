#!/usr/bin/env bash
# Send a theme's config.json to the cleanyourtv launcher (themes/README.md in that repo lists the keys) and
# restart it so it reads the file. Restarting switches accessibility off, so the key services go back on.
#
# Uso: scripts/push-theme.sh [pasta-do-tema]     (padrão: examples/tivo-stream-4k/theme)
#      scripts/push-theme.sh --reset             (remove o tema; volta ao config.xml)
source "$(dirname "$0")/_lib.sh"

PKG=com.gathin.tvhome
DIR=/sdcard/Android/data/$PKG/files
URI=content://$PKG.theme
TMP=/data/local/tmp/cyt-theme
connect

# The provider writes the file as the launcher; a plain cp from the shell would leave it owned by uid 2000,
# which the launcher cannot open on some Android versions. The revision marker makes it drop its on-TV choices.
put() {   # <name> <local file>
  adb -s "$TARGET" push "$2" "$TMP-$1" >/dev/null
  sh_tv "rm -f $DIR/$1 2>/dev/null; content write --uri $URI/$1 < $TMP-$1 || cp $TMP-$1 $DIR/$1; rm -f $TMP-$1"
}

sh_tv "mkdir -p $DIR"
revision="$(mktemp)"; date +%s%N > "$revision"
if [[ "${1:-}" == "--reset" ]]; then
  sh_tv "rm -f $DIR/config.json 2>/dev/null; content delete --uri $URI/config.json 2>/dev/null; true"
else
  theme="${1:-$ROOT/examples/tivo-stream-4k/theme}"
  python3 -I -c 'import json,sys; json.load(open(sys.argv[1]))' "$theme/config.json" \
    || { echo "$theme/config.json não é um JSON válido" >&2; exit 1; }
  put config.json "$theme/config.json"
fi
put theme_revision "$revision"; rm -f "$revision"

sh_tv am force-stop "$PKG"
sh_tv am start -n "$PKG/.MainActivity" >/dev/null
sleep 2
enable_services dev.lucaswotta.homekey/.HomeKeyService "$PKG/.HomeKeyService"
for _ in 1 2 3 4 5; do
  sleep 2
  bound="$(sh_tv dumpsys accessibility | grep -A1 'Bound services' || true)"
  [[ "$bound" == *"Home Key"* ]] && break
done
echo "Tema aplicado. Serviços: $(grep -o 'label=[^,]*' <<<"$bound" | tr '\n' ' ')"
