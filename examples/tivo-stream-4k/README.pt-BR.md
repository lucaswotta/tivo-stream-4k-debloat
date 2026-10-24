# TiVo Stream 4K

[English](README.md)

TiVo Stream 4K `IPA1104HDW` (SKU `RA2400`), fabricado pela SEI Robotics, Amlogic S905Y2, 2 GB de RAM, Android TV 12 (SDK 31), build `eSTREAM4K/SEI400TV/SEI400TV:12/SC/1272`, patch de segurança 2025-07-05. Testado em 2026-10-22 em uma unidade, por um dia e vários reboots.

## Arquivos

- `debloat.txt`: pacotes por grupo, com o motivo de cada um. Aplicar com `scripts/apply-all.sh` ou grupo a grupo com `scripts/apply.sh --only`.
- `theme/config.json`: tema da base para o launcher do cleanyourtv (dock com Netflix, Prime Video e YouTube; menu ao segurar OK).
- `theme-personal/config.json`: escolhas do dono (sem animações, título acima da dock, Play Store na dock, botões TiVo e Guide). Aplicado por `scripts/personal.sh`.

## Particularidades deste firmware

- `pm disable-user`, `pm hide` e `pm disable <componente>` são recusados. Todo pacote da base é suspenso (`pm suspend` mais `appops`). Desfazer: `scripts/rollback.sh`.
- O launcher original tem a Home com prioridade 2 e não pode ser desabilitado. Um launcher instalado não o substitui por `set-home-activity` (responde `Success` e nada muda). A Home chega ao launcher novo por um serviço de acessibilidade (`homekey/`), e o launcher novo não declara a categoria HOME, porque o `com.nes.coreservice` desinstala todo app não-sistema que a declara.
- A porta 5555 abre assim que a Depuração USB liga, com autorização por chave; não há opção separada de depuração pela rede.
- O botão do Assistente (`ASSIST`) é tratado pelo Android antes do filtro de teclas: nenhum serviço o intercepta. O desvio é apontar o setting `assistant` para uma atividade que abre a Play Store.
- Keycodes do controle `0471:1207`: TiVo `173` (`DVR`), Guide `172` (`GUIDE`), Live `5124`, Skip `272`, Netflix `265` (`STEM_1`), Assistente `ASSIST` (scancode 217; o keycode 219 do Android nunca foi observado, porque nenhum serviço recebe essa tecla).
- Suspender não impede o boot de religar `coreservice`, `sageservice`, `tvlauncher`, `tvrecommendations`, `tvbugtracker` e, se suspenso, `katniss`: o `bootclean` os para.
- O `coreservice` remove a cada boot 53 pacotes da lista de fábrica, entre eles o Downloader.

## Mantidos de propósito

`com.uei.uas.tivo` (QuickSet: liga e desliga a TV pelo controle), `com.sei.hdmi.services` (HDMI-CEC), `com.nes.tivo.remote.pair` e `remote.ota` (controle), `com.google.android.apps.mediashell` (Chromecast), Play Store, Play Services, teclado e Configurações.

Detalhes e medições: [docs/pt-BR/](../../docs/pt-BR/).
