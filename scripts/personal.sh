#!/usr/bin/env bash
# The owner's own choices, on top of scripts/apply-all.sh. Nothing here is needed for the rest to work, and
# every item is a matter of taste:
#   - focus: no border, halo or sheen; the selected app only grows 10%, at once; no app names under the tiles
#   - theme: no animations, no big title above the dock, dock with UniTV, short menu on hold OK
#   - remote: TiVo opens YouTube, Live opens UniTV, Guide opens Settings, Assistant opens the Play Store
#   - Google Assistant and voice search off (the Assistant button goes to a screen that opens the Play Store)
#
# Uso: TV_HOST=<ip> scripts/personal.sh [--dry-run] [--yes]
#      TV_HOST=<ip> scripts/personal.sh --undo     (volta à base: Assistente, zoom do foco e tema simples)
source "$(dirname "$0")/_lib.sh"

DRY="" YES="" UNDO=""
for arg in "$@"; do
  case "$arg" in --dry-run) DRY=1 ;; --yes) YES=1 ;; --undo) UNDO=1 ;; *) echo "opção desconhecida: $arg" >&2; exit 1 ;; esac
done
LIST="$ROOT/examples/tivo-stream-4k/debloat.txt"
step() { echo; echo "== $*"; }
run() { if [[ -n "$DRY" ]]; then echo "[dry-run] $*"; else "$@"; fi; }

connect
[[ -n "$(sh_tv pm list packages com.gathin.tvhome)" ]] || { echo "Rode scripts/apply-all.sh primeiro: o launcher ainda não está instalado." >&2; exit 1; }

if [[ -n "$UNDO" ]]; then
  KATNISS=com.google.android.katniss/.search.serviceapi.KatnissVoiceInteractionService
  step "voltar à base"
  run "$ROOT/scripts/rollback.sh" --pkg com.google.android.katniss
  run sh_tv settings put secure assistant "$KATNISS"
  run sh_tv settings put secure voice_interaction_service "$KATNISS"
  run "$ROOT/scripts/build-launcher.sh"
  if [[ -n "$DRY" ]]; then echo "[dry-run] scripts/install-launcher.sh"; else "$ROOT/scripts/install-launcher.sh"; fi
  run "$ROOT/scripts/push-theme.sh"
  [[ -n "$DRY" ]] || { sleep 20; "$ROOT/scripts/status.sh"; }
  exit 0
fi

cat <<'TXT'

Preferências pessoais (recompila o launcher com mais 3 patches e o bootclean com o perfil personal):
  1. Foco com o anel seletor de fábrica; o app selecionado cresce 10%, na hora.
  2. Tema: sem animações, título grande acima do dock, nomes só nos apps da grade (a dock fica sem texto embaixo), UniTV no dock.
  3. Botões do controle: TiVo abre o YouTube, Live abre o UniTV, Guide abre as Configurações.
  4. Assistente do Google desligado: o botão do Assistente abre a Play Store e o Katniss é suspenso.
Para voltar à base: scripts/personal.sh --undo.
TXT
if [[ -z "$YES" && -z "$DRY" ]]; then read -r -p "Aplicar? [s/N] " a; [[ "$a" == [sSyY]* ]] || { echo "nada foi alterado"; exit 0; }; fi

step "1/4 compilar a variante personal"
run "$ROOT/scripts/build-launcher.sh" --personal

step "2/4 instalar"
if [[ -n "$DRY" ]]; then echo "[dry-run] scripts/install-launcher.sh"; else "$ROOT/scripts/install-launcher.sh"; fi

step "3/4 tema pessoal e botões do controle"
run "$ROOT/scripts/push-theme.sh" "$ROOT/examples/tivo-stream-4k/theme-personal"

step "4/4 Assistente"
[[ -n "$DRY" ]] && export DRY_RUN=1
"$ROOT/scripts/apply.sh" "$LIST" --only "Google Assistant" | grep -v '^$' | grep -v '^Feito'

if [[ -z "$DRY" ]]; then
  step "conferência"
  sleep 20
  "$ROOT/scripts/status.sh" --personal
fi
