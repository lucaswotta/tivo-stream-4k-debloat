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
- Controle conferido pelo dono depois do lote 2: Home, volume, YouTube e Netflix normais.

## 2026-10-22 — Lote 3: recomendações e auto-instalação

- `google.android.tvrecommendations` e `android.autoinstalls.config.sei` ficaram `suspend + appops` (core, recusam `uninstall`). `nes.leanbacklauncher.partnercustomizer` não existe nesta build.
- Depois do lote: `KEYCODE_HOME` abre `com.google.android.tvlauncher/.MainActivity` em foco, buffer `crash` vazio, sem `FATAL` nem `ANR` no log.
- **Falta:** o dono conferir a home (linhas de recomendação) e o reboot.

## 2026-10-22 — Lote 4, benchmark final e fechamento da lista

- Dono conferiu depois do lote 3: home e controle normais. Lote 4 (`printspooler`, `talkback`) aplicado; Home em foco, sem crash.
- Todos os 10 pacotes suspensos continuam `suspended=true` e `RUN_ANY_IN_BACKGROUND: ignore` depois de 4 reboots (os 3 do bench com `--boot` mais o do teste do Downloader).
- Bench com reboot (3 rodadas, mediana): boot 48 s, `MemAvailable` 920 MB, 330 processos (`coreservice` e `sageservice` reiniciados pelo boot).
- Bench sem reboot, depois de `am force-stop` nos dois (3 rodadas, mediana):

| Métrica | Linha de base | Depois | Δ |
|---|---|---|---|
| `MemAvailable` | 976 MB | 1058 MB | +82 MB |
| Processos | 314 | 310 | -4 |
| Pacotes habilitados | 102 | 102 | 0 |
| PSS do launcher | 104 MB | 68 MB | -36 MB |
| YouTube a frio | 507 ms | 521 ms | +14 ms |
| Netflix a frio | 529 ms | 504 ms | -25 ms |
| Prime a frio | 785 ms | 689 ms | -96 ms |

- **Limite da comparação:** a linha de base foi medida com o aparelho ligado há horas; "depois" vem logo depois de um reboot. Parte do ganho de memória e do PSS do launcher pode ser só boot recente. Os tempos de abertura estão dentro da variação (YouTube pior, Netflix e Prime melhores). O ganho seguro é o polling de 1/s a zero e os serviços parados; o resto precisa de uma segunda linha de base após reboot sem as suspensões (`rollback.sh`, reboot, `bench.sh`).
- `packages_enabled` não muda porque suspender não desabilita.
- `debloat.txt` sem a marca DRAFT: toda linha ativa foi aplicada e testada neste aparelho (uma unidade, um dia). `tvlauncher` continua fora, sem launcher novo.
- **Próximo:** comparação limpa pós-reboot (sem as suspensões) e Fase 4, launcher novo (HOME `priority 2`; ver [09](09-referencias.md)).

## 2026-10-22 — Comparação limpa: com e sem as suspensões

Método igual nos dois lados: `bench.sh --boot --runs 3` (reboot, 180 s de espera, medição), mediana. "Sem" = as 10 suspensões desfeitas com `rollback.sh --pkg` (os 5 pacotes removidos antes ficaram como estavam); "com" = a lista aplicada, sem `force-stop` depois do boot.

| Métrica | Sem suspensões | Com suspensões | Δ |
|---|---|---|---|
| Boot | 48 s | 48 s | 0 |
| `MemAvailable` | 905 MB | 920 MB | +15 MB |
| Processos | 332 | 330 | -2 |
| PSS do launcher | 60 MB | 64 MB | +4 MB |
| YouTube a frio | 668 ms | 673 ms | +5 ms |
| Netflix a frio | 694 ms | 775 ms | +81 ms |
| Prime a frio | 1519 ms | 1479 ms | -40 ms |

- Rodadas individuais de `MemAvailable` sem suspensão: 904 e 905 MB (a terceira não foi anotada à parte). Não vale ler +15 MB como ganho: está no tamanho da variação já vista (976 a 990 MB na linha de base).
- O "antes e depois" anterior (+82 MB, launcher 104 → 68 MB) era em grande parte efeito de comparar um aparelho ligado há horas com um recém-reiniciado. Vale esta tabela, não aquela.
- Sobre o desempenho, a lista não mostra ganho mensurável neste aparelho. O que ela comprova: o polling de 1/s do `coreservice` vai a zero e o `sageservice` deixa de ficar em 88 a 139 MB de RSS quando recebe `force-stop`. O `MemAvailable` não separa isso do ruído.
- A contagem de `ClearDataForGotaFun` sem suspensão não foi refeita nesta rodada (o comando foi cortado por `timeout`); vale a medição anterior: 180 em 180 s.
- Lista reaplicada: os 10 pacotes `suspended=true` de novo, `force-stop` em `coreservice` e `sageservice`.
- **Conclusão:** o benefício real do projeto, até aqui, é privacidade e menos atividade de fundo, não velocidade. O ganho de velocidade, se houver, virá do launcher novo (Fase 4) e da troca da home.

## 2026-10-22 — Fase 4, leitura prévia, e teste de compilação AOT

Estado de desempenho medido antes de mexer: `MemAvailable` ~1,07 GB em repouso (`dumpsys meminfo`: 863 MB livres/cache), `/data` com 995 MB livres de 4,1 GB, CPU `interactive` a 1,6 GHz, animações já em `window=0`, `transition=0`, `animator=0.5` (ajuste anterior do dono). Apps de vídeo já em `speed-profile` por `bg-dexopt`/`install-dm`. Maiores consumidores: `gms` 145 MB, `system` 118 MB, `tvlauncher` 81 MB, `vending` 63 MB, `katniss:interactor` 60 MB.

