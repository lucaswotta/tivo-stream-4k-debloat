# 08 — Mapa do controle remoto

Controle Bluetooth `vendor=0x0471 product=0x1207`, mapeado por `/vendor/usr/keylayout/Vendor_0471_Product_1207.kl` (partição só leitura: sem root, o mapa não muda; só dá para escolher **quem responde** a cada tecla).

Como ler: `adb shell getevent -lt` mostra o código HID cru (`MSC_SCAN`); o `.kl` traduz para o keycode do Android.

| Botão | HID (`MSC_SCAN`) | Kernel | Keycode Android | Estado no aparelho |
|---|---|---|---|---|
| OK | `0c0041` | `KEY_SELECT` (353) | `DPAD_CENTER` | funciona |
| Guide | `0c008d` | `KEY_PROGRAM` (362) | `GUIDE` (172) | sem efeito: livre para remapear |
| TiVo (logo) | `0c003d` | `KEY_UNKNOWN` | `DVR` (173), via `key usage` | sem efeito: livre para remapear |
| Live | `0c003e` | `KEY_UNKNOWN` | `NES_SHORTCUT_10` (keycode próprio da NES, número a confirmar) | sem efeito |
| Skip | `0c00ce` | `KEY_UNKNOWN` | `MEDIA_SKIP_FORWARD` (272) | entendido pelos players |
| Netflix (provável) | `0c01c8` | — | `STEM_1` (265) | funciona |
| Apps | — | 580 | `ALL_APPS` | — |
| Assistente | — | 217 | `ASSIST` | — |

## Por que Guide e TiVo pararam

Nos aparelhos SEI/NES, `com.nes.tvglobalkeyhandler` é quem escuta os botões de atalho. Ele e o app do TiVo (`com.tivo.atom`) foram removidos pelo dono, então as teclas chegam ao Android e ninguém responde.

## Plano

O launcher do cleanyourtv tem `app_keys` (keycode → app). Proposta inicial, a decidir pelo dono:

- TiVo (`173`) → YouTube
- Guide (`172`) → Configurações
- Live → a definir quando o keycode for confirmado

Alternativa sem launcher novo: um app remapeador (Key Mapper ou Button Mapper), que usa serviço de acessibilidade.
