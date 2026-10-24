# 01 — Preparação

[English](../01-preparation.md)

## Ligar o ADB

1. Configurações, Preferências do dispositivo, Sobre: aperte OK em Build 7 vezes.
2. Volte, abra Opções do desenvolvedor e ligue Depuração USB. Neste firmware não existe uma opção separada de depuração pela rede: com a Depuração USB ligada, a porta 5555 já abre na rede.
3. Anote o IP em Configurações, Rede e Internet.
4. No computador, na mesma rede:

```bash
adb connect 192.168.0.50:5555
adb devices          # na primeira vez, aceite a chave do computador na TV
```

Até a chave ser aceita, `adb connect` responde `failed to authenticate`. Sem `adb` instalado: [platform-tools do Android](https://developer.android.com/tools/releases/platform-tools).

O `bootclean` exige que a Depuração USB fique ligada. A porta só aceita chaves que a TV autorizou: nunca aceite na TV um aviso de depuração que você não pediu.

## Antes de mudar qualquer coisa

- Fotografe a tela inicial e anote o build (Configurações, Preferências do dispositivo, Sobre).
- Rode `scripts/probe.sh`: ele salva em `runs/` o estado original (pacotes, dono da Home, dono do Wi-Fi, memória) e não altera nada.
- Tenha a senha do Wi-Fi à mão. Em alguns aparelhos a rede salva pertence ao assistente de configuração (`setupwraith`) e some se ele for desligado; nesta unidade ela pertence a `android.uid.system`.
- Liste os apps que você usa (Netflix, Prime Video, YouTube). Nenhum deles entra no debloat.

## Regras de segurança

- Nunca desligue `android`, `com.android.systemui`, `com.android.settings`, `com.android.tv.settings`, `com.android.providers.*`, `permissioncontroller`, `packageinstaller`, Play Store, Play Services nem o teclado. O `apply.sh` recusa esses pacotes mesmo que a lista os traga.
- Nunca suspenda o launcher original antes de o novo estar instalado e respondendo à tecla Home. O `apply-all.sh` deixa esse passo por último.
- Aplicando à mão, vá em grupos pequenos, com teste do controle e reboot entre eles ([04](04-debloat.md)).
