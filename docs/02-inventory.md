# 02 — Inventory

[Português](pt-BR/02-inventario.md)

`scripts/probe.sh` saves everything to `runs/<date>-probe/` without changing the device. These are the commands it runs, for anyone who wants to do it by hand.

## Device identity

```bash
adb shell getprop ro.build.fingerprint
adb shell getprop ro.build.version.release   # Android version
adb shell getprop ro.build.version.sdk
adb shell getprop ro.product.model
adb shell getprop ro.product.device
```

## Packages

```bash
adb shell pm list packages -s          # system
adb shell pm list packages -3          # installed by the user
adb shell pm list packages -d          # disabled
adb shell pm list packages | grep -iE 'tivo|nes|sei|droidlogic|partner|autoinstall'
```

To see what a package does: `adb shell dumpsys package <package> | grep -E 'Activity|Service|Receiver' | head -40`.

## Who answers Home

```bash
adb shell cmd package query-activities -a android.intent.action.MAIN -c android.intent.category.HOME
```

Factory state: `com.google.android.tvlauncher` (priority 2) and the Settings `FallbackHome`.

## Who owns the saved Wi-Fi

```bash
adb shell dumpsys wifi | grep -o 'cname=[^ ]*' | sort -u
```

If `setupwraith` shows up, forget and reconnect the network in Settings before touching it.

## What uses memory

```bash
adb shell dumpsys meminfo | sed -n '/Total PSS by process/,/Total PSS by OOM/p' | head -40
```
