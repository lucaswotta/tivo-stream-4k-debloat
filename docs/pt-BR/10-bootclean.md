# 10 — Limpeza automática depois do boot

[English](../10-bootclean.md)

O `bootclean` (`dev.lucaswotta.bootclean`, 17 KB) para os processos que o sistema religa a cada boot mesmo com o pacote suspenso, sem precisar de computador.

## O problema

`pm suspend`, `appops` e `killBackgroundProcesses` chamado por um app não impedem o boot de religar `com.nes.coreservice`, `com.tivo.sageservice`, `com.google.android.tvlauncher`, `com.google.android.tvrecommendations` e `com.nes.tvbugtracker`, e, na camada pessoal, `com.google.android.katniss`. Só `am force-stop` pelo shell os derruba, e o shell só existe pelo ADB. Este build não tem permissão de início automático (`AUTO_START` e semelhantes não existem em `cmd appops`).

## O que ele faz

1. O `BootReceiver` recebe `BOOT_COMPLETED` e agenda quatro execuções no `JobScheduler`: na hora e 60, 150 e 300 s depois, para os serviços que sobem tarde. A primeira roda com ~48 s de uptime, quando a TV termina de ligar.
2. O `CleanJob` conecta ao `adbd` da própria TV em `127.0.0.1:5555`, autentica com uma chave RSA própria e roda os comandos do perfil compilado.
3. O cliente ADB (`Adb.java`) é adaptado do free-my-tv (MIT, licença em `bootclean/LICENSE-free-my-tv`).

## Perfis

O que o APK roda é fixado na compilação, a partir de `bootclean/profile/*.txt`; o `scripts/bootclean-profile.sh` gera o `Profile.java`. Nada pode ser acrescentado depois, de fora.

- `base.txt`: `force-stop` dos cinco pacotes da base.
- `personal.txt`: acrescenta o Assistente. Grava `assistant = dev.lucaswotta.homekey/.AssistActivity` (o botão do Assistente abre a Play Store, ver [08](08-controle.md)), esvazia `voice_interaction_service` e dá `force-stop` no `katniss`. O Android preenche os dois settings com o Katniss a cada boot, e enquanto ele é o Assistente registrado o sistema mantém vivo o processo `katniss:interactor`.

`scripts/build-launcher.sh` compila o perfil base; com `--personal`, o pessoal.

## O `tvrecommendations`

Ele subia no boot como ouvinte de notificações (`NotificationsService`). O sistema mantém uma conexão com todo ouvinte habilitado, então `force-stop` não adiantava. O `apply-all.sh` remove o ouvinte com `cmd notification disallow_listener com.google.android.tvrecommendations/com.google.android.tvrecommendations.NotificationsService`; `enabled_notification_listeners` fica vazio e sobrevive ao reboot, ao contrário do Assistente. O processo ainda sobe no boot, por uma consulta ao `NotificationContentProvider`, e o `bootclean` o para como aos outros. Para desfazer: `cmd notification allow_listener` com o mesmo componente.

## O que ele exige e o que custa

- Permissões: `INTERNET` (só para o socket em `127.0.0.1`; o código não abre outro endereço) e `RECEIVE_BOOT_COMPLETED`. Fica em APK separado do `homekey`, que vê todas as teclas e não tem permissões, para não juntar acesso à rede e leitura de teclas num pacote só.
- Depuração USB sempre ligada.
- Chave ADB autorizada de forma permanente. Na primeira execução a TV pergunta "Permitir depuração USB?": marque "Sempre permitir", com a TV acordada. Com o protetor de tela na frente, o aviso é negado sozinho.
- Comandos: só os do perfil compilado. O receptor é exportado e aceita a ação `dev.lucaswotta.bootclean.RUN`, que apenas agenda a mesma limpeza.
- Não impede a remoção de apps pela lista do `coreservice` ([03](03-coreservice.md)), que acontece nos primeiros ~35 s do boot, antes de o `bootclean` existir.

## Desfazer

```bash
scripts/personal.sh --undo              # se a camada pessoal estiver aplicada: devolve o Assistente e recompila com o perfil base
scripts/install-launcher.sh --remove    # desinstala launcher, homekey e bootclean
```

Depois, na TV: Opções do desenvolvedor, Revogar autorizações de depuração USB.

## Instalação

`scripts/build-launcher.sh` compila os três APKs; `scripts/install-launcher.sh` instala, liga os serviços de acessibilidade e dispara a primeira execução do `bootclean`.