Teste de AOT: `cmd package compile -m speed -f` em `tvlauncher`, YouTube, Netflix e Prime (3 rodadas de `bench.sh` antes e depois; ~70 MB de disco).

| App | `speed-profile` | `speed` |
|---|---|---|
| YouTube | 538 ms | 628 ms |
| Netflix | 527 ms | 553 ms |
| Prime | 691 ms | 752 ms |

Pior, não melhor. Revertido com `compile -m speed-profile -f` nos 4 apps (status confirmado `speed-profile`, razão `cmdline`). `compile --reset` falha para o shell (`Only the system can clear all profile data`).

Achados para a troca de launcher:
- `tvrecommendations` está suspenso mas **rodando** (PID novo, 37 a 131 MB): o `tvlauncher` o religa. Suspender não impede um processo que outro app vincula; só `force-stop` e o launcher o religa de novo.
- Esta build (Android 12) não tem `cmd role get-role-holders`; HOME é decidido por `set-home-activity` (preferred activity). `tvlauncher` tem prioridade 2 e é app de sistema atualizado (`UPDATED_SYSTEM_APP`, `PRIVILEGED`).
- `free-my-tv` (`HomeMode.restoreHome`) usa `set-home-activity` e, como reversão, `cmd package set-home-activity <stock>`; no Android 9/12 sem `cmd role` o `remove-role-holder` não existe.
- A máquina de desenvolvimento só tem JDK 25 e não tem Android SDK. O launcher do `cleanyourtv` pede JDK 17, SDK 34 e Gradle; compilar exige baixar essas ferramentas.

## 2026-10-22 — Launcher próprio e o teste de HOME

Ferramentas baixadas de fontes oficiais, com checksum conferido (Temurin 17.0.21+9: SHA-256; `commandlinetools-linux-16111833`: SHA-1 do `repository2-3.xml`). Instaladas em `~/.local/share/tivo-toolchain` (fora do repo, sem tocar em `.bashrc`): JDK 17, `build-tools;34.0.0`, `platforms;android-34`.

Launcher próprio `dev.lucaswotta.homelite` (`launcher/`, commit `59b0e37`): grade de apps Leanback com banner, relógio e data. APK de 16,8 KB, **nenhuma permissão**, sem serviço, sem biblioteca, sem rede. Build sem Gradle (`launcher/build.sh`: `aapt2`, `javac --release 8`, `d8`, `zipalign`, `apksigner`).

- Armadilha de build: o `d8` de `build-tools` 34 aborta com `NullPointerException` em classes que o `javac` 17 marca com `MethodParameters` sem nome (classe interna não estática, classe anônima, método ponte de `Comparator`). Contorno no código: classes aninhadas `static`, `TreeMap` com `Collator` no lugar de `Comparator` próprio.
- Abre em 395 ms a frio (`am start -W`). Tela conferida por captura: 10 tiles (FX, Navegador Web, Netflix, Play Store, Prime Video, Send Files To TV, TVExpress BR, UniTV, YouTube, Configurações).
- O Downloader (`com.esaba.downloader`) não aparece na grade: não declara `LEANBACK_LAUNCHER`, ou foi desinstalado. A conferir.

**Teste de HOME (resultado negativo, igual ao Nokia 8000):**
- `cmd package set-home-activity --user 0 dev.lucaswotta.homelite/.MainActivity` → `Success`. `dumpsys role` mostra o papel HOME com o `homelite` e `dumpsys package preferred` mostra a atividade preferida `homelite` (`mAlways=true`).
- Mesmo assim, a tecla Home e `am start -a MAIN -c HOME` abrem `com.google.android.tvlauncher/.MainActivity` (log: `START ... cmp=com.google.android.tvlauncher/.MainActivity`). `resolve-activity` continua devolvendo o `tvlauncher` com `priority=2`.
- Causa provável (não confirmada no código-fonte do firmware): a resolução do intent escolhe o filtro de maior prioridade antes de consultar a preferência do usuário, e um app instalado não passa de prioridade 0 num filtro.
- Desvios tentados, todos recusados: `pm disable com.google.android.tvlauncher/.MainActivity` (`SecurityException: Shell cannot change component state`); `pm disable-user` e `uninstall --user 0` já recusados antes (app core).
- Configurações da TV > Apps > Android TV Home (v7.7.15): só Forçar parada, Desinstalar atualizações, Remover dados, Limpar cache, Limpar ações padrão, Notificações e Permissões. **Sem botão Desativar.**
- Estado restaurado: `set-home-activity` devolvido ao `tvlauncher`; papel HOME de volta com ele; tecla Home normal. O `homelite` segue instalado, fora do caminho.

**Aberto:** como fazer o `homelite` receber a tecla Home sem root. Opções, nenhuma testada: (1) "Desinstalar atualizações" do `tvlauncher` (volta à versão de fábrica; se o botão Desativar aparecer depois, resolve); (2) serviço de acessibilidade que intercepta a tecla Home e abre o `homelite` (a abordagem de `HomeKeyService` do `cleanyourtv`/`free-my-tv`; custo: um serviço permanente e a permissão `WRITE_SECURE_SETTINGS` concedida por ADB); (3) usar o `homelite` só como app de atalho, sem tomar a tecla Home.
