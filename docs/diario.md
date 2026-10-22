# Diário de bordo

Uma entrada por sessão: data, o que foi feito, comando, resultado, próximo passo.

## 2026-10-22 — Fase 0: documentação

- Repositório criado com a estrutura, docs e scripts.
- Fotos do aparelho, da etiqueta (HSN/MAC tarjados) e da home original adicionadas.
- Descoberta: FCC ID `2AOVU` = SEI Robotics. Primos no cleanyourtv: Nokia Streaming Box 8000 e Dialog ViU, ambos com middleware NES.
- `com.nes.coreservice` identificado como o app que remove launchers (AFTVnews).
- **Próximo:** ligar ADB, rodar `scripts/probe.sh`, confirmar versão do Android.

## 2026-10-22 — Probe inicial

- ADB conectado pela rede só com "Depuração USB" ligada (não existe toggle de depuração de rede). Primeiro `adb connect` dá `failed to authenticate` até aceitar o aviso na TV.
- Android 12 (SDK 31), build `eSTREAM4K/SEI400TV/SEI400TV:12/SC/1272`, patch 2025-07-05, userspace 32-bit, fabricante SEI Robotics.
- 98 pacotes de sistema, 5 do usuário, 1 já desabilitado, 17 NES/vendor. `com.nes.coreservice` presente.
- Wi-Fi salvo pertence a `android.uid.system` (seguro mexer no setupwraith).
- **`pm disable-user` recusado** ("This command is illegal!"), igual ao Nokia 8000. A correção divulgada para o CoreService não funciona nesta build.
- **Próximo:** testar se `pm suspend`/`appops` funcionam, listar pacotes NES e conferir quem é dono da HOME.

## 2026-10-22 — Métodos aceitos e debloat manual anterior

- `pm suspend` ✅, `appops` ✅, `pm hide` ❌ (MANAGE_USERS), `pm uninstall --user 0` ❌ para apps core, mas ✅ para os não-core (o dono já tinha removido 7 assim).
- HOME: só `tvlauncher` (prioridade 2) e FallbackHome, como no Nokia. Launcher novo vai precisar de HOME_KEY_SERVICE.
- Pacotes TiVo/NES presentes: coreservice, daemon, tivo.quickset, tivo.remote.ota, tivo.remote.pair, tvbugtracker, tivo.sageservice, uei.uas.tivo, sei.hdmi.services.
- Já removidos pelo dono antes do projeto: tivo.atom, tivoplusplayer, tvlaunchercustomization, skywayclient, tvglobalkeyhandler, utsmta.app, play.games; YouTube Music desabilitado pelas Configurações.
- **Linha de base não é de fábrica**: o benchmark "antes" parte deste estado.
- `apply.sh` passa a tentar disable-user → uninstall --user 0 → suspend+appops; `rollback.sh` usa install-existing.

## 2026-10-22 — Controle e polling do CoreService

- `.kl` do controle (`Vendor_0471_Product_1207.kl`) já mapeia TiVo→`DVR`, Skip→`MEDIA_SKIP_FORWARD`, Live→`NES_SHORTCUT_10`; Guide chega como `GUIDE`. Mapa em [08-controle](08-controle.md).
- Keycode numérico do Live não aparece em `dumpsys input` nem `logcat`: fica para a fase do launcher (captura pelo remapeador).
- **`com.nes.coreservice` consulta o status de atualização do sistema 1×/segundo** (`ClearDataForGotaFun`). `com.nes.daemon` executa limpeza de dados de app (`onRemoveCompleted`).

## 2026-10-22 — Logs por minuto e dumpsys dos serviços NES/TiVo

Coleta: `adb logcat -v threadtime -b all` por 180 s em repouso (buffer limpo antes), `ps -A` e `dumpsys package` dos três pacotes. Bruto em `runs/2026-10-22_1606-logs/` (fora do git).

Linhas de log por minuto, por processo (top, repouso):

| Processo | Linhas/min | RSS |
|---|---|---|
| `system_server` | 782 | 163 MB |
| `audio.service-droidlogic` | 96 | 19 MB |
| `com.nes.coreservice` | 61 | 49 MB |
| `com.nes.daemon` | 2,7 | 41 MB |
| `com.tivo.sageservice` | 4 | 88 MB |

- `com.nes.coreservice`: 180 de 184 linhas em 180 s são `ClearDataForGotaFun ... getSystemUpdateStatus() status is 0`, ou seja 1 consulta/s confirmada. O `system_server` responde cada uma com `SystemUpdateManagerService: No existing info file` (180 linhas), então o custo é dobrado. Restante: negações SELinux de `search` em `sysfs/leds` (LED).
- `com.nes.daemon` (`PERSISTENT`, uid `system`): `DaemonService check, mSkywayPid: -1`, tenta subir o `com.nes.skywayclient` (removido), chama `startService` e depois `start clear` / `onRemoveCompleted s: com.nes.skywayclient`. Ou seja, fica em laço de verificação de um pacote que não existe mais.
- `com.tivo.sageservice`: quase mudo no log (`sagelogger [diagnostics]`: coleta de GC e estatísticas de saúde do sistema). Receiver `AutoStartBroadcastReceiver`, sem DELETE nem INSTALL. Mantém 88 MB de RSS num aparelho que não usa o serviço TiVo.
- `com.nes.coreservice` 1.0.5.238, uid `system`, `/system/app`: pede `DELETE_PACKAGES`, `REQUEST_DELETE_PACKAGES`, `CLEAR_APP_USER_DATA`, `INSTALL_PACKAGES`, `MANAGE_USERS`. Componentes: `ClearAppDataActivity`, `NonABGotaMsgInfoReceiver`, `LedReceiver`, `BootReceiver`, `GaReceiver`, `ProviderReceiver`. Isso explica a desinstalação de launchers; o LED é outro componente, mesmo pacote.
- `com.nes.daemon` 20230512-fit31, uid `system`, `/system/app`, `PERSISTENT`: também tem `DELETE_PACKAGES` e `CLEAR_APP_USER_DATA`.
- Soma de RSS dos três: ~178 MB de 2 GB.
- Nenhuma alteração feita no aparelho nesta etapa (só leitura).
- **Próximo:** testar `pm suspend` + `appops` em `sageservice` e `daemon` (menor risco), depois `coreservice`, medindo `MemAvailable` e logs antes e depois.

