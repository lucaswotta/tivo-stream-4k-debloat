# 03 — `com.nes.coreservice`

[Português](pt-BR/03-coreservice.md)

## The problem

After the Android 12 update, TiVo Stream 4K owners reported that Downloader, Projectivy Launcher and ADB tools were uninstalled right after being installed. The system app `com.nes.coreservice` was named as the cause, and the published fix is `pm disable-user com.nes.coreservice`. Sources: [AFTVnews](https://www.aftvnews.com/?p=46214) and [TROYPOINT](https://troypoint.com/tivo-stream-4k-update-removes-downloader/), which reports that a reboot sometimes undoes the fix.

On build `SC.1272` (patch 2025-07-05) that fix does not work: `pm disable-user` is refused for every package (`Warning! This command is illegal!`).

## What it does

### Update check every second

`adb logcat` shows this pair once per second:

```
I SystemUpdateManagerService: No existing info file /data/system/system-update-info.xml
I ClearDataForGotaFun: ... #getSystemUpdateStatus() status is 0
```

The PID of these lines is `com.nes.coreservice`'s. That is about 86 thousand checks a day on a device that gets no updates. `com.nes.daemon` shows up in the same log in `DaemonService ... onRemoveCompleted`, an app data clearing callback.

### Uninstalls at boot

At boot, the `coreservice` function `EvoBlackListAppsFun`:

1. lists the activities that declare `android.intent.category.HOME` and calls `AppUtil.uninstallAsUser` on the ones that are not system apps (`isSystemApp = false`);
2. calls `uninstallAsUser` for a fixed list of 53 packages, installed or not.

`tvlauncher` and Settings are spared because they are system apps. That is how alternative launchers disappear.

- Where the list lives: in the `array/evo_black_list_to_uninstall_pkgs` resource (id `0x7f030009`), in the `resources.arsc` of `Nes_CoreService_Newest.apk` under `/system/app`, read-only. The same APK has `clear_data_black_list` and `clear_data_white_list`, which tell `daemon` whose app data to clear (the Play Store and YouTube among them).
- When it runs: every time `coreservice` starts, in the first ~35 s of boot. The log shows `Start proc ... com.nes.coreservice for broadcast {BootReceiver}` 4 s after `com.nes.daemon` comes up. `daemon` is `PERSISTENT` (Android recreates it if killed) and the broadcast arrives even with `coreservice` suspended.
- Why: the APK does not say. The contents of the list (alternative launchers, installers, ADB tools and more than twenty variants of IPTV apps) suggest a manufacturer policy against sideloading and pirate IPTV, which matches the AFTVnews reports. That is an inference, not a documented fact.

### The fixed list of 53 packages

- Alternative launchers: `me.efesser.flauncher`, `com.izyver.fllauncher`, `com.spocky.projengmenu`, `com.teslacoilsw.launcher`, `com.anddoes.launcher`, `ca.dstudio.atvlauncher.free` and `.pro`, `studio.scillarium.stblauncher`, `eu.chainfire.tv.sideloadlauncher`, `org.cosinus.launchertv`, `com.vnapps.tvlauncher` and others.
- Installers and ADB tools: `com.esaba.downloader` (Downloader), `ru.aaaaaaci.installer`, `com.cybercat.adbappcontrol.tv`, `com.topjohnwu.magisk`.
- IPTV: about 25 variants of "Magis TV" (`com.magistv.magistv`, `com.android.mgstv`, ...), plus `com.hbo.hbonow` and `com.disney.starplus`.

## What works and what does not

| Attempt | Result |
|---|---|
| `pm disable-user`, `pm disable <component>`, `pm hide` | refused to the shell |
| `pm suspend` + `appops` + `am force-stop` | the update check drops to zero; the suspension survives reboots, but the process comes back at boot and the uninstalls happen anyway |
| Launcher without the HOME category | ignored by the rule: it survived full boots with `coreservice` running, with 0 `uninstallAsUser` calls |
| Stopping the process after boot | `bootclean` does it ([10](10-bootclean.md)); it cannot prevent the removals in the first ~35 s |
| Resource overlay (RRO) to empty the array | not tested; usually needs a system overlay |

In practice:

- The project's launcher does not declare HOME, and an accessibility service opens it from the Home key ([05](05-launcher.md)).
- Downloader installed after boot, with `coreservice` stopped, stays until the next boot. A reboot, even after a power cut, removes it. To install APKs, use `scripts/install-apk.sh` from the computer, or a file manager that is not on the list (Send Files To TV and FX File Explorer worked).
- No side effect was seen on the LED, the remote, Wi-Fi or YouTube with `coreservice` suspended.

On the Nokia Streaming Box 8000 the same package was kept because it also drives the LED, OTA messages and an analytics receiver. On another NES device, check those three before suspending it.

## How to reproduce

```bash
adb shell dumpsys package com.nes.coreservice | grep -E 'versionName|permission'   # DELETE_PACKAGES, CLEAR_APP_USER_DATA
adb reboot
# after boot:
adb logcat -d | grep -E 'EvoBlackListAppsFun|uninstallAsUser'
```

Permissions of `coreservice` 1.0.5.238 (uid `system`, `/system/app`): `DELETE_PACKAGES`, `REQUEST_DELETE_PACKAGES`, `CLEAR_APP_USER_DATA`, `INSTALL_PACKAGES`, `MANAGE_USERS`. Components: `ClearAppDataActivity`, `NonABGotaMsgInfoReceiver`, `LedReceiver`, `BootReceiver`, `GaReceiver`, `ProviderReceiver`.
