# 03 — O caso CoreService

## O problema

Depois da atualização para o Android 12, donos de TiVo Stream 4K relataram que apps como Downloader, Projectivy Launcher e utilitários de ADB eram desinstalados logo após a instalação. A comunidade apontou um app de sistema, `com.nes.coreservice`, como responsável, e a correção divulgada é:

```bash
adb shell pm disable-user com.nes.coreservice
```

Fontes: [AFTVnews](https://www.aftvnews.com/?p=46214), [TROYPOINT](https://troypoint.com/tivo-stream-4k-update-removes-downloader/) (relata que um reboot às vezes desfaz a correção).

## Achado: a correção da internet não funciona nesta build

No build 1272 (patch 2025-07-05), `pm disable-user` é recusado para qualquer pacote (`Warning! This command is illegal!`). A neutralização terá que ser por `pm suspend` + `appops`, se o firmware aceitar.

## Achado: polling de atualização a cada segundo

`adb logcat` mostra, uma vez por segundo, o par:

```
I SystemUpdateManagerService: No existing info file /data/system/system-update-info.xml
I ClearDataForGotaFun: ... #getSystemUpdateStatus() status is 0
```

O PID dessas linhas é o `com.nes.coreservice` (confirmado com `ps -A`). São ~86 mil consultas por dia acordando a CPU, num aparelho em que nenhuma atualização vai chegar. No mesmo log, `com.nes.daemon` aparece em `DaemonService ... onRemoveCompleted`, um callback de **apagar dados de app**: o daemon limpa dados de pacotes em segundo plano. Os dois serviços NES são os principais suspeitos de custo em repouso.

## Achado: a lista negra e a regra do HOME

O log de `com.nes.coreservice` mostra, no boot, a função `EvoBlackListAppsFun`: ela lista as atividades que declaram `android.intent.category.HOME` e chama `AppUtil.uninstallAsUser` nas que não são de sistema (`isSystemApp = false`), além de uma lista fixa de apps (nesta unidade: `com.magistv.magistv`, `com.cfsa.magis`, `com.mycompany.descargarmagistv4281apk`). `tvlauncher` e Configurações passam por serem de sistema. É assim que launchers alternativos somem.

Consequências medidas em 2026-10-22:
- **Suspender o `coreservice` não impede a remoção.** O pacote suspenso sobe de novo no boot (receiver) e desinstala o launcher próprio em segundos. O Downloader sobreviveu antes porque o `coreservice` estava parado por `am force-stop` naquele momento.
- **Um app que não declara HOME é ignorado.** O `homelite` sem a categoria sobreviveu a um boot completo com o `coreservice` rodando, com 0 chamadas de `uninstallAsUser` para ele.
- Um serviço de acessibilidade abre o launcher pela tecla Home (ver [05](05-launcher.md)); por isso o launcher não precisa da categoria.

### Origem da lista e por que ela roda

- **Onde está:** no recurso `array/evo_black_list_to_uninstall_pkgs` (id `0x7f030009`) dentro de `resources.arsc` do `Nes_CoreService_Newest.apk` (`/system/app`, somente leitura). Os nomes não aparecem no código (`.dex`); o código chama a função `EvoBlackListAppsFun`. Há outros dois arrays no mesmo APK, `clear_data_black_list` e `clear_data_white_list`, que dizem de quais apps o `daemon` limpa os dados (entre eles Play Store e YouTube; a lista de "limpar" é outra coisa que a de "desinstalar").
- **Quando roda:** a cada início do `coreservice`, antes de qualquer app terminar de abrir. No boot de 2026-10-22 18:40 a função enumerou só launchers de sistema (`tvlauncher`, Configurações) e **mesmo assim** chamou `uninstallAsUser` para os 53 nomes: não depende de haver launcher alternativo instalado. Repete a enumeração em eventos seguintes (18:40:20 e 18:40:31).
- **Quem acorda o `coreservice`:** o log mostra `Start proc ... com.nes.coreservice for broadcast {BootReceiver}`, 4 s depois de `com.nes.daemon` subir. O `daemon` é `PERSISTENT` (o Android o recria se for morto) e o broadcast chega mesmo com o `coreservice` suspenso e em estado parado.
- **Por quê:** o APK não diz. A composição da lista (launchers alternativos, ferramentas de instalação e de ADB como Downloader e Magisk, mais de vinte variantes de apps de IPTV "Magis TV") sugere política do fabricante contra sideload e IPTV pirata, e coincide com os relatos da AFTVnews de que a atualização para o Android 12 passou a apagar o Downloader. É uma inferência, não um fato documentado.
- **O que não funciona:** suspender, `appops`, `force-stop` (o processo volta no boot), e componentes e `pm disable*` (recusados ao shell). **Não testado:** sobreposição de recurso (RRO) para esvaziar o array, que em geral exige que o app alvo permita ou que o overlay seja do sistema.
- **O que funciona:** o Downloader instalado **depois** do boot, com o `coreservice` parado por `scripts/post-boot.sh`, fica até o próximo boot. Um reboot, mesmo o de uma queda de energia, o remove. Alternativas fora da lista: `scripts/install-apk.sh` a partir do PC, ou Send Files To TV e FX Explorer na própria TV.

### A lista fixa de 53 pacotes

No boot, `EvoBlackListAppsFun` chama `uninstallAsUser` para 53 nomes de pacote, instalados ou não (registro do log de 2026-10-22). Grupos:
- **Launchers alternativos:** `me.efesser.flauncher`, `com.izyver.fllauncher`, `com.spocky.projengmenu`, `com.teslacoilsw.launcher`, `com.anddoes.launcher`, `ca.dstudio.atvlauncher.free`/`.pro`, `studio.scillarium.stblauncher`, `eu.chainfire.tv.sideloadlauncher`, `org.cosinus.launchertv`, `com.vnapps.tvlauncher` e outros.
- **Instaladores e ferramentas de ADB:** `com.esaba.downloader` (Downloader), `ru.aaaaaaci.installer`, `com.cybercat.adbappcontrol.tv`, `com.topjohnwu.magisk`.
- **IPTV e variantes de "Magis TV":** cerca de 25 nomes (`com.magistv.magistv`, `com.android.mgstv`, ...), mais `com.hbo.hbonow` e `com.disney.starplus`.
- Fora da lista: Navegador Web (`com.internet.tvbrowser`) e TVExpress BR (`com.livetv.tve`) não constam e foram desinstalados pelo próprio dono.

Consequência: **o Downloader é removido a cada boot em que o `coreservice` roda.** O `coreservice` suspenso ainda sobe no boot (receiver), então reiniciar a TV com ele ativo remove os apps da lista. `scripts/post-boot.sh` não ajuda, porque a remoção acontece nos primeiros ~35 s, antes de o ADB responder.

## Por que não aplicar às cegas

No Nokia Streaming Box 8000 (mesma fabricante e middleware), o `com.nes.coreservice` foi **mantido** porque concentra o LED frontal, mensagens de OTA e um receptor de analytics. Então desabilitar pode ter efeito colateral. A investigação existe para descobrir qual.

## Roteiro de investigação

1. **Confirmar que existe e está ativo**
   ```bash
   adb shell pm list packages | grep coreservice
   adb shell dumpsys package com.nes.coreservice | grep -E 'versionName|enabled|firstInstall'
   ```
2. **Mapear componentes e permissões**
   ```bash
   adb shell dumpsys package com.nes.coreservice > runs/coreservice-package.txt
   ```
   Procurar: `DELETE_PACKAGES`, `INSTALL_PACKAGES`, receivers de `PACKAGE_ADDED`/`BOOT_COMPLETED`, serviços persistentes.
3. **Reproduzir o comportamento** (antes de desabilitar)
   ```bash
   adb logcat -c
   # instale o Projectivy Launcher pela Play Store
   adb logcat -d | grep -iE 'coreservice|delete|uninstall' > runs/coreservice-logcat.txt
   ```
4. **Neutralizar, do mais suave ao mais forte**
   - `adb shell pm disable-user --user 0 com.nes.coreservice`
   - se recusado: `pm suspend --user 0` + `cmd appops set com.nes.coreservice RUN_ANY_IN_BACKGROUND ignore` + `am force-stop`
5. **Verificar**: instalar o Projectivy de novo, reboot 2×, conferir se continua instalado e se algo parou (LED, aviso de atualização, controle).

## Resultado

| Item | Resultado |
|---|---|
| Versão do Android quando testado | 12, build 1272 |
| Componentes suspeitos | `ClearAppDataActivity` e permissões `DELETE_PACKAGES`/`CLEAR_APP_USER_DATA`/`INSTALL_PACKAGES` (uid `system`); `daemon` também tem as duas primeiras ([diário](diario.md)) |
| Comando que funcionou | `pm suspend` + `appops` + `am force-stop` pára o polling, mas não o boot; o que protege um launcher é ele não declarar HOME |
| Sobrevive a reboot? | A suspensão sim; o processo volta no boot (rodar `scripts/post-boot.sh`) |
| Efeitos colaterais | Nenhum visto em LED, controle, Wi-Fi e YouTube |
