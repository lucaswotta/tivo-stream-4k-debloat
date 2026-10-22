# 10 — Limpeza automática depois do boot

`bootclean` (`dev.lucaswotta.bootclean`, 17 KB) para os processos que o sistema religa em todo boot mesmo com o pacote suspenso, sem precisar de um computador.

## O problema

`pm suspend`, `appops` e `killBackgroundProcesses` (chamado por um app) não impedem o boot de religar `com.nes.coreservice`, `com.tivo.sageservice`, `com.google.android.tvlauncher`, `com.google.android.katniss` e `com.google.android.tvrecommendations`. Só `am force-stop` pelo shell os derruba, e o shell só existe no ADB. Esta build não tem permissão de início automático (`AUTO_START` e semelhantes não existem em `cmd appops`).

## O que ele faz

1. `BootReceiver` recebe `BOOT_COMPLETED` e agenda três execuções (`JobScheduler`) 60, 150 e 300 s depois, quando os serviços já subiram.
2. `CleanJob` conecta ao `adbd` da própria TV em `127.0.0.1:5555`, autentica com uma chave RSA própria e roda comandos fixos: limpa os settings `assistant` e `voice_interaction_service` (o Android os preenche com o Katniss a cada boot, e enquanto ele é o Assistente registrado o sistema mantém o processo `katniss:interactor` vivo) e dá `am force-stop` nos cinco pacotes.
3. O cliente ADB (`Adb.java`) é adaptado do `free-my-tv` (MIT, licença em `bootclean/LICENSE-free-my-tv`).

## O `tvrecommendations`

Ele subia no boot como **serviço de escuta de notificações** (`NotificationsService`): o sistema mantém uma conexão com todo ouvinte habilitado, por isso `force-stop` não adiantava. O ouvinte foi removido uma vez com `cmd notification disallow_listener com.google.android.tvrecommendations/com.google.android.tvrecommendations.NotificationsService`; `enabled_notification_listeners` ficou vazio e **sobreviveu ao reboot** (diferente do Assistente, que o Android refaz). Depois disso o processo ainda sobe no boot, agora por uma consulta ao provedor `NotificationContentProvider`, e o `bootclean` o para como aos outros. Para desfazer: `cmd notification allow_listener` com o mesmo componente.

## O que ele exige e o que custa

- **Permissões:** `INTERNET` (só para abrir o socket em `127.0.0.1`; o código não abre outro endereço) e `RECEIVE_BOOT_COMPLETED`. Ficou em APK separado do `homekey` (serviço de acessibilidade que vê todas as teclas, sem permissões) justamente para não juntar acesso à rede com leitura de teclas num pacote só.
- **Depuração USB sempre ligada**, como já está.
- **Chave ADB autorizada de forma permanente.** Na primeira execução a TV pergunta "Permitir depuração USB?": marque "Sempre permitir". O aviso é negado sozinho se o protetor de tela estiver na frente; rode com a TV acordada.
- **Comandos:** só os que estão em `CleanJob.java`; nada vem de fora. O receptor é exportado e aceita a ação `dev.lucaswotta.bootclean.RUN`, que apenas agenda a mesma limpeza.
- **Não impede** a remoção de apps pela lista do `coreservice` ([03](03-coreservice.md)), que acontece nos primeiros ~35 s do boot, antes da primeira execução.

## Desfazer

```bash
scripts/install-launcher.sh --remove    # desinstala também o bootclean
```

e, na TV, Opções do desenvolvedor > Revogar autorizações de depuração USB. Para o Assistente: `settings put secure assistant com.google.android.katniss/.search.serviceapi.KatnissVoiceInteractionService` e o mesmo em `voice_interaction_service`.

## Instalação

`scripts/build-launcher.sh` compila os três APKs; `scripts/install-launcher.sh` instala, liga os serviços de acessibilidade e dispara a primeira execução do `bootclean`.
