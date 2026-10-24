# 03 — O `com.nes.coreservice`

[English](../03-coreservice.md)

## O problema

Depois da atualização para o Android 12, donos de TiVo Stream 4K relataram que Downloader, Projectivy Launcher e ferramentas de ADB eram desinstalados logo depois de instalados. O responsável apontado foi o app de sistema `com.nes.coreservice`, e a correção divulgada é `pm disable-user com.nes.coreservice`. Fontes: [AFTVnews](https://www.aftvnews.com/?p=46214) e [TROYPOINT](https://troypoint.com/tivo-stream-4k-update-removes-downloader/), que relata que um reboot às vezes desfaz a correção.

No build `SC.1272` (patch 2025-07-05) essa correção não funciona: `pm disable-user` é recusado para qualquer pacote (`Warning! This command is illegal!`).

## O que ele faz

### Consulta de atualização a cada segundo

`adb logcat` mostra, uma vez por segundo, o par:

```
I SystemUpdateManagerService: No existing info file /data/system/system-update-info.xml
I ClearDataForGotaFun: ... #getSystemUpdateStatus() status is 0
```

O PID dessas linhas é o do `com.nes.coreservice`. São cerca de 86 mil consultas por dia num aparelho que não recebe atualização. O `com.nes.daemon` aparece no mesmo log em `DaemonService ... onRemoveCompleted`, um callback de limpeza de dados de app.

### Desinstalação no boot

No boot, a função `EvoBlackListAppsFun` do `coreservice`:

1. lista as atividades que declaram `android.intent.category.HOME` e chama `AppUtil.uninstallAsUser` nas que não são de sistema (`isSystemApp = false`);
2. chama `uninstallAsUser` para uma lista fixa de 53 pacotes, instalados ou não.

O `tvlauncher` e as Configurações escapam por serem de sistema. É assim que launchers alternativos somem.

- Onde está a lista: no recurso `array/evo_black_list_to_uninstall_pkgs` (id `0x7f030009`), no `resources.arsc` do `Nes_CoreService_Newest.apk` em `/system/app`, somente leitura. O mesmo APK tem `clear_data_black_list` e `clear_data_white_list`, que dizem de quais apps o `daemon` limpa os dados (entre eles Play Store e YouTube).
- Quando roda: a cada início do `coreservice`, nos primeiros ~35 s do boot. O log mostra `Start proc ... com.nes.coreservice for broadcast {BootReceiver}` 4 s depois de o `com.nes.daemon` subir. O `daemon` é `PERSISTENT` (o Android o recria se for morto) e o broadcast chega mesmo com o `coreservice` suspenso.
- Por quê: o APK não diz. A composição da lista (launchers alternativos, instaladores, ferramentas de ADB e mais de vinte variantes de apps de IPTV) sugere uma política do fabricante contra sideload e IPTV pirata, o que bate com os relatos da AFTVnews. É inferência, não fato documentado.

### A lista fixa de 53 pacotes

- Launchers alternativos: `me.efesser.flauncher`, `com.izyver.fllauncher`, `com.spocky.projengmenu`, `com.teslacoilsw.launcher`, `com.anddoes.launcher`, `ca.dstudio.atvlauncher.free` e `.pro`, `studio.scillarium.stblauncher`, `eu.chainfire.tv.sideloadlauncher`, `org.cosinus.launchertv`, `com.vnapps.tvlauncher` e outros.
- Instaladores e ferramentas de ADB: `com.esaba.downloader` (Downloader), `ru.aaaaaaci.installer`, `com.cybercat.adbappcontrol.tv`, `com.topjohnwu.magisk`.
- IPTV: cerca de 25 variantes de "Magis TV" (`com.magistv.magistv`, `com.android.mgstv`, ...), mais `com.hbo.hbonow` e `com.disney.starplus`.

## O que funciona e o que não funciona

| Tentativa | Resultado |
|---|---|
| `pm disable-user`, `pm disable <componente>`, `pm hide` | recusados ao shell |
| `pm suspend` + `appops` + `am force-stop` | a consulta de atualização cai a zero; a suspensão sobrevive ao reboot, mas o processo volta no boot e a desinstalação acontece do mesmo jeito |
| Launcher sem a categoria HOME | ignorado pela regra: sobreviveu a boots completos com o `coreservice` rodando, com 0 chamadas de `uninstallAsUser` |
| Parar o processo depois do boot | o `bootclean` faz isso ([10](10-bootclean.md)); não impede a remoção dos primeiros ~35 s |
| Sobreposição de recurso (RRO) para esvaziar o array | não testado; em geral exige overlay de sistema |

Na prática:

- O launcher do projeto não declara HOME, e um serviço de acessibilidade o abre pela tecla Home ([05](05-launcher.md)).
- O Downloader instalado depois do boot, com o `coreservice` parado, fica até o próximo boot. Um reboot, mesmo por queda de energia, o remove. Para instalar APKs, use `scripts/install-apk.sh` a partir do computador, ou um gerenciador de arquivos que não está na lista (Send Files To TV e FX File Explorer funcionaram).
- Nenhum efeito colateral foi visto no LED, no controle, no Wi-Fi ou no YouTube com o `coreservice` suspenso.

No Nokia Streaming Box 8000, o mesmo pacote foi mantido porque também cuida do LED, das mensagens de OTA e de um receptor de analytics. Em outro aparelho NES, confira esses três antes de suspender.

## Como reproduzir

```bash
adb shell dumpsys package com.nes.coreservice | grep -E 'versionName|permission'   # DELETE_PACKAGES, CLEAR_APP_USER_DATA
adb reboot
# depois do boot:
adb logcat -d | grep -E 'EvoBlackListAppsFun|uninstallAsUser'
```

Permissões do `coreservice` 1.0.5.238 (uid `system`, `/system/app`): `DELETE_PACKAGES`, `REQUEST_DELETE_PACKAGES`, `CLEAR_APP_USER_DATA`, `INSTALL_PACKAGES`, `MANAGE_USERS`. Componentes: `ClearAppDataActivity`, `NonABGotaMsgInfoReceiver`, `LedReceiver`, `BootReceiver`, `GaReceiver`, `ProviderReceiver`.
