# 00 — Hardware and device family

[Português](pt-BR/00-hardware.md)

![Label, with HSN and MAC removed](img/etiqueta.jpg)

## Label

| Field | Value | Why it matters |
|---|---|---|
| Model | `IPA1104HDW 01 400 09T TIVO` | hardware revision |
| SKU | `RA2400` | US retail version |
| FCC ID | `2AOVU-IPA1104HDW` | `2AOVU` is SEI Robotics' grantee code |
| Power | 5 V ⎓ 1 A | some TV USB ports do not deliver this and the stick freezes; use a power adapter |
| Marks | Dolby Vision, Dolby Digital Plus, Bluetooth | |

Do not publish the HSN or the MAC from the label. The photos in this repository are redacted.

## Hardware, read from the device

| Item | Value |
|---|---|
| SoC | Amlogic S905Y2, 4 ARM cores from 100 MHz to 1.8 GHz, `interactive` governor |
| GPU | Mali-G31, OpenGL ES 3.2 |
| Memory | 2 GB |
| Userspace | 32-bit, `armeabi-v7a` only |
| UI | 1920x1080 at 320 dpi |
| Hardware decoders | H.264, H.265, VP9; no AV1 |
| System | Android TV 12 (SDK 31), build `eSTREAM4K/SEI400TV/SEI400TV:12/SC/1272`, patch 2025-07-05 |

The governor and the frequency belong to the `system` user, so ADB cannot change them, and the bootloader is locked.

## The SEI/NES family

The TiVo Stream 4K is made by SEI Robotics, which ships the NES middleware on devices for several operators. cleanyourtv already documents two relatives:

| Device | List in cleanyourtv | What it teaches |
|---|---|---|
| Nokia Streaming Box 8000 (SEI600NK4, Android TV 14) | `examples/nokia-streaming-box-8000/` | same classic launcher with a Shop tab; the firmware refuses `pm disable-user` and the list uses `pm suspend` and `appops`; `com.nes.coreservice` was kept there because it also drives the LED, OTA messages and an analytics receiver |
| Dialog ViU (SEI103DL, Android TV 9) | `examples/dialog-viu-sei103dl/` | `com.nes.blerc` (Bluetooth remote) and `com.nes.tvglobalkeyhandler` (shortcut buttons) are essential; `com.nes.skywayclient` shows boot ads and installs apps silently |

Confirmed on the TiVo, build `SC.1272`:

- `pm disable-user` is refused, as on the Nokia: `Warning! This command is illegal!`. `pm suspend` and `appops` work; `pm uninstall --user 0` works only for apps that are not core.
- NES and TiVo packages present: `com.nes.coreservice`, `com.nes.daemon`, `com.nes.tvbugtracker`, `com.nes.tivo.quickset`, `com.nes.tivo.remote.ota`, `com.nes.tivo.remote.pair`, `com.tivo.sageservice`, `com.uei.uas.tivo` and `com.sei.hdmi.services`. Remote pairing, CEC and QuickSet stay; the rest is suspended.
- The TiVo's `com.nes.coreservice` does what the Nokia's does and, on top of that, uninstalls at boot a fixed list of 53 packages and every non-system app that declares the HOME category. See [03](03-coreservice.md).
