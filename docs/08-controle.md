# 08 — Mapa do controle remoto

Controle Bluetooth `vendor=0x0471 product=0x1207`, mapeado por `/vendor/usr/keylayout/Vendor_0471_Product_1207.kl` (partição só leitura: sem root, o mapa não muda; só dá para escolher **quem responde** a cada tecla).

Como ler: `adb shell getevent -lt` mostra o código HID cru (`MSC_SCAN`); o `.kl` traduz para o keycode do Android.

| Botão | HID (`MSC_SCAN`) | Keycode Android | Scancode | Ação configurada |
|---|---|---|---|---|
| OK | `0c0041` | `DPAD_CENTER` | 353 | seleciona; segurar abre o menu do app |
| Guide | `0c008d` | `GUIDE` (172) | 362 | abre as Configurações |
| TiVo (logo) | `0c003d` | `DVR` (173) | 240 | abre o YouTube |
| Live | `0c003e` | **5124** (`NES_SHORTCUT_10`) | 240 | abre o UniTV |
| Skip | `0c00ce` | `MEDIA_SKIP_FORWARD` (272) | 240 | entendido pelos players, não mapeado |
| Netflix | `0c01c8` | `STEM_1` (265) | — | funciona sem configuração |
| Apps | — | `ALL_APPS` | 580 | — |
| Assistente | — | `ASSIST` | 217 | — |

Keycodes lidos em 2026-10-22 por log temporário em `onKeyEvent` de um serviço de acessibilidade, com os botões reais (`getevent -lt` mostra o `MSC_SCAN` HID, que não serve para mapear). TiVo, Live e Skip compartilham o scancode 240, então só o keycode os distingue. O sistema registra os keycodes 5103, 5104 e 5115 a 5126 como atalhos globais da NES (`dumpsys window policy`), todos roteados para `com.nes.tvglobalkeyhandler`.

## Por que Guide e TiVo pararam

Nos aparelhos SEI/NES, `com.nes.tvglobalkeyhandler` é quem escuta os botões de atalho. Ele e o app do TiVo (`com.tivo.atom`) foram removidos pelo dono, então as teclas chegam ao Android e ninguém responde.

## Configuração

`examples/tivo-stream-4k/theme/config.json`, enviado por `scripts/push-theme.sh`:

```json
"app_keys": ["173:com.google.android.youtube.tv", "5124:com.global.unitviptv"],
"settings_key_keycodes": [172]
```

O launcher só lê `app_keys` e `settings_key_keycodes` por meio do `HomeKeyService` dele, que o `scripts/install-launcher.sh` liga junto com o serviço da tecla Home (`homekey/`). Os dois serviços ficam ligados ao mesmo tempo. Para outro app: troque o pacote na linha do keycode e rode o script de novo; `hold:173:pacote` dá um segundo app ao toque longo.

Testado com os botões reais (log do `ActivityTaskManager`): Guide abriu `com.android.tv.settings/.MainSettings`, TiVo abriu o YouTube, Live abriu o UniTV, e a tecla Home voltou ao launcher depois de cada um. Sem crash.
