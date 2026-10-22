# 03 — O caso CoreService

## O problema

Depois da atualização para o Android 12, donos de TiVo Stream 4K relataram que apps como Downloader, Projectivy Launcher e utilitários de ADB eram desinstalados logo após a instalação. A comunidade apontou um app de sistema, `com.nes.coreservice`, como responsável, e a correção divulgada é:

```bash
adb shell pm disable-user com.nes.coreservice
```

Fontes: [AFTVnews](https://www.aftvnews.com/?p=46214), [TROYPOINT](https://troypoint.com/tivo-stream-4k-update-removes-downloader/) (relata que um reboot às vezes desfaz a correção).

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
| Versão do Android quando testado | — |
| Componentes suspeitos | — |
| Comando que funcionou | — |
| Sobrevive a reboot? | — |
| Efeitos colaterais | — |
