On a TiVo Stream 4K (SEI/NES middleware, Android 12, build `SC.1272`, see #1061), `com.nes.coreservice` is what removes alternative launchers, and it also explains why `examples/nokia-streaming-box-8000/README.md` says the new launcher cannot take over the Home button "yet". I have it working on the TiVo, with the evidence below. I have **not** tried it on the Nokia 8000 or the Dialog ViU; I infer from the shared NES middleware that they behave the same.

**What the service does.** At every start it runs `EvoBlackListAppsFun`, which calls `AppUtil.uninstallAsUser`:

- on every non-system app whose activity declares `android.intent.category.HOME` (log: `EvoBlackListAppsFun: onCreate: info.activityInfo.packageName = ... isSystemApp = false`, followed by the uninstall), and
- on a fixed list of 53 packages, from `array/evo_black_list_to_uninstall_pkgs` (id `0x7f030009`) in the `resources.arsc` of `/system/app/Nes_CoreService_Newest/Nes_CoreService_Newest.apk`: alternative launchers (FLauncher, Projectivy, ATV Launcher, Nova Launcher, Apex...), Downloader, Magisk, ADB-control apps and about 25 "Magis TV" IPTV variants.

The names are not in the `.dex`; `aapt2 dump resources` shows the array. It ran with only system launchers installed, so it does not depend on another launcher being present.

**Why `pm suspend` does not help.** The service is started by a broadcast to its `BootReceiver`, sent after the persistent `com.nes.daemon` comes up (`Start proc ... com.nes.coreservice for broadcast {...BootReceiver}`), also when the package is suspended or force-stopped. In my runs, an app declaring HOME was uninstalled twice right after a reboot (`AppUtil: uninstallAsUser: pkg = <my launcher>` from the coreservice PID, then `deletePackageX`).

**What worked.** Remove the HOME category from the launcher's `MainActivity` intent filter (it stays listed as `LEANBACK_LAUNCHER`) and open it by component from a small accessibility service that listens for the Home key. The stock launcher declares HOME with priority 2, and `set-home-activity` answers `Success` but changes nothing, so the key service is what moves Home. After that the launcher survived four reboots with `coreservice` running and 0 `uninstallAsUser` calls for it. To suspend the stock launcher, the HOME role has to leave it first (`cmd package set-home-activity --user 0 com.android.tv.settings/.system.FallbackHome`), because Android refuses to suspend the role holder.

**Not tested:** the unpatched cleanyourtv launcher on the TiVo (I observed the removal with a launcher of my own that declared HOME), and every other NES device.

The patch (one line out of the manifest), the key service and the measurements are in https://github.com/lucaswotta/tivo-stream-4k-debloat, mainly `docs/03-coreservice.md` and `docs/05-launcher.md`. Happy to test a candidate fix for the Nokia if someone has one.
