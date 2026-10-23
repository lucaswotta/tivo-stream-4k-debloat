# 04 — Debloat

A lista é `examples/tivo-stream-4k/debloat.txt`, no formato do cleanyourtv (um pacote por linha, `#` para comentários). Cada grupo da lista é um lote, e `scripts/apply.sh <lista> --only "<grupo>"` aplica um de cada vez. `scripts/apply-all.sh` aplica todos, na ordem abaixo.

## Método

Neste firmware (`SC.1272`, Android 12):

- `pm disable-user` é **recusado** (`Warning! This command is illegal!`) e `pm hide` e `pm disable <componente>` também.
- `pm uninstall -k --user 0` funciona só para apps que não são "core". Os demais respondem `is a core application in the system`.
- `pm suspend --user 0` e `cmd appops set <pkg> RUN_ANY_IN_BACKGROUND ignore` funcionam e sobrevivem a reboot.

Por isso o `apply.sh` tenta, por pacote: `disable-user`, depois `uninstall -k --user 0`, depois `suspend` + `appops` + `force-stop`. A lista deste projeto só tem apps core, então tudo cai em suspender. Reverter: `scripts/rollback.sh <lista>` ou `--pkg <pacote>`.

**Suspender não para o processo no boot.** O sistema ainda entrega os broadcasts de boot e mantém conexões, então `coreservice`, `sageservice`, `tvlauncher`, `katniss`, `tvrecommendations` e `tvbugtracker` voltam a rodar. Quem os para é o `bootclean` ([10](10-bootclean.md)), ou `scripts/post-boot.sh` pelo computador.

## Grupos, na ordem

| Grupo | Pacotes | Observação |
|---|---|---|
| Telemetry and feedback | `feedback`, `partnersetup`, `tvbugtracker` | `tv.bugreportsender` não existe nesta build |
| App blocker and NES services | `coreservice`, `daemon`, `sageservice` | `daemon` é persistente: suspender não o para. Ver [03](03-coreservice.md) |
| Recommendations, partner rows | `tvrecommendations`, `autoinstalls.config.sei` | o ouvinte de notificações do `tvrecommendations` também é desligado (`cmd notification disallow_listener`) |
| Preloaded apps | `printspooler`, `talkback` | |
| Stock launcher and unused | `tvlauncher`, `backdrop`, `camera2`, `gallery3d`, `katniss` | só **depois** de instalar o launcher novo; o papel HOME precisa sair do `tvlauncher` antes (`set-home-activity` para a `FallbackHome` das Configurações), porque o Android recusa suspender o dono do papel HOME |
| Already removed by the owner | `tivo.atom`, `skywayclient`, `tvglobalkeyhandler`, ... | só com `apply-all.sh --with-owner-removals`; `tvglobalkeyhandler` trata os botões de atalho do controle e `skywayclient` faz a verificação de firmware |

Também mexem em ajustes do sistema (não são pacotes): o Assistente (`assistant`, `voice_interaction_service`) e o protetor de tela (`screensaver_components`). O Assistente é regravado a cada boot pelo `bootclean`.

## Ciclo de cada lote

```bash
scripts/apply.sh examples/tivo-stream-4k/debloat.txt --only "<grupo>"
# testar com o controle: Home, voltar, volume, YouTube, Netflix, Prime
adb reboot
scripts/status.sh
```

## Não fazer

- Lançar pacotes de fábrica ou teste (`com.utsmta.app`, nomes com `factory` ou `fac`): em outros aparelhos isso muda flags que o shell não desfaz.
- Suspender `com.android.vending`, Play Services, `com.android.tv.settings`, o teclado, `sei.hdmi.services` (CEC), `uei.uas.tivo` (liga e desliga a TV pelo controle) nem `nes.tivo.remote.*` (pareamento e firmware do controle).
- Suspender `com.google.android.apps.mediashell` (Chromecast): testado, só quebra o cast e não libera memória, porque outro componente mantém uma conexão com ele.

## Atenção

- Atualização de firmware: se o serviço de OTA estiver suspenso, o aparelho pode deixar de atualizar. Rode `rollback.sh` antes de procurar atualização e a lista de novo depois.
- Antes de um reset de fábrica, rode `scripts/install-launcher.sh --remove` e `scripts/rollback.sh`.
