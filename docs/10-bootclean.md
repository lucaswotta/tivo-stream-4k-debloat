# 10 — Automatic cleanup after boot

[Português](pt-BR/10-bootclean.md)

`bootclean` (`dev.lucaswotta.bootclean`, 17 KB) stops the processes the system restarts at every boot even though their packages are suspended, with no computer needed.

## The problem

`pm suspend`, `appops` and `killBackgroundProcesses` called from an app do not stop the boot from restarting `com.nes.coreservice`, `com.tivo.sageservice`, `com.google.android.tvlauncher`, `com.google.android.tvrecommendations` and `com.nes.tvbugtracker`, plus `com.google.android.katniss` with the personal layer. Only `am force-stop` from the shell takes them down, and the shell is only reachable through ADB. This build has no auto-start permission (`AUTO_START` and similar do not exist in `cmd appops`).

## What it does

1. `BootReceiver` gets `BOOT_COMPLETED` and schedules four runs with `JobScheduler`: right away and 60, 150 and 300 s later, for services that start late. The first one runs at ~48 s of uptime, when the TV finishes starting.
2. `CleanJob` connects to the TV's own `adbd` at `127.0.0.1:5555`, authenticates with its own RSA key and runs the commands of the compiled profile.
3. The ADB client (`Adb.java`) is adapted from free-my-tv (MIT, license in `bootclean/LICENSE-free-my-tv`).

## Profiles

What the APK runs is fixed at build time from `bootclean/profile/*.txt`; `scripts/bootclean-profile.sh` generates `Profile.java`. Nothing can be added later from outside.

- `base.txt`: `force-stop` of the five base packages.
- `personal.txt`: adds the Assistant. It writes `assistant = dev.lucaswotta.homekey/.AssistActivity` (the Assistant button opens the Play Store, see [08](08-remote.md)), empties `voice_interaction_service` and force-stops `katniss`. Android fills both settings with Katniss at every boot, and while it is the registered Assistant the system keeps the `katniss:interactor` process alive.

`scripts/build-launcher.sh` builds the base profile; with `--personal`, the personal one.

## `tvrecommendations`

It started at boot as a notification listener (`NotificationsService`). The system keeps a binding to every enabled listener, so `force-stop` did not help. `apply-all.sh` removes the listener with `cmd notification disallow_listener com.google.android.tvrecommendations/com.google.android.tvrecommendations.NotificationsService`; `enabled_notification_listeners` stays empty across reboots, unlike the Assistant. The process still starts at boot, through a query to `NotificationContentProvider`, and `bootclean` stops it like the others. To undo: `cmd notification allow_listener` with the same component.

## What it needs and what it costs

- Permissions: `INTERNET` (only for the socket on `127.0.0.1`; the code opens no other address) and `RECEIVE_BOOT_COMPLETED`. It is a separate APK from `homekey`, which sees every key and has no permissions, so network access and key reading never share a package.
- USB debugging always on.
- An ADB key authorized for good. On the first run the TV asks "Allow USB debugging?": tick "Always allow", with the TV awake. With the screensaver in front, the prompt is denied by itself.
- Commands: only those of the compiled profile. The receiver is exported and accepts the `dev.lucaswotta.bootclean.RUN` action, which only schedules the same cleanup.
- It does not prevent the app removals by `coreservice`'s list ([03](03-coreservice.md)), which happen in the first ~35 s of boot, before `bootclean` exists.

## Undo

```bash
scripts/personal.sh --undo              # if the personal layer is applied: gives the Assistant back and rebuilds with the base profile
scripts/install-launcher.sh --remove    # uninstalls launcher, homekey and bootclean
```

Then, on the TV: Developer options, Revoke USB debugging authorizations.

## Install

`scripts/build-launcher.sh` builds the three APKs; `scripts/install-launcher.sh` installs them, turns on the accessibility services and triggers the first `bootclean` run.
