# 06 — Measurements

[Português](pt-BR/06-benchmark.md)

Device: TiVo Stream 4K, Android 12 build `SC.1272`, 2 GB of RAM. Measured on 2026-10-22, on one unit, with `scripts/bench.sh` (3 runs, median) unless noted. Raw output lives in `runs/`, kept out of Git because it can hold device data; the [lab notebook](pt-BR/diario.md) (Portuguese) has the command and time of each measurement.

## Reading the numbers

- Measurements with the TV in different states (just rebooted or on for hours) are not comparable. Each row states its state.
- The cold start of the same app varies a lot between identical measurements: the launcher opened in 408 to 634 ms with no change at all. Differences of 100 ms or less mean nothing.
- `MemAvailable` moves about 15 MB between identical runs.

## Memory and processes

| State | `MemAvailable` | Processes | Launcher PSS | YouTube | Netflix | Prime Video |
|---|---|---|---|---|---|---|
| Baseline: factory minus 7 apps the owner had removed; on for hours, no reboot | 976 MB | 314 | 104 MB | 507 ms | 529 ms | 785 ms |
| `sageservice` and `daemon` suspended, no reboot | 990 MB | 315 | 108 MB | 439 ms | 521 ms | 646 ms |
| 10 packages suspended, `force-stop` on `coreservice` and `sageservice`, no reboot | 1058 MB | 310 | 68 MB | 521 ms | 504 ms | 689 ms |
| Clean comparison, 3 reboots, without the suspensions | 905 MB | 332 | 60 MB | 668 ms | 694 ms | 1519 ms |
| Clean comparison, 3 reboots, with the 10 suspensions | 920 MB | 330 | 64 MB | 673 ms | 775 ms | 1479 ms |
| cleanyourtv launcher, `post-boot.sh` | 1060 MB | 317 | 21 MB | 526 ms | 511 ms | 655 ms |
| + stock launcher and Katniss stopped | 1151 MB | 316 | 22 MB | 545 ms | 653 ms | 655 ms |
| Full cycle with `bootclean`, 6 min after boot | 1014 MB | n/a | n/a | n/a | n/a | n/a |
| Same, benchmark right after | 1139 MB | 312 | 22 MB | 508 ms | 491 ms | 961 ms |

Reading:

- Suspending the first 10 packages alone gave no measurable gain (905 against 920 MB, in the clean comparison after reboot).
- Memory goes up once the stock launcher and `coreservice`, `sageservice`, `katniss` and `tvrecommendations` are stopped: from ~920 MB to 1014 to 1151 MB, about 100 to 200 MB.
- Launcher PSS drops from 60 to 108 MB to 21 to 22 MB.
- Cold start of the streaming apps did not improve consistently. The 961 ms for Prime Video in the last row is the first launch after boot.

## Background activity

| Measurement | Before | After |
|---|---|---|
| `ClearDataForGotaFun: getSystemUpdateStatus()` (`coreservice` update check) | 180 in 180 s | 0 in 90 s |
| Log lines per minute from `com.nes.coreservice` | 61 | 0 |
| Idle CPU | ~10% of the 4 cores | same; what is left is the vendor audio service (~26% of one core, with audio on standby) and `com.uei.uas.tivo` (~9%, the remote's QuickSet, kept because it powers the TV) |

## UI

`dumpsys gfxinfo com.gathin.tvhome`, 24 D-pad presses per pass, 0.35 s apart:

| Condition | Frames per pass | Janky frames | p90 frame |
|---|---|---|---|
| UI at 1080p | ~650 | 3 to 4 (0.46 to 0.61%) | 16 to 27 ms |
| UI at 720p (`wm size 1280x720`, not applied) | ~650 | 0 | 11 ms |
| `reduced_motion` | ~125 | 0 to 5 | 15 to 23 ms |
| `reduced_motion` + `animations: false` + `focus_overshoot: false` + `module_cards: false` + `ambient_glow: false` | ~21 | 1 to 3 | 10 to 27 ms |

Janky frames stay at ~3 per pass, on vertical moves, and no theme option removes them. The final state of the personal layer (the theme above plus the 4 patches in `launcher/personal/`) was not measured.

## What `scripts/bench.sh` measures

| Metric | How |
|---|---|
| Available memory | `MemAvailable` from `/proc/meminfo` |
| Processes | lines of `ps -A` |
| Enabled packages | `pm list packages -e` (suspending does not disable, so it does not change) |
| Launcher PSS | `dumpsys meminfo <launcher>` |
| Cold start | `am force-stop` and `am start -W` (`TotalTime`) |
| Boot (`--boot`) | from `adb reboot` to `sys.boot_completed=1` |

```bash
scripts/bench.sh before                      # 3 runs, no reboot
scripts/bench.sh after --boot                # reboots the TV 3 times
HOME_CMD='am start -n com.gathin.tvhome/.MainActivity' HOME_PKG=com.gathin.tvhome scripts/bench.sh after
```

With the new launcher, a Home key injected over ADB still opens the stock one (only the real key goes through the service), hence `HOME_CMD` and `HOME_PKG`. A `force-stop` of the launcher turns the key services off: run `scripts/push-theme.sh` afterwards.
