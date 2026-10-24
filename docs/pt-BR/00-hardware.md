# 00 — Hardware e família do aparelho

[English](../00-hardware.md)

![Etiqueta, com HSN e MAC removidos](../img/etiqueta.jpg)

## Etiqueta

| Campo | Valor | Por que importa |
|---|---|---|
| Modelo | `IPA1104HDW 01 400 09T TIVO` | identifica a revisão de hardware |
| SKU | `RA2400` | versão de varejo dos EUA |
| FCC ID | `2AOVU-IPA1104HDW` | `2AOVU` é o código de concessionário da SEI Robotics |
| Alimentação | 5 V ⎓ 1 A | a porta USB de algumas TVs não entrega isso e o aparelho trava; use uma fonte |
| Selos | Dolby Vision, Dolby Digital Plus, Bluetooth | |

Não publique o HSN nem o MAC da etiqueta. As fotos deste repositório estão tarjadas.

## Hardware, lido do aparelho

| Item | Valor |
|---|---|
| SoC | Amlogic S905Y2, 4 núcleos ARM de 100 MHz a 1,8 GHz, governor `interactive` |
| GPU | Mali-G31, OpenGL ES 3.2 |
| Memória | 2 GB |
| Userspace | 32 bits, só `armeabi-v7a` |
| Interface | 1920x1080 a 320 dpi |
| Decodificadores de hardware | H.264, H.265, VP9; sem AV1 |
| Sistema | Android TV 12 (SDK 31), build `eSTREAM4K/SEI400TV/SEI400TV:12/SC/1272`, patch 2025-07-05 |

O governor e a frequência pertencem ao usuário `system`, então o ADB não muda nenhum dos dois, e o bootloader é travado.

## A família SEI/NES

O TiVo Stream 4K foi fabricado pela SEI Robotics, que usa o middleware NES em aparelhos de várias operadoras. O cleanyourtv já documenta dois parentes:

| Aparelho | Lista no cleanyourtv | O que ele ensina |
|---|---|---|
| Nokia Streaming Box 8000 (SEI600NK4, Android TV 14) | `examples/nokia-streaming-box-8000/` | mesmo launcher clássico com aba Loja; o firmware recusa `pm disable-user` e a lista usa `pm suspend` e `appops`; o `com.nes.coreservice` foi mantido lá porque também cuida do LED, das mensagens de OTA e de um receptor de analytics |
| Dialog ViU (SEI103DL, Android TV 9) | `examples/dialog-viu-sei103dl/` | `com.nes.blerc` (controle Bluetooth) e `com.nes.tvglobalkeyhandler` (botões de atalho) são essenciais; `com.nes.skywayclient` faz anúncios no boot e instalações silenciosas |

Confirmado no TiVo, build `SC.1272`:

- `pm disable-user` é recusado, como no Nokia: `Warning! This command is illegal!`. Funcionam `pm suspend` e `appops`; `pm uninstall --user 0` funciona só para apps que não são core.
- Pacotes NES e TiVo presentes: `com.nes.coreservice`, `com.nes.daemon`, `com.nes.tvbugtracker`, `com.nes.tivo.quickset`, `com.nes.tivo.remote.ota`, `com.nes.tivo.remote.pair`, `com.tivo.sageservice`, `com.uei.uas.tivo` e `com.sei.hdmi.services`. Pareamento do controle, CEC e QuickSet ficam; o resto é suspenso.
- O `com.nes.coreservice` do TiVo faz o mesmo que o do Nokia e, além disso, desinstala no boot uma lista fixa de 53 pacotes e todo app não-sistema que declare a categoria HOME. Ver [03](03-coreservice.md).
