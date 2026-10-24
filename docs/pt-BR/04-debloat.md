# 04 — Debloat

[English](../04-debloat.md)

A lista é `examples/tivo-stream-4k/debloat.txt`, no formato do cleanyourtv: um pacote por linha, `#` para comentários, e cada bloco depois de uma linha em branco é um grupo. `scripts/apply.sh <lista> --only "<grupo>"` aplica um grupo; `scripts/apply-all.sh` aplica todos, na ordem abaixo.

## Método

Neste firmware (`SC.1272`, Android 12):

- `pm disable-user`, `pm hide` e `pm disable <componente>` são recusados.
- `pm uninstall -k --user 0` funciona só para apps que não são core; os outros respondem `is a core application in the system`.
- `pm suspend --user 0` e `cmd appops set <pacote> RUN_ANY_IN_BACKGROUND ignore` funcionam e sobrevivem ao reboot.

O `apply.sh` tenta, por pacote: `disable-user`, depois `uninstall -k --user 0` (o APK continua em `/system`; volta com `install-existing`), depois `suspend` + `appops` + `force-stop`. Todos os pacotes da lista são core neste build, então todos acabam suspensos. Para reverter: `scripts/rollback.sh <lista>` ou `scripts/rollback.sh --pkg <pacote>`.

Suspender não impede o processo de subir no boot: o sistema ainda entrega os broadcasts de boot e mantém conexões. `coreservice`, `sageservice`, `tvlauncher`, `tvrecommendations`, `tvbugtracker` e, na camada pessoal, `katniss` voltam a rodar. Quem os para é o `bootclean` ([10](10-bootclean.md)), ou `scripts/post-boot.sh` a partir do computador.

## Grupos

A base suspende 14 pacotes; a camada pessoal acrescenta 2.

| Grupo | Pacotes | Observação |
|---|---|---|
| Telemetry and feedback | `feedback`, `partnersetup`, `tvbugtracker` | `tv.bugreportsender` não existe neste build |
| App blocker and NES services | `coreservice`, `daemon`, `sageservice` | o `daemon` é persistente e suspender não o para; ver [03](03-coreservice.md) |
| Recommendations, partner rows | `tvrecommendations`, `autoinstalls.config.sei` | o ouvinte de notificações do `tvrecommendations` também é desligado; `leanbacklauncher.partnercustomizer` não existe neste build |
| Preloaded apps | `printspooler`, `talkback` | |
| Stock launcher and unused | `tvlauncher`, `backdrop`, `camera2`, `gallery3d` | só depois de o launcher novo estar instalado; o papel HOME sai antes do `tvlauncher` (`set-home-activity` para a `FallbackHome` das Configurações), porque o Android recusa suspender o dono do papel HOME |
| Google Assistant and voice search | `katniss`, `tts` | só no `scripts/personal.sh`; desliga a busca por voz e o Assistente |
| Already removed by the owner | `tivo.atom`, `skywayclient`, `tvglobalkeyhandler` e mais 5 | só com `apply-all.sh --with-owner-removals`; o dono já os tinha removido antes do projeto |

Fora os pacotes, a base desliga o ouvinte de notificações do `tvrecommendations` (`cmd notification disallow_listener`) e troca o protetor de tela pelo relógio do launcher (`screensaver_components`). A camada pessoal muda o Assistente (`assistant`, `voice_interaction_service`), que o `bootclean` regrava a cada boot.

## Aplicar à mão, grupo a grupo

```bash
scripts/apply.sh examples/tivo-stream-4k/debloat.txt --only "<grupo>"
# teste com o controle: Home, voltar, volume, YouTube, Netflix, Prime Video
adb reboot
scripts/status.sh
```

## Não fazer

- Iniciar pacotes de fábrica ou de teste (`com.utsmta.app`, nomes com `factory`): em outros aparelhos isso muda flags que o shell não desfaz.
- Suspender `com.android.vending`, Play Services, `com.android.tv.settings`, o teclado, `com.sei.hdmi.services` (CEC), `com.uei.uas.tivo` (liga e desliga a TV pelo controle) ou `com.nes.tivo.remote.*` (pareamento e firmware do controle).
- Suspender `com.google.android.apps.mediashell` (Chromecast): testado; quebra o cast e não libera memória, porque outro componente mantém conexão com ele.

## Atualização de firmware

O `coreservice` (suspenso pela base) e o `skywayclient` (removido só com `--with-owner-removals`) participam da verificação de atualização; sem eles, o aparelho pode deixar de atualizar. Antes de atualizar, rode `scripts/rollback.sh examples/tivo-stream-4k/debloat.txt`; depois, aplique de novo e confira com `scripts/status.sh`. Uma atualização pode mudar o que o firmware aceita.
