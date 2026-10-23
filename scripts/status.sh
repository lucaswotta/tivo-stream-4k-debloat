#!/usr/bin/env bash
# Read-only snapshot of the TV against what docs/diario.md says was validated. Changes nothing.
#
# Uso: TV_HOST=<ip> scripts/status.sh              (estado da base, scripts/apply-all.sh)
#      TV_HOST=<ip> scripts/status.sh --personal   (base + scripts/personal.sh)
source "$(dirname "$0")/_lib.sh"
PERSONAL=""; [[ "${1:-}" == --personal ]] && PERSONAL=1
connect

ok() { [[ "$2" == "$3" ]] && echo "  ok   $1" || echo "  FALTA $1 (esperado '$3', veio '$2')"; }

echo "aparelho: $(sh_tv getprop ro.product.model) / Android $(sh_tv getprop ro.build.version.release) / uptime $(sh_tv uptime -p) / perfil conferido: $([[ -n "$PERSONAL" ]] && echo personal || echo base)"
echo "launcher e serviços:"
ok "launcher instalado (com.gathin.tvhome)" "$(sh_tv pm list packages com.gathin.tvhome | wc -l | tr -d ' ')" 1
ok "homekey instalado" "$(sh_tv pm list packages dev.lucaswotta.homekey | wc -l | tr -d ' ')" 1
ok "bootclean instalado" "$(sh_tv pm list packages dev.lucaswotta.bootclean | wc -l | tr -d ' ')" 1
bound="$(sh_tv dumpsys accessibility | grep -A1 'Bound services' | grep -o 'label=[^,]*' | sort | tr '\n' ' ')"
ok "serviços de tecla ligados" "$bound" "label=Botão Home label=Home Key "
ok "ouvintes de notificação vazios" "$(sh_tv settings get secure enabled_notification_listeners)" ""
ok "protetor de tela é o do launcher" "$(sh_tv settings get secure screensaver_components)" "com.gathin.tvhome/.ClockDream"
if [[ -n "$PERSONAL" ]]; then
  ok "Assistente aponta para o homekey" "$(sh_tv settings get secure assistant)" "dev.lucaswotta.homekey/.AssistActivity"
  ok "voice_interaction_service vazio" "$(sh_tv settings get secure voice_interaction_service)" ""
  ok "tema pessoal no aparelho" "$(sh_tv 'grep -c reduced_motion /sdcard/Android/data/com.gathin.tvhome/files/config.json 2>/dev/null')" 1
fi
echo "em foco: $(sh_tv dumpsys activity activities | grep -m1 mFocusedApp | sed -E 's/.*u0 ([^ ]+) .*/\1/')"

SUSPENDED=(com.google.android.feedback com.google.android.partnersetup com.nes.tvbugtracker com.nes.coreservice com.nes.daemon
  com.tivo.sageservice com.google.android.tvrecommendations android.autoinstalls.config.sei com.android.printspooler
  com.google.android.marvin.talkback com.google.android.tvlauncher com.google.android.backdrop com.android.camera2 com.android.gallery3d)
STOPPED=(com.nes.coreservice com.tivo.sageservice com.google.android.tvlauncher com.google.android.tvrecommendations com.nes.tvbugtracker)
if [[ -n "$PERSONAL" ]]; then SUSPENDED+=(com.google.android.katniss com.google.android.tts); STOPPED+=(com.google.android.katniss); fi

echo "suspensos esperados (${#SUSPENDED[@]}):"
for p in "${SUSPENDED[@]}"; do
  [[ "$(sh_tv dumpsys package "$p" | grep -oE 'suspended=[a-z]+' | head -1)" == suspended=true ]] || echo "  FALTA suspender $p"
done
echo "processos que o bootclean deve ter parado (vivos = problema, exceto nos primeiros minutos do boot):"
for p in "${STOPPED[@]}"; do
  [[ -n "$(sh_tv pidof "$p")" ]] && echo "  vivo: $p"
done
echo "MemAvailable: $(sh_tv "awk '/MemAvailable/{print int(\$2/1024)}' /proc/meminfo") MB"
