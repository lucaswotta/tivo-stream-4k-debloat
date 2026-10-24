# 01 — Preparation

[Português](pt-BR/01-preparacao.md)

## Turn on ADB

1. Settings, Device Preferences, About: press OK on Build 7 times.
2. Go back, open Developer options and turn on USB debugging. This firmware has no separate network debugging option: with USB debugging on, port 5555 is already open on the network.
3. Note the IP address under Settings, Network & Internet.
4. On the computer, on the same network:

```bash
adb connect 192.168.0.50:5555
adb devices          # the first time, accept the computer's key on the TV
```

Until the key is accepted, `adb connect` answers `failed to authenticate`. If `adb` is missing: [Android platform-tools](https://developer.android.com/tools/releases/platform-tools).

`bootclean` needs USB debugging to stay on. The port only accepts keys the TV has authorized: never accept a debugging prompt on the TV that you did not trigger.

## Before changing anything

- Take a picture of the home screen and note the build (Settings, Device Preferences, About).
- Run `scripts/probe.sh`: it saves the original state (packages, Home owner, Wi-Fi owner, memory) under `runs/` and changes nothing.
- Have the Wi-Fi password at hand. On some devices the saved network belongs to the setup wizard (`setupwraith`) and disappears if it is turned off; on this unit it belongs to `android.uid.system`.
- List the apps you use (Netflix, Prime Video, YouTube). None of them is part of the debloat.

## Safety rules

- Never turn off `android`, `com.android.systemui`, `com.android.settings`, `com.android.tv.settings`, `com.android.providers.*`, `permissioncontroller`, `packageinstaller`, the Play Store, Play Services or the keyboard. `apply.sh` refuses these packages even if a list has them.
- Never suspend the stock launcher before the new one is installed and answering the Home key. `apply-all.sh` leaves that step for last.
- When applying by hand, go in small groups, testing the remote and rebooting in between ([04](04-debloat.md)).
