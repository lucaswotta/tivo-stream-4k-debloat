# 05 — Launcher

## Opções

| Launcher | Prós | Contras |
|---|---|---|
| **cleanyourtv** (`launcher/` do repo base, ~300 KB) | Sem rede, sem serviços, feito para 1 GB de RAM; remapeia botões do controle | Precisa compilar (JDK 17 + Android SDK) |
| **Projectivy** | Pronto na Play Store, bonito | Maior; era justamente o alvo do CoreService |
| **FLauncher** | Open source, leve | Menos manutenção |

Escolha inicial: o launcher do cleanyourtv, porque o PR fica coerente com o projeto base. Projectivy fica como plano B.

**Decisão final (2026-10-22): launcher próprio, `dev.lucaswotta.homelite`** (`launcher/`). 17 KB, sem permissões, sem biblioteca, sem rede; build sem Gradle com `launcher/build.sh`. Motivo: o do cleanyourtv tem 10,8 mil linhas, temas, vídeo de fundo e dois serviços; o do free-my-tv pede `INTERNET`. Custo se errado: manter um launcher; o `scripts/install-launcher.sh --remove` volta ao original.

## Como a tecla Home chega ao launcher

Três fatos medidos neste firmware (Android 12, build 1272):

1. `cmd package set-home-activity` responde `Success` e registra o papel HOME e a atividade preferida, mas a tecla Home continua abrindo o `tvlauncher`: o filtro dele tem `priority=2`, um app instalado não passa de 0 e o Android escolhe pela prioridade antes da preferência do usuário.
2. `pm disable-user`, `pm disable <componente>` e `uninstall --user 0` do `tvlauncher` são recusados, e as Configurações da TV não têm botão Desativar nele.
3. `com.nes.coreservice` desinstala, no boot, todo app não-sistema que declara a categoria HOME ([03](03-coreservice.md)).

Solução: o launcher **não declara HOME**. Um serviço de acessibilidade (`HomeKeyService`, só filtro de teclas, sem eventos de tela) abre a atividade por componente explícito quando a tecla Home real é pressionada e quando liga no boot. Custo: o serviço permanente, que cabe no processo de 21 MB do launcher.

- A tecla injetada por ADB (`input keyevent KEYCODE_HOME`) **não** passa pelo serviço e abre o `tvlauncher`; só vale o botão real do controle.
- `adb install -r` apaga a habilitação do serviço: use `scripts/install-launcher.sh`, que reabilita e confere.
- Um app não consegue parar processos de outros: `killBackgroundProcesses` é aceito e ignorado neste firmware. Por isso `scripts/post-boot.sh` (ADB) para `coreservice`, `sageservice` e `tvlauncher` depois de cada boot. O `tvrecommendations` é religado pelo sistema em 1 s e fica de fora.
- Armadilha de build: `d8` 8.2 (build-tools 34) aborta com classes internas não estáticas, anônimas ou ponte de `Comparator`.

## Pontos de atenção do TiVo (herdados dos primos SEI/NES)

- No Nokia 8000, o `tvlauncher` tem prioridade HOME 2 e não pôde ser desabilitado: `set-home-activity` diz Success e nada muda. **Testar isso cedo**, antes de investir no resto.
- Botões do controle (Netflix, Guide, Live, TiVo) provavelmente passam por `com.nes.tvglobalkeyhandler`. Ler os códigos com `adb shell getevent -lt` e mapear com `app_keys` no launcher.
- Proteção de tela: se o `backdrop` sair, apontar `screensaver_components` para o relógio do launcher.

## Verificação

- [x] Botão Home abre o launcher novo, inclusive depois de reboot (botão real, 2026-10-22)
- [ ] Botões Netflix / TiVo / Guide / Live fazem algo útil
- [ ] Microfone (Assistente) funciona, se mantido
- [ ] Wi-Fi volta sozinho depois do reboot
