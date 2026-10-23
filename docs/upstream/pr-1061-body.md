Adds `examples/tivo-stream-4k/`: a `debloat.txt`, a `README.md` with apply and undo, and a `theme/config.json` with the dock. SEI/NES family like the Nokia 8000: `pm disable-user`, `pm disable <component>` and `pm hide` are refused, so the list is suspended (`pm suspend` plus `appops`), following `examples/nokia-streaming-box-8000/`. Nothing in the list uninstalls.

The README also records how Home can reach another launcher on this firmware: `com.nes.coreservice` uninstalls, at every boot, every non-system app that declares `android.intent.category.HOME` and a fixed list of 53 packages, so the launcher has to drop the HOME category and be opened by component from an accessibility service. That is the part the Nokia 8000 folder lists as unsolved. I will open an issue with the details.

**Tested on:** TiVo Stream 4K (`IPA1104HDW`, SEI400TV, Amlogic S905Y2), Android TV 12, build `SC.1272`, one unit.

### If this adds or changes a TV list
- [x] `examples/tivo-stream-4k/debloat.txt`, header with model, Android version and firmware build
- [ ] Only packages I actually disabled and lived with; anything I had to re-enable is noted. **One day of use, with about ten reboots, not "a few days".** Happy to hold this until there are more days, or to comment out any line you think is too early.
- [x] A row in `examples/README.md` and one in the README's TV table
- [x] Nothing in the list uninstalls (the packages the owner had already removed are comments)

`python3 -m unittest discover -s tests`: 540 tests, OK (3 skipped), with this folder in place. The launcher is untouched.

Full write-up, patches and measurements: https://github.com/lucaswotta/tivo-stream-4k-debloat
