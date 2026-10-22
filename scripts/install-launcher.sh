#!/usr/bin/env bash
# Install launcher/HomeLite.apk and turn its Home-key service on. Reinstalling clears the service
# setting, so every install has to enable it again. Other enabled accessibility services are kept.
#
# Uso: scripts/install-launcher.sh [--build]
#      scripts/install-launcher.sh --remove     # desliga o serviço e desinstala; a Home volta ao original
source "$(dirname "$0")/_lib.sh"

PKG=dev.lucaswotta.homelite
SERVICE="$PKG/.HomeKeyService"
connect

if [[ "${1:-}" == "--remove" ]]; then
  current="$(sh_tv settings get secure enabled_accessibility_services)"
  rest="$(tr ':' '\n' <<<"$current" | grep -vx -e "$SERVICE" -e null -e '' | paste -sd: - || true)"
  if [[ -n "$rest" ]]; then sh_tv settings put secure enabled_accessibility_services "$rest"
  else sh_tv settings delete secure enabled_accessibility_services; sh_tv settings put secure accessibility_enabled 0; fi
  sh_tv pm uninstall "$PKG" || true
  sh_tv am start -a android.intent.action.MAIN -c android.intent.category.HOME >/dev/null
  echo "Removido. Home: $(sh_tv cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME | tail -1)"
  exit 0
fi

[[ "${1:-}" == "--build" ]] && "$ROOT/launcher/build.sh"
adb -s "$TARGET" install -r "$ROOT/launcher/HomeLite.apk" </dev/null

current="$(sh_tv settings get secure enabled_accessibility_services)"
case ":$current:" in
  *":$SERVICE:"*) ;;
  *:null:|*::) sh_tv settings put secure enabled_accessibility_services "$SERVICE" ;;
  *) sh_tv settings put secure enabled_accessibility_services "$current:$SERVICE" ;;
esac
sh_tv settings put secure accessibility_enabled 1

for _ in 1 2 3 4 5; do
  sleep 2
  sh_tv dumpsys accessibility | grep -q "Bound services:.*Home Lite" && { echo "Serviço ativo."; exit 0; }
done
echo "O serviço não ligou. Confira Configurações > Acessibilidade." >&2
exit 1
