# 08 — Mapa do controle remoto

[English](../08-remote.md)

Controle Bluetooth `vendor=0x0471 product=0x1207`, mapeado por `/vendor/usr/keylayout/Vendor_0471_Product_1207.kl`. A partição é somente leitura: sem root o mapa não muda, e só dá para escolher quem responde a cada tecla.

| Botão | HID (`MSC_SCAN`) | Keycode do Android | Scancode | No tema pessoal |
|---|---|---|---|---|
| OK | `0c0041` | `DPAD_CENTER` | 353 | seleciona; segurar abre o menu do app |
| Guide | `0c008d` | `GUIDE` (172) | 362 | abre as Configurações |
| TiVo (logo) | `0c003d` | `DVR` (173) | 240 | abre o YouTube |
| Live | `0c003e` | 5124 (`NES_SHORTCUT_10`) | 240 | livre: o tema publicado não o mapeia |
| Skip | `0c00ce` | `MEDIA_SKIP_FORWARD` (272) | 240 | entendido pelos players |
| Netflix | `0c01c8` | `STEM_1` (265) | — | funciona sem configuração |
| Apps | — | `ALL_APPS` | 580 | — |
| Assistente | `0c0221` (`KEY_SEARCH`) | `ASSIST` | 217 | abre a Play Store (ver abaixo) |

`adb shell getevent -lt` mostra só o código HID cru (`MSC_SCAN`), que não serve para mapear. Os keycodes foram lidos em 2026-10-22 com um log temporário em `onKeyEvent` de um serviço de acessibilidade, apertando os botões reais. TiVo, Live e Skip compartilham o scancode 240, então só o keycode os distingue. O sistema registra os keycodes 5103, 5104 e 5115 a 5126 como atalhos globais da NES (`dumpsys window policy`), todos roteados para `com.nes.tvglobalkeyhandler`.

## Por que Guide, TiVo e Live não fazem nada de fábrica

Nos aparelhos SEI/NES, quem escuta os botões de atalho é o `com.nes.tvglobalkeyhandler`. Nesta unidade ele e o app da TiVo (`com.tivo.atom`) foram removidos pelo dono antes do projeto, então as teclas chegam ao Android e ninguém responde. O launcher do cleanyourtv passa a responder com `app_keys` e `settings_key_keycodes`.

## O botão do Assistente

O botão chega ao sistema (`KEY_SEARCH`, scancode 217, mapeado para `ASSIST` pelo `.kl`), mas nenhum serviço de acessibilidade o vê: com o log temporário, o serviço não recebeu evento enquanto o sistema registrava `HomeKeyReceiver: reason: assist`. O Android trata `ASSIST` antes do filtro de teclas, então `app_keys` não resolve.

O que funciona: o sistema manda `ACTION_ASSIST` ao componente do setting `assistant`. O `homekey` declara a `AssistActivity`, sem tela, que abre a Play Store e termina. O perfil pessoal do `bootclean` grava `assistant = dev.lucaswotta.homekey/.AssistActivity` e esvazia `voice_interaction_service` a cada boot, porque o Android os preenche de novo com o Katniss. Testado com o botão real, antes e depois de um reboot. O botão perde a voz; o microfone não foi testado com o Assistente do Google, e o toque longo não foi capturado.

## Configuração

No `config.json` do tema (`examples/tivo-stream-4k/theme-personal/`, ou a pasta em `PERSONAL_THEME`):

```json
"app_keys": ["173:com.google.android.youtube.tv", "5124:<pacote do app>"],
"settings_key_keycodes": [172]
```

`hold:173:<pacote>` dá um segundo app ao toque longo. Depois de editar, rode `scripts/push-theme.sh <pasta do tema>`.

O launcher só lê `app_keys` e `settings_key_keycodes` pelo `HomeKeyService` dele, que o `scripts/install-launcher.sh` liga junto com o serviço da tecla Home (`homekey/`). Os dois ficam ligados ao mesmo tempo.

Testado com os botões reais (log do `ActivityTaskManager`): Guide abriu `com.android.tv.settings/.MainSettings`, TiVo abriu o YouTube, Live abriu o app mapeado, e a tecla Home voltou ao launcher depois de cada um.
