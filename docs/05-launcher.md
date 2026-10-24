# 05 — Launcher

[Português](pt-BR/05-launcher.md)

## Choice

The launcher is [cleanyourtv](https://github.com/Gathin23/cleanyourtv)'s (`com.gathin.tvhome` 2.6, commit `30626a8`, MIT): native, no `INTERNET` permission, 482 KB, with a background in the color of the focused app, greeting, clock, favorites and an app menu. It uses 21 to 22 MB of PSS, against 60 to 108 MB for the stock launcher.

Alternatives considered: Projectivy (ready on the Play Store, but larger and on `coreservice`'s removal list) and FLauncher (light, less maintained, also on the list). The cost of the choice is a patch to reapply on each new cleanyourtv release; `scripts/build-launcher.sh` pins the commit.

## How the Home key reaches the launcher

Three facts measured on this firmware:

1. `cmd package set-home-activity` answers `Success` and records the HOME role, but the Home key still opens `tvlauncher`: its filter has `priority=2`, an installed app cannot go above 0, and Android picks by priority before the user's preference.
2. `pm disable-user`, `pm disable <component>` and `uninstall --user 0` on `tvlauncher` are refused, and the TV Settings offer no Disable for it.
3. `com.nes.coreservice` uninstalls at boot every non-system app that declares the HOME category ([03](03-coreservice.md)).

Solution:

- The launcher does not declare HOME. `launcher/base/home-category.patch` removes the category from the `MainActivity` `intent-filter`, which stays listed as `LEANBACK_LAUNCHER`.
- An accessibility service in a separate APK (`homekey/`, 13 KB, no permissions, key filter only and no screen events) opens `com.gathin.tvhome/.MainActivity` when the real Home key is pressed and when the service starts at boot. Without the launcher installed, the key goes to the stock one.

Limits:

- A key injected over ADB (`input keyevent KEYCODE_HOME`) does not go through the service and opens `tvlauncher`; only the real remote button does.
- `adb install -r` and `am force-stop` of the launcher turn the accessibility services off. `scripts/install-launcher.sh` and `scripts/push-theme.sh` turn them back on and check.
- An app cannot stop other apps' processes: `killBackgroundProcesses` is accepted and ignored on this firmware. That is why `bootclean` exists ([10](10-bootclean.md)).

## Build

`scripts/build-launcher.sh` clones cleanyourtv at the pinned commit, applies the patches in `launcher/base/` and runs the project's Gradle with the toolchain's JDK 17 (it ignores the shell's `JAVA_HOME`, because Gradle 8.9 does not run on Java 25). It also builds `homekey/` and `bootclean/` with `scripts/build-apk.sh`, without Gradle. The `d8` in build-tools 34 crashes on the nested classes `javac` 17 writes; the build uses 35.

With `--personal`, it also applies the patches in `launcher/personal/` and copies the images in `$PERSONAL_THEME/res/` into the launcher, if that folder exists.

## Patches

| Patch | Layer | What it changes |
|---|---|---|
| `base/home-category.patch` | base | removes the HOME category from `MainActivity` |
| `personal/instant-focus-zoom.patch` | personal | with `animations: false`, the selected app still grows 10%, at once (upstream dropped the zoom together with the animations); the outline follows the size |
| `personal/no-glass-fill.patch` | personal | the highlight no longer paints the white veil and sheen over the tile; the ring and the halo stay |
| `personal/names-below-dock-only.patch` | personal | the dock never shows names nor reserves room for them; in the grid, only the focused app shows its name. Applies after `instant-focus-zoom`, which changes nearby lines |
| `personal/top-bar-edge-to-dock.patch` | personal | in the top bar (Wi-Fi, Settings), an arrow past the first or last button moves focus to the first dock app |

## Themes

In `examples/tivo-stream-4k/`, pushed by `scripts/push-theme.sh <folder>`:

- `theme/`: base. Dock with Netflix, Prime Video and YouTube; menu on hold OK.
- `theme-personal/`: personal layer. Adds `reduced_motion`, `animations: false`, `focus_overshoot: false`, `dock_title: true`, the Play Store in the dock and the remote buttons ([08](08-remote.md)).

To use a theme kept outside the repository, point `PERSONAL_THEME` at a folder with `config.json` and, for custom banners (`app_banners`), `res/drawable-nodpi/<name>.png`. The theme keys are listed in cleanyourtv's `themes/README.md`. The cost of each theme option is in [06](06-benchmark.md).

## Verified

- The real Home key opens the new launcher, including after a reboot.
- Guide, TiVo and Live open what the theme sets, and Home goes back to the launcher after each ([08](08-remote.md)).
- With the personal layer, the Assistant button opens the Play Store.

Not verified: the remote's microphone with the Google Assistant.
