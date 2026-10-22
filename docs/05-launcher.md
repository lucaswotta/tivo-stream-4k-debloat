# 05 — Launcher

## Opções

| Launcher | Prós | Contras |
|---|---|---|
| **cleanyourtv** (`launcher/` do repo base, ~300 KB) | Sem rede, sem serviços, feito para 1 GB de RAM; remapeia botões do controle | Precisa compilar (JDK 17 + Android SDK) |
| **Projectivy** | Pronto na Play Store, bonito | Maior; era justamente o alvo do CoreService |
| **FLauncher** | Open source, leve | Menos manutenção |

Escolha inicial: o launcher do cleanyourtv, porque o PR fica coerente com o projeto base. Projectivy fica como plano B.

**Decisão final (2026-10-22): o launcher do cleanyourtv** (`com.gathin.tvhome` 2.6, commit `30626a8`), com um patch de uma linha (`launcher/home-category.patch`). Motivo: pedido do dono; é nativo, sem `INTERNET`, 482 KB, com fundo ambiente na cor do app focado, saudação, relógio, favoritos e menu de app. Mede 21 MB de PSS, o mesmo de um protótipo próprio de 17 KB que foi descartado por ser simples demais e ter o foco quebrado. Custo se errado: um patch a reaplicar em cada versão nova do cleanyourtv.

O protótipo próprio (`dev.lucaswotta.homelite`) foi removido do aparelho; do código dele só ficou o serviço de tecla Home, em `homekey/`.

## Patches no launcher

`scripts/build-launcher.sh` aplica todos os `launcher/*.patch` ao commit fixado do `cleanyourtv`:

| Patch | O que muda |
|---|---|
| `home-category.patch` | tira a categoria HOME do `MainActivity` (o `coreservice` apaga apps não-sistema que a declaram) |
| `no-focus-highlight.patch` | `GlassView` (o destaque em vidro que acompanha o foco) deixa de desenhar: sem borda branca, sem os 12 anéis de brilho e sem o brilho do vidro; também deixa de pedir uma camada de hardware para ele |
| `instant-focus-zoom.patch` | com `animations: false` o app selecionado ainda cresce 10%, mas na hora (o código original zerava o zoom junto com as animações); o contorno do destaque acompanha o tamanho |

Tema de movimento (`examples/tivo-stream-4k/theme/config.json`): `reduced_motion: true`, `animations: false`, `focus_overshoot: false`. O foco muda de botão sem deslizar e sem mola, e o app selecionado só cresce 10%, sem borda nem brilho. Medições dos custos de cada opção em [diário](diario.md).

## Como a tecla Home chega ao launcher

Três fatos medidos neste firmware (Android 12, build 1272):

1. `cmd package set-home-activity` responde `Success` e registra o papel HOME e a atividade preferida, mas a tecla Home continua abrindo o `tvlauncher`: o filtro dele tem `priority=2`, um app instalado não passa de 0 e o Android escolhe pela prioridade antes da preferência do usuário.
2. `pm disable-user`, `pm disable <componente>` e `uninstall --user 0` do `tvlauncher` são recusados, e as Configurações da TV não têm botão Desativar nele.
3. `com.nes.coreservice` desinstala, no boot, todo app não-sistema que declara a categoria HOME ([03](03-coreservice.md)).

Solução: o launcher **não declara HOME** (o patch remove a categoria do `intent-filter` da `MainActivity`; ela segue listada como `LEANBACK_LAUNCHER`). Um serviço de acessibilidade em APK separado de 13 KB e sem permissões (`homekey/`, só filtro de teclas, sem eventos de tela) abre `com.gathin.tvhome/.MainActivity` por componente quando a tecla Home real é pressionada e quando liga no boot. Sem o launcher instalado, a tecla passa para o original.

- A tecla injetada por ADB (`input keyevent KEYCODE_HOME`) **não** passa pelo serviço e abre o `tvlauncher`; só vale o botão real do controle.
- `adb install -r` apaga a habilitação do serviço: use `scripts/install-launcher.sh`, que reabilita e confere. Para compilar: `scripts/build-launcher.sh` (clona o commit fixado, aplica o patch e roda o Gradle do projeto com o JDK 17 do toolchain; ignora o `JAVA_HOME` do shell, porque o Gradle 8.9 não roda em Java 25).
- Um app não consegue parar processos de outros: `killBackgroundProcesses` é aceito e ignorado neste firmware. Por isso `scripts/post-boot.sh` (ADB) para `coreservice`, `sageservice` e `tvlauncher` depois de cada boot. O `tvrecommendations` é religado pelo sistema em 1 s e fica de fora.
- Armadilha de build do `homekey/` (sem Gradle): o `d8` 8.2 do build-tools 34 aborta com classes internas não estáticas ou anônimas geradas pelo `javac` 17; o serviço não usa nenhuma.

## Pontos de atenção do TiVo (herdados dos primos SEI/NES)

- No Nokia 8000, o `tvlauncher` tem prioridade HOME 2 e não pôde ser desabilitado: `set-home-activity` diz Success e nada muda. **Testar isso cedo**, antes de investir no resto.
- Botões do controle (Netflix, Guide, Live, TiVo) provavelmente passam por `com.nes.tvglobalkeyhandler`. Ler os códigos com `adb shell getevent -lt` e mapear com `app_keys` no launcher.
- Proteção de tela: se o `backdrop` sair, apontar `screensaver_components` para o relógio do launcher.

## Verificação

- [x] Botão Home abre o launcher novo, inclusive depois de reboot (botão real, 2026-10-22)
- [ ] Botões Netflix / TiVo / Guide / Live fazem algo útil
- [ ] Microfone (Assistente) funciona, se mantido
- [ ] Wi-Fi volta sozinho depois do reboot
