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
