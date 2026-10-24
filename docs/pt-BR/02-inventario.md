# 02 — Inventário

[English](../02-inventory.md)

O `scripts/probe.sh` salva tudo em `runs/<data>-probe/` sem alterar nada no aparelho. Os comandos abaixo são os que ele roda, para quem quiser fazer à mão.

## Identidade do aparelho

```bash
adb shell getprop ro.build.fingerprint
adb shell getprop ro.build.version.release   # versão do Android
adb shell getprop ro.build.version.sdk
adb shell getprop ro.product.model
adb shell getprop ro.product.device
```

## Pacotes

```bash
adb shell pm list packages -s          # de sistema
adb shell pm list packages -3          # instalados pelo usuário
adb shell pm list packages -d          # desabilitados
adb shell pm list packages | grep -iE 'tivo|nes|sei|droidlogic|partner|autoinstall'
```

Para ver o que um pacote faz: `adb shell dumpsys package <pacote> | grep -E 'Activity|Service|Receiver' | head -40`.

## Quem responde à Home

```bash
adb shell cmd package query-activities -a android.intent.action.MAIN -c android.intent.category.HOME
```

De fábrica: `com.google.android.tvlauncher` (prioridade 2) e a `FallbackHome` das Configurações.

## Quem é dono do Wi-Fi salvo

```bash
adb shell dumpsys wifi | grep -o 'cname=[^ ]*' | sort -u
```

Se aparecer `setupwraith`, esqueça e reconecte a rede em Configurações antes de mexer nele.

## O que pesa em memória

```bash
adb shell dumpsys meminfo | sed -n '/Total PSS by process/,/Total PSS by OOM/p' | head -40
```