## 2026-10-22 — Lote NES: suspend + appops em sageservice, daemon e coreservice

Método por pacote: `pm suspend --user 0`, `cmd appops set <pkg> RUN_ANY_IN_BACKGROUND ignore`, `am force-stop`. Todos retornaram sucesso. `apply.sh` não foi usado porque tenta `uninstall --user 0` antes de `suspend`, e o lote pedia só o método reversível mais fraco.

Linha de base (`scripts/bench.sh`, 3 rodadas, mediana, sem reboot) e depois de `sageservice` + `daemon`:

| Métrica | Antes | Depois do lote 1 |
|---|---|---|
| `MemAvailable` | 976 MB | 990 MB |
| Processos | 314 | 315 |
| YouTube a frio | 507 ms | 439 ms |
| Netflix a frio | 529 ms | 521 ms |
| Prime a frio | 785 ms | 646 ms |

A diferença de memória (14 MB) e de tempos está dentro da variação entre rodadas (976 a 990 MB só na linha de base); não é ganho comprovado.

- `com.nes.daemon` é `PERSISTENT`: `force-stop` não o derruba (PID 4523 inalterado) e ele segue com ~3 linhas de log/min. Suspender não o para. Efeito prático: nenhum.
- Reboot (volta em ~43 s): `suspended=true` e `RUN_ANY_IN_BACKGROUND: ignore` **sobrevivem**, mas `com.tivo.sageservice` **sobe sozinho** após o boot (PID novo, 131 MB de RSS), via `AutoStartBroadcastReceiver`. Um `am force-stop` depois do boot o derruba e ele não volta em 20 s. Ou seja, o `suspend` não impede o receiver de boot (limite já previsto em 04-debloat). Sem root, não há automação no próprio aparelho; fica como passo pós-boot.
- `com.nes.coreservice` suspenso: em 90 s, **0** linhas de `ClearDataForGotaFun` e 0 de `SystemUpdateManagerService` (antes: 180 em 180 s cada). O processo não voltou. `MemAvailable` medido logo após o boot: 957 MB (não comparável com a linha de base sem reboot).
- **Não verificado:** efeito no LED frontal, no aviso de OTA e no controle, e se o `coreservice` ainda desinstala launchers (falta instalar um app para provar). Precisa de olho humano na TV.
- **Próximo:** conferir LED, Home, volume/TV pelo controle e Wi-Fi; depois instalar o Downloader e ver se sobrevive.

## 2026-10-22 — Teste do Downloader com o coreservice suspenso

- Conferido pelo dono na TV: LED, controle, Wi-Fi e YouTube funcionando com os três pacotes suspensos.
- `com.esaba.downloader` instalado pela Play Store e aberto. Logcat de 7 min sem remoção; o pacote continuou em `pm list packages` depois de abrir e depois de um reboot.
- Pós-reboot: os três pacotes seguem `suspended=true`, mas `coreservice` e `sageservice` **sobem de novo** (processos ativos, 87 MB e 139 MB de RSS). Mesmo com o `coreservice` rodando suspenso, 0 linhas de `ClearDataForGotaFun` em 30 s: o polling não volta. `am force-stop` nos dois os derruba e eles ficam parados (20 s).
- **Limite da prova:** não há controle sem suspensão. O Downloader sobreviver não prova que a suspensão é a causa; só mostra que, com ela, o comportamento relatado não apareceu em 1 instalação e 1 reboot. Para provar, seria preciso reabilitar o `coreservice` (`pm unsuspend`) e repetir a instalação de outro app.
- Receita pós-boot: `am force-stop com.nes.coreservice; am force-stop com.tivo.sageservice`.

## 2026-10-22 — Lote 2: telemetria e feedback

- Bug em `scripts/apply.sh`: o `adb shell` dentro do `while read` consumia o stdin do laço e só o primeiro pacote era processado. Corrigido em `_lib.sh` (`</dev/null` em `sh_tv`); commit separado.
- Aplicado com `FORCE_DRAFT=1 scripts/apply.sh ... --only "Telemetry and feedback"`: `google.android.feedback`, `google.android.partnersetup` e `nes.tvbugtracker` ficaram `suspended=true` (todos recusam `uninstall --user 0` por serem core). `tv.bugreportsender` não existe nesta build.
- **Falta:** teste com o controle e reboot.
