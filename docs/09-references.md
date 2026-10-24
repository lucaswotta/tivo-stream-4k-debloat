# 09 — Reference repositories

[Português](pt-BR/09-referencias.md)

Read on 2026-10-22 from shallow clones (`main`) of `Gathin23/cleanyourtv` (commit `30626a8`) and `simbasjungles/free-my-tv`. The name `free-my-tv` appears in several forks; the original they cite is `simbasjungles/free-my-tv`.

## cleanyourtv

ADB debloat plus a native launcher (`com.gathin.tvhome`, Java, `minSdk` 26, no `INTERNET`). MIT.

| Piece | Role |
|---|---|
| `PROMPT.md` | script for an agent: connect, back up, debloat, launcher, close ADB; the safety rules live here |
| `tools/disable.sh` / `restore.sh` | reads the list (one package per line, `#` comments), validates it and runs `pm disable-user --user 0` in batch through `tools/tv.py --batch` |
| `tools/recovery.py` | saves the state before the first change to `~/.cleanyourtv/`; `restore.sh` undoes from it |
| `tools/check.py`, `privacy.py`, `adb-closed.py` | list validation, privacy audit, check that port 5555 is closed |
| `examples/<brand-model>/debloat.txt` | one list per tested device, with optional `README.md` and `config.json` |

`disable.sh` guards, which refuse the list or skip the package:

1. Well-formed package name (the line goes into a TV shell).
2. Android core packages (`android`, `systemui`, `shell`, `phone`, `settings`, `tv.settings`, permissioncontroller, packageinstaller, ext.services, modulemetadata, `overlay.modules*`, `providers.*`), no override.
3. `setupwraith` skipped if it owns the saved Wi-Fi (`FORCE_SETUPWRAITH=1` overrides).
4. HOME owner skipped if no other app can answer HOME (`FORCE_HOME=1`).
5. Packages asking for `TV_INPUT_HARDWARE` skipped, since they are the HDMI/AV layer (`TVINPUT_ALLOW=1`).
6. Warning if `ro.adb.secure=0`.

Repository rules (`AGENTS.md`): no `pm uninstall` in lists or scripts, no root, no prebuilt APKs, firmware updater preferably kept, no factory or test package started, no IP, MAC or serial in commits. A new list needs model, Android and build on the first line, only packages used for a few days, one row in `examples/README.md` and one in `README.md`, and `python3 -m unittest discover -s tests` passing.

Where it differs from this project:

- cleanyourtv forbids `pm uninstall`. On the TiVo, `pm disable-user` is refused and `uninstall -k --user 0` is the only method that removes non-core packages. So the PR carried the list the way the Nokia 8000 did: no `disable.sh`, a `README.md` describing `suspend` + `appops`, and already removed apps as comments.
- `examples/nokia-streaming-box-8000` is the closest relative (SEI/NES, Amlogic, 2 GB), but on Android 14 and refusing everything on core packages. It keeps `coreservice`, `daemon`, `tvglobalkeyhandler`, `blerc` and `remoteota.*` for the LED, OTA, shortcut keys and remote pairing. `examples/dialog-viu-sei103dl` (Android 9) accepts `disable-user` and documents the NES global keys by number (Apps 5116, Prime Video 5119, Catch-up 5122).
- On the Nokia, the stock launcher has HOME `priority 2` and `set-home-activity` answers `Success` with no effect, the same picture as the TiVo. The way out documented there, `STOCK_LAUNCHER=none` with `HOME_KEY_SERVICE=1`, was not verified here; this project uses the launcher without HOME plus `homekey` ([05](05-launcher.md)).

## free-my-tv

Android app (Java, no Gradle: `build.sh` calls aapt2, javac, d8, zipalign and apksigner; ~2 MB APK) that is both home screen and screensaver, with web versions for LG webOS and Samsung Tizen. MIT.

- It is not a debloat list: the app switches a mode on and off. `HomeMode` saves the original state and, entering Free My TV mode, runs `pm disable-user --user 0` on a short list (`DEBLOAT`), with a `PROTECTED` list (picture, sound, inputs, CEC, pairing) and a dependency check first. Going back to Original re-enables everything and restores `set-home-activity`.
- It talks to the TV's own ADB at `127.0.0.1:5555` with its own key (`Adb.java`), which is why the TV asks for a second authorization. `bootclean` uses the same method.
- A `Watchdog` in a separate process falls back to the stock launcher after 3 failures in 5 minutes; a boot check reapplies the choice after a system update.
- Same Wi-Fi guard: if the saved network belongs to `setupwraith`, the switch stops and asks to forget and reconnect the network.
- The app needs TMDB, weather, crypto and `INTERNET`, the opposite of a lean launcher, so only the ADB client was reused.

## Comparison

| | cleanyourtv | free-my-tv | this repository |
|---|---|---|---|
| Devices | more than 230 folders in `examples/` | Google TV and Android TV, LG webOS, Samsung Tizen | 1 (TiVo Stream 4K, `SC.1272`) |
| Debloat | batch `pm disable-user`, with guards | short list per brand, reversible with a button | `pm suspend` and `appops`, 14 packages (16 with the personal layer), reversible by script |
| Launcher | its own: themes, modules, app library | its own: recommendations, weather, crypto, needs internet | cleanyourtv's with 1 patch (5 with the personal layer) |
| Home on a firmware that pins the launcher | listed as unsolved (Nokia 8000) | not checked | solved on this firmware |
| Remote buttons | `app_keys` by keycode and scancode | TCL only | plus the Live keycode 5124 and the Assistant button workaround |
| Process cleanup at boot | no | no | `bootclean` |
| Tests and CI | yes | yes | only the check scripts (`status.sh`, `bench.sh`) |

What this repository adds: the list of 53 packages and the boot trigger of `coreservice` ([03](03-coreservice.md)); the Home switch without declaring HOME, which survived several reboots; the Assistant button workaround, since that key never reaches an accessibility service ([08](08-remote.md)); and the cleanup after boot without a computer ([10](10-bootclean.md)).

What it lacks: breadth (one device against more than 230), themes, modules, app library, LG and Samsung versions, automated tests, CI and a review process. Validation is one unit, one day, and depends on one firmware version.

## Gaps

- `tools/tv.py`, `launcher/build-and-install.sh` and cleanyourtv's tests were not read line by line.
- free-my-tv's `DEBLOAT` and `PROTECTED` lists for Android 12 were not extracted.
- cleanyourtv's launcher without the HOME category patch was not tested on the TiVo: the removal by `coreservice` was observed with an app of this project that declared HOME.
- Nothing was tested on the Nokia 8000 or the Dialog ViU.
