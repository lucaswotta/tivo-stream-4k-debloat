#!/usr/bin/env bash
# The owner's own choices, on top of scripts/apply-all.sh. Nothing here is needed for the rest to work, and
# every item is a matter of taste:
#   - focus: the stock focus ring without the white fill; the selected app grows 10% at once
#   - theme: no animations, big title above the dock, names only under the focused grid tile, short menu on hold OK
#   - remote: TiVo opens YouTube, Guide opens Settings, Assistant opens the Play Store
#   - Google Assistant, voice search and Google text-to-speech off
#
# PERSONAL_THEME points to another theme folder (config.json, optionally res/ with banners), so apps you do
# not want in the repository stay outside it. Default: examples/tivo-stream-4k/theme-personal.
#
# Usage: TV_HOST=<ip> scripts/personal.sh [--dry-run] [--yes]
#        TV_HOST=<ip> scripts/personal.sh --undo     (back to the base: Assistant, launcher and plain theme)
source "$(dirname "$0")/_lib.sh"

DRY="" YES="" UNDO=""
for arg in "$@"; do
  case "$arg" in --dry-run) DRY=1 ;; --yes) YES=1 ;; --undo) UNDO=1 ;; *) echo "unknown option: $arg" >&2; exit 1 ;; esac
done
LIST="$ROOT/examples/tivo-stream-4k/debloat.txt"
export PERSONAL_THEME="${PERSONAL_THEME:-$ROOT/examples/tivo-stream-4k/theme-personal}"
step() { echo; echo "== $*"; }
run() { if [[ -n "$DRY" ]]; then echo "[dry-run] $*"; else "$@"; fi; }

connect
[[ -n "$(sh_tv pm list packages com.gathin.tvhome)" ]] || { echo "Run scripts/apply-all.sh first: the launcher is not installed yet." >&2; exit 1; }

if [[ -n "$UNDO" ]]; then
  KATNISS=com.google.android.katniss/.search.serviceapi.KatnissVoiceInteractionService
  step "back to the base"
  run "$ROOT/scripts/rollback.sh" --pkg com.google.android.katniss
  run "$ROOT/scripts/rollback.sh" --pkg com.google.android.tts
  run sh_tv settings put secure assistant "$KATNISS"
  run sh_tv settings put secure voice_interaction_service "$KATNISS"
  run "$ROOT/scripts/build-launcher.sh"
  if [[ -n "$DRY" ]]; then echo "[dry-run] scripts/install-launcher.sh"; else "$ROOT/scripts/install-launcher.sh"; fi
  run "$ROOT/scripts/push-theme.sh"
  [[ -n "$DRY" ]] || { sleep 20; "$ROOT/scripts/status.sh"; }
  exit 0
fi

cat <<TXT

Personal layer (rebuilds the launcher with 4 more patches and bootclean with the personal profile):
  1. Focus: the stock focus ring without the white fill; the selected app grows 10%, at once.
  2. Theme from $PERSONAL_THEME:
     no animations, big title above the dock, names only under the focused grid tile.
  3. Remote buttons from the theme's app_keys (published theme: TiVo opens YouTube, Guide opens Settings).
  4. Google Assistant off: the Assistant button opens the Play Store; katniss and tts are suspended.
Back to the base: scripts/personal.sh --undo.
TXT
if [[ -z "$YES" && -z "$DRY" ]]; then read -r -p "Apply? [y/N] " a; [[ "$a" == [yY]* ]] || { echo "nothing was changed"; exit 0; }; fi

step "1/4 build the personal variant"
run "$ROOT/scripts/build-launcher.sh" --personal

step "2/4 install"
if [[ -n "$DRY" ]]; then echo "[dry-run] scripts/install-launcher.sh"; else "$ROOT/scripts/install-launcher.sh"; fi

step "3/4 personal theme and remote buttons"
run "$ROOT/scripts/push-theme.sh" "$PERSONAL_THEME"

step "4/4 Assistant"
[[ -n "$DRY" ]] && export DRY_RUN=1
"$ROOT/scripts/apply.sh" "$LIST" --only "Google Assistant" | grep -v '^$' | grep -v '^Done'

if [[ -z "$DRY" ]]; then
  step "check"
  sleep 20
  "$ROOT/scripts/status.sh" --personal
fi
