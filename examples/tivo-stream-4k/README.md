# TiVo Stream 4K

[Português](README.pt-BR.md)

TiVo Stream 4K `IPA1104HDW` (SKU `RA2400`), made by SEI Robotics, Amlogic S905Y2, 2 GB of RAM, Android TV 12 (SDK 31), build `eSTREAM4K/SEI400TV/SEI400TV:12/SC/1272`, security patch 2025-07-05. Tested on 2026-10-22 on one unit, for one day and several reboots.

## Files

- `debloat.txt`: packages by group, with the reason for each. Apply with `scripts/apply-all.sh` or group by group with `scripts/apply.sh --only`.
- `theme/config.json`: base theme for the cleanyourtv launcher (dock with Netflix, Prime Video and YouTube; menu on hold OK).
- `theme-personal/config.json`: the owner's choices (no animations, title above the dock, Play Store in the dock, TiVo and Guide buttons). Applied by `scripts/personal.sh`.

## Firmware quirks

- `pm disable-user`, `pm hide` and `pm disable <component>` are refused. Every package in the base is suspended (`pm suspend` plus `appops`). Undo: `scripts/rollback.sh`.
- The stock launcher holds Home with priority 2 and cannot be disabled. An installed launcher does not replace it through `set-home-activity` (it answers `Success` and nothing changes). Home reaches the new launcher through an accessibility service (`homekey/`), and the new launcher does not declare the HOME category, because `com.nes.coreservice` uninstalls every non-system app that does.
- Port 5555 opens as soon as USB debugging is on, with key authorization; there is no separate network debugging option.
- The Assistant button (`ASSIST`) is handled by Android before the key filter: no service can intercept it. The workaround is to point the `assistant` setting to an activity that opens the Play Store.
- Remote `0471:1207` keycodes: TiVo `173` (`DVR`), Guide `172` (`GUIDE`), Live `5124`, Skip `272`, Netflix `265` (`STEM_1`), Assistant `ASSIST` (scancode 217; Android keycode 219 was never observed, because no service receives that key).
- Suspending does not stop the boot from restarting `coreservice`, `sageservice`, `tvlauncher`, `tvrecommendations`, `tvbugtracker` and, if suspended, `katniss`: `bootclean` stops them.
- `coreservice` removes 53 packages from its factory list at every boot, Downloader among them.

## Kept on purpose

`com.uei.uas.tivo` (QuickSet: TV power from the remote), `com.sei.hdmi.services` (HDMI-CEC), `com.nes.tivo.remote.pair` and `remote.ota` (remote), `com.google.android.apps.mediashell` (Chromecast), Play Store, Play Services, keyboard and Settings.

Details and measurements: [docs/](../../docs/).
