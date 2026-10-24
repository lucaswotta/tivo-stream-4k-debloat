# 04 — Debloat

[Português](pt-BR/04-debloat.md)

The list is `examples/tivo-stream-4k/debloat.txt`, in cleanyourtv's format: one package per line, `#` for comments, and each block after a blank line is a group. `scripts/apply.sh <list> --only "<group>"` applies one group; `scripts/apply-all.sh` applies all of them, in the order below.

## Method

On this firmware (`SC.1272`, Android 12):

- `pm disable-user`, `pm hide` and `pm disable <component>` are refused.
- `pm uninstall -k --user 0` works only for apps that are not core; the others answer `is a core application in the system`.
- `pm suspend --user 0` and `cmd appops set <package> RUN_ANY_IN_BACKGROUND ignore` work and survive reboots.

Per package, `apply.sh` tries `disable-user`, then `uninstall -k --user 0` (the APK stays in `/system`; `install-existing` brings it back), then `suspend` + `appops` + `force-stop`. Every package in the list is core on this build, so all of them end up suspended. To undo: `scripts/rollback.sh <list>` or `scripts/rollback.sh --pkg <package>`.

Suspending does not stop the process from starting at boot: the system still delivers boot broadcasts and keeps bindings. `coreservice`, `sageservice`, `tvlauncher`, `tvrecommendations`, `tvbugtracker` and, with the personal layer, `katniss` run again. `bootclean` stops them ([10](10-bootclean.md)), or `scripts/post-boot.sh` from the computer.

## Groups

The base suspends 14 packages; the personal layer adds 2.

| Group | Packages | Notes |
|---|---|---|
| Telemetry and feedback | `feedback`, `partnersetup`, `tvbugtracker` | `tv.bugreportsender` does not exist on this build |
| App blocker and NES services | `coreservice`, `daemon`, `sageservice` | `daemon` is persistent and suspending it does not stop it; see [03](03-coreservice.md) |
| Recommendations, partner rows | `tvrecommendations`, `autoinstalls.config.sei` | the `tvrecommendations` notification listener is turned off too; `leanbacklauncher.partnercustomizer` does not exist on this build |
| Preloaded apps | `printspooler`, `talkback` | |
| Stock launcher and unused | `tvlauncher`, `backdrop`, `camera2`, `gallery3d` | only once the new launcher is installed; the HOME role leaves `tvlauncher` first (`set-home-activity` to the Settings `FallbackHome`), because Android refuses to suspend the HOME role holder |
| Google Assistant and voice search | `katniss`, `tts` | only in `scripts/personal.sh`; turns off voice search and the Assistant |
| Already removed by the owner | `tivo.atom`, `skywayclient`, `tvglobalkeyhandler` and 5 more | only with `apply-all.sh --with-owner-removals`; the owner had removed them before this project |

Besides packages, the base turns off the `tvrecommendations` notification listener (`cmd notification disallow_listener`) and makes the launcher clock the screensaver (`screensaver_components`). The personal layer changes the Assistant (`assistant`, `voice_interaction_service`), which `bootclean` writes again at every boot.

## Applying by hand, group by group

```bash
scripts/apply.sh examples/tivo-stream-4k/debloat.txt --only "<group>"
# test with the remote: Home, back, volume, YouTube, Netflix, Prime Video
adb reboot
scripts/status.sh
```

## Do not

- Start factory or test packages (`com.utsmta.app`, names with `factory`): on other devices that flips flags the shell cannot undo.
- Suspend `com.android.vending`, Play Services, `com.android.tv.settings`, the keyboard, `com.sei.hdmi.services` (CEC), `com.uei.uas.tivo` (TV power from the remote) or `com.nes.tivo.remote.*` (remote pairing and firmware).
- Suspend `com.google.android.apps.mediashell` (Chromecast): tested; it breaks casting and frees no memory, because another component keeps a binding to it.

## Firmware updates

`coreservice` (suspended by the base) and `skywayclient` (removed only with `--with-owner-removals`) take part in the update check; without them the device may stop updating. Before updating, run `scripts/rollback.sh examples/tivo-stream-4k/debloat.txt`; afterwards, apply again and check with `scripts/status.sh`. An update can change what the firmware accepts.
