# 05 — Launcher

[English](../05-launcher.md)

## Escolha

O launcher é o do [cleanyourtv](https://github.com/Gathin23/cleanyourtv) (`com.gathin.tvhome` 2.6, commit `30626a8`, MIT): nativo, sem permissão `INTERNET`, 482 KB, com fundo na cor do app em foco, saudação, relógio, favoritos e menu de app. Mede 21 a 22 MB de PSS, contra 60 a 108 MB do launcher original.

Alternativas consideradas: Projectivy (pronto na Play Store, mas maior e na lista de remoção do `coreservice`) e FLauncher (leve, menos mantido, também na lista). O custo da escolha é um patch a reaplicar a cada versão nova do cleanyourtv; o `scripts/build-launcher.sh` fixa o commit.

## Como a tecla Home chega ao launcher

Três fatos medidos neste firmware:

1. `cmd package set-home-activity` responde `Success` e registra o papel HOME, mas a tecla Home continua abrindo o `tvlauncher`: o filtro dele tem `priority=2`, um app instalado não passa de 0, e o Android escolhe pela prioridade antes da preferência do usuário.
2. `pm disable-user`, `pm disable <componente>` e `uninstall --user 0` do `tvlauncher` são recusados, e as Configurações da TV não oferecem Desativar para ele.
3. O `com.nes.coreservice` desinstala no boot todo app não-sistema que declare a categoria HOME ([03](03-coreservice.md)).

Solução:

- O launcher não declara HOME. O patch `launcher/base/home-category.patch` tira a categoria do `intent-filter` da `MainActivity`, que continua listada como `LEANBACK_LAUNCHER`.
- Um serviço de acessibilidade em APK separado (`homekey/`, 13 KB, sem permissões, só filtro de teclas e sem eventos de tela) abre `com.gathin.tvhome/.MainActivity` quando a tecla Home real é pressionada e quando o serviço liga no boot. Sem o launcher instalado, a tecla passa para o original.

Limites:

- A tecla injetada por ADB (`input keyevent KEYCODE_HOME`) não passa pelo serviço e abre o `tvlauncher`; só o botão real do controle passa.
- `adb install -r` e `am force-stop` do launcher desligam os serviços de acessibilidade. `scripts/install-launcher.sh` e `scripts/push-theme.sh` os religam e conferem.
- Um app não consegue parar processos de outros: `killBackgroundProcesses` é aceito e ignorado neste firmware. Por isso existe o `bootclean` ([10](10-bootclean.md)).

## Compilação

`scripts/build-launcher.sh` clona o cleanyourtv no commit fixado, aplica os patches de `launcher/base/` e roda o Gradle do projeto com o JDK 17 do toolchain (ignora o `JAVA_HOME` do shell, porque o Gradle 8.9 não roda em Java 25). Também compila `homekey/` e `bootclean/` com `scripts/build-apk.sh`, sem Gradle. O `d8` do build-tools 34 aborta com as classes aninhadas que o `javac` 17 gera; o build usa o 35.

Com `--personal`, aplica também os patches de `launcher/personal/` e copia para o launcher as imagens de `$PERSONAL_THEME/res/`, se a pasta existir.

## Patches

| Patch | Camada | O que muda |
|---|---|---|
| `base/home-category.patch` | base | tira a categoria HOME da `MainActivity` |
| `personal/instant-focus-zoom.patch` | pessoal | com `animations: false`, o app selecionado ainda cresce 10%, na hora (o original zerava o zoom junto com as animações); o contorno acompanha o tamanho |
| `personal/no-glass-fill.patch` | pessoal | o destaque deixa de pintar o véu branco e o brilho sobre o tile; ficam o anel e o halo |
| `personal/names-below-dock-only.patch` | pessoal | a dock nunca mostra nomes nem reserva espaço para eles; na grade, só o app em foco mostra o nome. Aplica depois do `instant-focus-zoom`, que altera linhas vizinhas |
| `personal/top-bar-edge-to-dock.patch` | pessoal | na barra de cima (Wi-Fi, Configurações), seta para fora do primeiro ou do último botão leva o foco ao primeiro app da dock |

## Temas

Em `examples/tivo-stream-4k/`, enviados por `scripts/push-theme.sh <pasta>`:

- `theme/`: base. Dock com Netflix, Prime Video e YouTube; menu ao segurar OK.
- `theme-personal/`: camada pessoal. Acrescenta `reduced_motion`, `animations: false`, `focus_overshoot: false`, `dock_title: true`, a Play Store na dock e os botões do controle ([08](08-controle.md)).

Para usar um tema fora do repositório, aponte `PERSONAL_THEME` para uma pasta com `config.json` e, se quiser banners próprios (`app_banners`), `res/drawable-nodpi/<nome>.png`. As chaves do tema estão em `themes/README.md` do cleanyourtv. Custo de cada opção de tema em [06](06-benchmark.md).

## Verificado

- A tecla Home real abre o launcher novo, inclusive depois de reboot.
- Guide, TiVo e Live abrem o que o tema define, e a Home volta ao launcher depois de cada um ([08](08-controle.md)).
- O botão do Assistente abre a Play Store na camada pessoal.

Não verificado: o microfone do controle com o Assistente do Google.
