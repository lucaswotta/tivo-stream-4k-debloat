# TiVo Stream 4K Debloat

[Português](README.pt-BR.md)

![TiVo Stream 4K, remote and cable](docs/img/aparelho.jpg)

Scripts that give the TiVo Stream 4K (Android TV 12) a light launcher, a working Home key and no TiVo or NES services running in the background. No root, nothing deleted from the system, and one command undoes it.

| Factory | After `apply-all.sh` |
|---|---|
| ![Factory home screen](docs/img/home-original.jpg) | ![Home screen after](docs/img/home-base.png) |

## What changes

- The Android TV home screen, with its recommendation rows and Shop tab, is replaced by the [cleanyourtv](https://github.com/Gathin23/cleanyourtv) launcher: only your apps, 22 MB of memory against 64 MB for the stock one.
- The Home key on the remote opens the new launcher. On this firmware no installed launcher can take over Home the normal way; here a 13 KB accessibility service does it.
- `com.nes.coreservice`, which checks for updates once per second and uninstalls alternative launchers, is suspended and stopped.
- 14 telemetry, recommendation, TiVo and NES packages are suspended.
- After every boot, `bootclean` (17 KB) stops the 5 processes the system restarts even when suspended.

Free memory goes from 920 MB to between 1014 and 1151 MB. The processor, the boot time (48 s) and app start times stay the same.

## Requirements

- TiVo Stream 4K `IPA1104HDW` on Android 12, build `SC.1272` (Settings, Device Preferences, About). On another build the script warns and asks before going on.
- USB debugging on: in About, press Build 7 times; then Developer options, USB debugging. Port 5555 opens on the network, no cable needed.
- A Linux x86_64 computer on the same network, with `adb`, `curl`, `python3`, `unzip`, `tar` and `git`, and 1.5 GB free. The script downloads JDK 17 and the Android SDK by itself, from official sources with checksums, to build the APKs.

## Install

```bash
git clone https://github.com/lucaswotta/tivo-stream-4k-debloat && cd tivo-stream-4k-debloat
export TV_HOST=192.168.0.50          # your TiVo's IP
adb connect $TV_HOST:5555            # accept the prompt on the TV with "Always allow"

scripts/apply-all.sh --dry-run       # prints the plan, changes nothing
scripts/apply-all.sh                 # explains, asks, applies and checks
```

During the install, `bootclean` asks the TV for USB debugging authorization: tick "Always allow" with the TV awake. At the end, press Home on the remote, reboot, and run `scripts/status.sh` about 6 minutes after boot, once `bootclean` has run.

## What you accept

- `bootclean` keeps a USB debugging key authorized for good and runs fixed commands at every boot, so USB debugging has to stay on. Details in [docs/10-bootclean.md](docs/10-bootclean.md).
- At every boot, `coreservice` uninstalls Downloader and 52 other apps from a factory list, plus every app that declares the HOME category. Without root this cannot be prevented. To install APKs, use `scripts/install-apk.sh <file or URL>`. Details in [docs/03-coreservice.md](docs/03-coreservice.md).
- A firmware update may undo part of the changes.

## Undo

If you applied the personal layer (end of this page), run `scripts/personal.sh --undo` first.

```bash
scripts/rollback.sh examples/tivo-stream-4k/debloat.txt    # unsuspends the packages
scripts/install-launcher.sh --remove                       # removes launcher, Home key service and bootclean
```

## Measurements

Median of 3 runs of `scripts/bench.sh`. Method and every run in [docs/06-benchmark.md](docs/06-benchmark.md).

| Metric | Factory | After |
|---|---|---|
| Free memory (`MemAvailable`) | 920 MB | 1014 to 1151 MB |
| Launcher memory (PSS) | 64 MB | 22 MB |
| `coreservice` update checks in 180 s | 180 | 0 |
| Janky frames while browsing the launcher | not measured | 3 in ~650 |

The "factory" column already had 10 packages suspended, which alone did not change memory. App start times vary 400 to 630 ms between identical measurements, so they are not counted as a gain.

## How it works

| Part | What it does | Notes |
|---|---|---|
| `examples/tivo-stream-4k/debloat.txt` | the package list, by group, with the reason for each | [04](docs/04-debloat.md) |
| `launcher/base/` | one-line patch to cleanyourtv: drops the HOME category so `coreservice` does not delete the launcher | [05](docs/05-launcher.md) |
| `homekey/` | accessibility service that sends the Home key to the new launcher | [05](docs/05-launcher.md) |
| `bootclean/` | app that connects to the TV's own ADB after boot and stops the restarted processes | [10](docs/10-bootclean.md) |
| `scripts/` | `apply-all.sh` applies everything; `status.sh` checks without changing anything; `apply.sh` and `rollback.sh` work per group (`--only`) | |

More notes: [hardware](docs/00-hardware.md), [preparation](docs/01-preparation.md), [inventory](docs/02-inventory.md), [`coreservice`](docs/03-coreservice.md), [remote keycodes](docs/08-remote.md), [upstream contributions](docs/07-upstream.md), [references](docs/09-references.md), and the [lab notebook](docs/pt-BR/diario.md) (Portuguese), with the date, command and result of each step.

## Limitations

- Tested on one unit, over one day of use and several reboots.
- Build `SC.1272` only. The Nokia Streaming Box 8000 and the Dialog ViU share the manufacturer (SEI Robotics) and the middleware (NES) and probably behave the same, but were not tested.
- The install script runs on Linux only.

## Credits

- Launcher and list format: [cleanyourtv](https://github.com/Gathin23/cleanyourtv) (MIT). This device's list was merged there in [PR #1061](https://github.com/Gathin23/cleanyourtv/pull/1061), and the `coreservice` behavior is in [issue #1062](https://github.com/Gathin23/cleanyourtv/issues/1062).
- `bootclean`'s local ADB client: [free-my-tv](https://github.com/simbasjungles/free-my-tv) (MIT, `bootclean/LICENSE-free-my-tv`).

## Behind the project

I use a TiVo Stream 4K in Brazil, where the TiVo service does not work. What was left was a slow Android TV full of recommendations, on a firmware that deleted every launcher I installed. Finding out why the launcher kept disappearing led to `coreservice`, and the rest followed from there.

After the base, I tuned the device to my taste in a separate layer, `scripts/personal.sh` (`--undo` goes back to the base):

![Home screen with the personal layer](docs/img/home-personal.png)

- the focused app grows 10% at once, with the stock focus ring and a big title above the dock;
- the TiVo button opens YouTube, Guide opens Settings, and Live opens a live TV app I keep outside the repository;
- the Assistant button opens the Play Store, and the Google Assistant is off.

The buttons and apps are set in `examples/tivo-stream-4k/theme-personal/config.json`, or in your own theme folder through `PERSONAL_THEME` ([docs/05-launcher.md](docs/05-launcher.md#themes)).

## License

MIT. Suspending the wrong package can break features: read the list before running it.
