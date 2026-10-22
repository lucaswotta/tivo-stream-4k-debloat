# 00 — Hardware e família do aparelho

![Etiqueta, com HSN e MAC removidos](img/etiqueta.jpg)

## O que a etiqueta diz

| Campo | Valor | Por que importa |
|---|---|---|
| Modelo | `IPA1104HDW 01 400 09T TIVO` | Identifica a revisão de hardware |
| SKU | `RA2400` | Versão de varejo dos EUA |
| FCC ID | `2AOVU-IPA1104HDW` | `2AOVU` é o código de concessionário da **SEI Robotics** |
| Alimentação | 5 V ⎓ 1 A | Use uma fonte que entregue isso de verdade; USB da TV às vezes não basta e causa travadas |
| Selos | Dolby Vision, Dolby Digital Plus, Bluetooth | |

> Nunca publique o HSN e o MAC da etiqueta. As fotos do repositório já estão tarjadas.

## A descoberta que mais ajuda: a família SEI/NES

O TiVo não foi fabricado pela TiVo. Quem fez foi a SEI Robotics, que usa a middleware **NES** em vários aparelhos de operadoras. Isso significa que o TiVo tem "primos" já documentados no cleanyourtv:

| Aparelho | Lista no cleanyourtv | O que aprendemos com ele |
|---|---|---|
| Nokia Streaming Box 8000 (SEI600NK4, Android TV 14) | `examples/nokia-streaming-box-8000/` | Mesmo launcher clássico com aba "Loja"; o firmware **recusou** `pm disable-user` e teve que usar `pm suspend` + `appops`. `com.nes.coreservice` foi mantido lá porque mistura LED, mensagens de OTA e um receptor de analytics |
| Dialog ViU (SEI103DL, Android TV 9) | `examples/dialog-viu-sei103dl/` | `com.nes.blerc` (controle Bluetooth) e `com.nes.tvglobalkeyhandler` (botões do controle) são essenciais; `com.nes.skywayclient` faz anúncios de boot e instalações silenciosas |

Hipóteses para confirmar no nosso aparelho:

- [x] O TiVo aceita `pm disable-user` ou recusa como o Nokia? **Recusa** (build 1272): `Warning! This command is illegal!`
- [ ] Quais `com.nes.*` existem e quais são carga estrutural?
- [ ] O `com.nes.coreservice` do TiVo faz as mesmas coisas que o do Nokia, mais a desinstalação?

## Especificações

| | |
|---|---|
| SoC | Amlogic S905Y2, 4× Cortex-A53 a ~1,8 GHz |
| GPU | Mali-G31 MP2 |
| RAM | 2 GB |
| Armazenamento | 8 GB |
| Vídeo | 4K HDR, Dolby Vision, HDR10+ |
| Lançamento | 2020, Android TV 9 → 10 → 12 via OTA |

## Limites que não vamos tentar quebrar

- **Bootloader travado**: não existe método público de desbloqueio nem ROM customizada.
- **Android 15/16**: exigiria bootloader aberto e port de kernel e drivers Amlogic. Fora de escopo.
- **Widevine L1**: qualquer modificação de sistema arriscaria derrubar Netflix e Prime para SD. Por isso o projeto é 100% ADB, sem tocar em partições.
