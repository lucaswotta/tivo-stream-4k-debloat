# 07 — Contributions to the reference repositories

[Português](pt-BR/07-upstream.md)

## cleanyourtv (Gathin23/cleanyourtv)

| What | Link | Content | State |
|---|---|---|---|
| Pull request | [#1061](https://github.com/Gathin23/cleanyourtv/pull/1061) | `examples/tivo-stream-4k/` (`debloat.txt`, `README.md` with apply and undo, `theme/config.json` with the dock only) and the device table rows | opened 2026-10-22, merged 2026-10-23 |
| Issue | [#1062](https://github.com/Gathin23/cleanyourtv/issues/1062) | `com.nes.coreservice` uninstalls at boot every non-system app that declares HOME and a list of 53 packages | open |

On merge, the maintainer commented out the stock launcher group in their `debloat.txt`, with a note: cleanyourtv's launcher does not answer the Home key on this device yet, and their README says to uncomment the group only once another launcher does. On the issue, the maintainer asked for a PR that adds the finding to the TiVo/NES device notes and to the Nokia 8000 README, marked "not yet tested there". That PR has not been opened yet.

The text sent is in [`upstream/pr-1061-body.md`](upstream/pr-1061-body.md) and [`upstream/issue-1062-body.md`](upstream/issue-1062-body.md). The PR patch (commit `f85f700` on the `add-tivo-stream-4k` branch of the `lucaswotta/cleanyourtv` fork, on top of upstream `30626a8`) is in [`upstream/`](upstream/).

The PR went out with a caveat in its body: their `CONTRIBUTING.md` asks for packages used for "a few days", and this was one day with several reboots. With it applied, cleanyourtv's `python3 -m unittest discover -s tests` passes (540 tests, 3 skipped). The PR carries no `pm uninstall` (the apps the owner had already removed are comments) and none of the personal choices (buttons, animations, Assistant).

Upstream rules the PR follows (`CONTRIBUTING.md` and `AGENTS.md`): `examples/<brand>-<model>/debloat.txt` in the format of `xiaomi-mi-tv-4a`; a header with model, Android and build; one row in `examples/README.md` and one in the TV table of `README.md`, with the same text; nothing to uninstall; no install scripts in the folder.

## free-my-tv (simbasjungles/free-my-tv)

Nothing sent. Their `Adb.java` is the base of `bootclean`'s local ADB client, with the MIT license copied to `bootclean/LICENSE-free-my-tv`. A possible note, not tested: on devices with `com.nes.coreservice`, their app declares HOME and would probably be uninstalled at boot by the same rule.
