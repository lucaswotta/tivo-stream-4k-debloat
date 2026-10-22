# 01 — Preparação

## 1. Fotos do "antes" (faça primeiro, não tem volta depois)

- [ ] Home inicial inteira, com as linhas de recomendação (já tem: `img/home-original.jpg`)
- [ ] Aba "Loja" e aba "Apps"
- [ ] Configurações → Preferências do dispositivo → Sobre (versão do Android e build)
- [ ] Vídeo curto com cronômetro: ligar a TV e abrir YouTube e Netflix
- [ ] O stick plugado atrás da TV (foto de capa)

Salve em `docs/img/antes-*.jpg`. Tarje qualquer número de série, MAC, e-mail ou foto de perfil.

## 2. Ligar o ADB

1. **Configurações → Preferências do dispositivo → Sobre** → aperte OK em **Build** 7 vezes.
2. Volte → **Opções do desenvolvedor** → ligue **Depuração USB** (e **Depuração de rede/ADB**, se aparecer).
3. Anote o IP em **Configurações → Rede**.
4. No PC, na mesma rede:

```bash
adb connect 192.168.0.50:5555
adb devices          # aceite a chave do PC na TV na primeira vez
```

Sem `adb` instalado: [platform-tools do Android](https://developer.android.com/tools/releases/platform-tools).

> Desligue a depuração ao terminar o projeto. ADB aberto na rede é uma porta para qualquer um da sua rede.

## 3. Dados que você não pode perder

- Senha do Wi-Fi à mão: alguns aparelhos apagam a rede salva quando o assistente de configuração (`setupwraith`) é desabilitado.
- Lista dos apps que você realmente usa (Netflix, Prime, YouTube, etc.). Eles **não** entram no debloat.
- Rode `scripts/probe.sh` antes de qualquer mudança. A saída vira o registro do estado original.

## 4. Regras de segurança

- Nunca desabilitar: `android`, `com.android.systemui`, `com.android.settings`, `com.android.tv.settings`, `com.android.providers.*`, `permissioncontroller`, `packageinstaller`, Play Store, Play Services, teclado.
- Nunca desabilitar o launcher original **antes** de ter outro instalado e funcionando.
- Lotes de no máximo ~5 pacotes, com teste do controle e reboot entre eles.
