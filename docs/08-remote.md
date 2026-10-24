# 08 — Remote control map

[Português](pt-BR/08-controle.md)

Bluetooth remote `vendor=0x0471 product=0x1207`, mapped by `/vendor/usr/keylayout/Vendor_0471_Product_1207.kl`. The partition is read-only: without root the map does not change, and you can only choose who answers each key.

| Button | HID (`MSC_SCAN`) | Android keycode | Scancode | In the personal theme |
|---|---|---|---|---|
| OK | `0c0041` | `DPAD_CENTER` | 353 | selects; hold opens the app menu |
| Guide | `0c008d` | `GUIDE` (172) | 362 | opens Settings |
| TiVo (logo) | `0c003d` | `DVR` (173) | 240 | opens YouTube |
| Live | `0c003e` | 5124 (`NES_SHORTCUT_10`) | 240 | free: the published theme does not map it |
| Skip | `0c00ce` | `MEDIA_SKIP_FORWARD` (272) | 240 | understood by players |
| Netflix | `0c01c8` | `STEM_1` (265) | — | works without configuration |
| Apps | — | `ALL_APPS` | 580 | — |
| Assistant | `0c0221` (`KEY_SEARCH`) | `ASSIST` | 217 | opens the Play Store (see below) |

`adb shell getevent -lt` shows only the raw HID code (`MSC_SCAN`), which is no use for mapping. The keycodes were read on 2026-10-22 with a temporary log in an accessibility service's `onKeyEvent`, pressing the real buttons. TiVo, Live and Skip share scancode 240, so only the keycode tells them apart. The system registers keycodes 5103, 5104 and 5115 to 5126 as NES global shortcuts (`dumpsys window policy`), all routed to `com.nes.tvglobalkeyhandler`.

## Why Guide, TiVo and Live do nothing out of the box

On SEI/NES devices, `com.nes.tvglobalkeyhandler` listens to the shortcut buttons. On this unit it and the TiVo app (`com.tivo.atom`) were removed by the owner before this project, so the keys reach Android and nobody answers. cleanyourtv's launcher answers them through `app_keys` and `settings_key_keycodes`.

## The Assistant button

The button reaches the system (`KEY_SEARCH`, scancode 217, mapped to `ASSIST` by the `.kl`), but no accessibility service sees it: with the temporary log, the service got no event while the system logged `HomeKeyReceiver: reason: assist`. Android handles `ASSIST` before the key filter, so `app_keys` cannot catch it.

What works: the system sends `ACTION_ASSIST` to the component in the `assistant` setting. `homekey` declares `AssistActivity`, with no UI, which opens the Play Store and finishes. The personal `bootclean` profile writes `assistant = dev.lucaswotta.homekey/.AssistActivity` and empties `voice_interaction_service` at every boot, because Android fills both with Katniss again. Tested with the real button, before and after a reboot. The button loses voice; the microphone was not tested with the Google Assistant, and the long press was not captured.

## Configuration

In the theme's `config.json` (`examples/tivo-stream-4k/theme-personal/`, or the folder in `PERSONAL_THEME`):

```json
"app_keys": ["173:com.google.android.youtube.tv", "5124:<app package>"],
"settings_key_keycodes": [172]
```

`hold:173:<package>` gives a second app to the long press. After editing, run `scripts/push-theme.sh <theme folder>`.

The launcher only reads `app_keys` and `settings_key_keycodes` through its own `HomeKeyService`, which `scripts/install-launcher.sh` turns on together with the Home key service (`homekey/`). Both stay on at the same time.

Tested with the real buttons (`ActivityTaskManager` log): Guide opened `com.android.tv.settings/.MainSettings`, TiVo opened YouTube, Live opened the mapped app, and the Home key went back to the launcher after each.
