#!/usr/bin/env bash
# Applies everything this project validated on a TiVo Stream 4K, in an order that cannot leave the TV
# without a way to open apps: tools, build, install, theme, settings, debloat, and the stock launcher last.
# Every step is reversible (scripts/rollback.sh, scripts/install-launcher.sh --remove, docs/10-bootclean.md).
#
# Uso: TV_HOST=<ip> scripts/apply-all.sh              (explica e pergunta antes)
#      TV_HOST=<ip> scripts/apply-all.sh --dry-run    (só mostra o plano e o que o apply.sh faria)
#      TV_HOST=<ip> scripts/apply-all.sh --yes        (sem perguntar)
#      --with-owner-removals   também remove os apps listados em "Already removed by the owner"
#      --skip-build            usa os APKs que já existem em launcher/, homekey/ e bootclean/
# As escolhas do dono (foco sem destaque, botões do controle, Assistente trocado) ficam em scripts/personal.sh.
source "$(dirname "$0")/_lib.sh"

DRY="" YES="" OWNER="" SKIP_BUILD=""
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY=1 ;; --yes) YES=1 ;; --with-owner-removals) OWNER=1 ;; --skip-build) SKIP_BUILD=1 ;;
    *) echo "opção desconhecida: $arg" >&2; exit 1 ;;
  esac
done
LIST="$ROOT/examples/tivo-stream-4k/debloat.txt"
TOOLCHAIN="${TOOLCHAIN:-$HOME/.local/share/tivo-toolchain}"
step() { echo; echo "== $*"; }
run() { if [[ -n "$DRY" ]]; then echo "[dry-run] $*"; else "$@"; fi; }

connect
MODEL="$(sh_tv getprop ro.product.model)"; BUILD="$(sh_tv getprop ro.build.display.id)"; SDK="$(sh_tv getprop ro.build.version.sdk)"
echo "Aparelho: $MODEL, build $BUILD, SDK $SDK"
if [[ "$MODEL" != "TiVo Stream 4K" || "$SDK" != 31 ]]; then
  echo "AVISO: validado só no TiVo Stream 4K com Android 12 (build 1272). Este aparelho é diferente." >&2
  [[ -n "$YES" || -n "$DRY" ]] || { read -r -p "Continuar mesmo assim? [s/N] " a; [[ "$a" == [sSyY]* ]] || exit 1; }
fi

cat <<'TXT'

O que será feito (a base; as preferências pessoais ficam em scripts/personal.sh):
  1. Baixar JDK 17 e Android SDK (fontes oficiais, checksum conferido), se ainda não houver.
  2. Compilar o launcher do cleanyourtv sem a categoria HOME, o serviço da tecla Home e o bootclean.
  3. Instalar os três e ligar os serviços de acessibilidade.
  4. Aplicar um tema simples (dock com Netflix, Prime e YouTube; menu ao segurar OK).
  5. Desligar o ouvinte de notificações do tvrecommendations e usar o relógio do launcher como protetor de tela.
  6. Suspender 14 pacotes (telemetria, serviços NES e TiVo, recomendações, protetor de tela original, apps sem uso), sem desinstalar.
  7. Tirar o launcher original do papel HOME e suspendê-lo (por último).
Não mexe no Assistente do Google, nos botões do controle nem no zoom do foco.
Efeitos que você deve aceitar:
  - O bootclean fica com uma chave de depuração USB autorizada para sempre e roda comandos fixos no boot.
  - O Downloader e outros 52 apps da lista de fábrica do coreservice continuam sendo removidos a cada boot.
TXT
if [[ -z "$YES" && -z "$DRY" ]]; then read -r -p "Aplicar? [s/N] " a; [[ "$a" == [sSyY]* ]] || { echo "nada foi alterado"; exit 0; }; fi

step "1/7 ferramentas de build"
if [[ -n "$SKIP_BUILD" ]]; then echo "pulado (--skip-build)"
elif [[ -x "$TOOLCHAIN/sdk/build-tools/35.0.0/d8" && -x "$TOOLCHAIN/jdk17/bin/java" ]]; then echo "já existem em $TOOLCHAIN"
else run "$ROOT/scripts/setup-toolchain.sh"; fi

step "2/7 compilar"
if [[ -n "$SKIP_BUILD" ]]; then echo "pulado (--skip-build)"; else run "$ROOT/scripts/build-launcher.sh"; fi

step "3/7 instalar launcher, serviço da tecla Home e bootclean"
if [[ -n "$DRY" ]]; then echo "[dry-run] scripts/install-launcher.sh"; else
  echo "Olhe a TV: na primeira vez, aceite o aviso de depuração USB do bootclean com 'Sempre permitir' (com a TV acordada, sem protetor de tela)."
  "$ROOT/scripts/install-launcher.sh"
fi

step "4/7 tema"
run "$ROOT/scripts/push-theme.sh"

step "5/7 ouvinte de notificações do tvrecommendations e protetor de tela"
run sh_tv cmd notification disallow_listener com.google.android.tvrecommendations/com.google.android.tvrecommendations.NotificationsService
run sh_tv "settings put secure screensaver_components com.gathin.tvhome/.ClockDream; settings put secure screensaver_default_component com.gathin.tvhome/.ClockDream; settings put secure screensaver_enabled 1"

step "6/7 debloat (suspender, sem desinstalar)"
[[ -n "$DRY" ]] && export DRY_RUN=1
for group in "Telemetry and feedback" "App blocker and NES services" "Recommendations, partner rows" "Preloaded apps"; do
  "$ROOT/scripts/apply.sh" "$LIST" --only "$group" | grep -v '^$' | grep -v '^Feito'
done
[[ -n "$OWNER" ]] && "$ROOT/scripts/apply.sh" "$LIST" --only "Already removed" | grep -v '^$' | grep -v '^Feito'

step "7/7 launcher antigo (por último, depois de o novo estar instalado)"
# The stock launcher owns the HOME role, and Android refuses to suspend the role holder.
run sh_tv cmd package set-home-activity --user 0 com.android.tv.settings/.system.FallbackHome
"$ROOT/scripts/apply.sh" "$LIST" --only "Stock launcher and unused" | grep -v '^$' | grep -v '^Feito'

if [[ -z "$DRY" ]]; then
  step "conferência"
  sleep 20
  "$ROOT/scripts/status.sh"
  echo
  echo "Teste a tecla Home do controle. Depois reinicie a TV e rode scripts/status.sh uns 6 minutos depois. Preferências pessoais: scripts/personal.sh."
fi
