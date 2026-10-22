# 02 — Inventário

O `scripts/probe.sh` salva tudo em `runs/<data>-probe/`. Os comandos abaixo são o que ele roda, para quem quiser entender ou fazer na mão.

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
adb shell pm list packages -3          # instalados por você
adb shell pm list packages -d          # já desabilitados
adb shell pm list packages | grep -iE 'tivo|nes|sei|droidlogic|partner|autoinstall'
```

## Quem é a Home

```bash
adb shell cmd package query-activities -a android.intent.action.MAIN -c android.intent.category.HOME
```

Esperado: `com.google.android.tvlauncher` (launcher clássico, com abas Início/Loja/Apps).

## Quem é dono do Wi-Fi salvo

```bash
adb shell dumpsys wifi | grep -o 'cname=[^ ]*' | sort -u
```

Se aparecer `setupwraith`, **esquecer e reconectar** a rede em Configurações antes de mexer nele.

## O que pesa em memória

```bash
adb shell dumpsys meminfo | sed -n '/Total PSS by process/,/Total PSS by OOM/p' | head -40
```

## Tabela de classificação (preencher)

| Pacote | O que faz (como descobri) | Decisão | Lote |
|---|---|---|---|
| `com.nes.coreservice` | Desinstala launchers/ADB tools (AFTVnews); no Nokia também faz LED/OTA | investigar | 2 |
| `com.google.android.tvlauncher` | Home original | desabilitar só no fim | 4 |
| … | | | |

Para descobrir o que um pacote faz: `adb shell dumpsys package <pkg> | grep -E 'Activity|Service|Receiver' | head -40`.
