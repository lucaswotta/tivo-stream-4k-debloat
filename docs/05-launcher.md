# 05 — Launcher

## Opções

| Launcher | Prós | Contras |
|---|---|---|
| **cleanyourtv** (`launcher/` do repo base, ~300 KB) | Sem rede, sem serviços, feito para 1 GB de RAM; remapeia botões do controle | Precisa compilar (JDK 17 + Android SDK) |
| **Projectivy** | Pronto na Play Store, bonito | Maior; era justamente o alvo do CoreService |
| **FLauncher** | Open source, leve | Menos manutenção |

Escolha inicial: o launcher do cleanyourtv, porque o PR fica coerente com o projeto base. Projectivy fica como plano B.

## Pontos de atenção do TiVo (herdados dos primos SEI/NES)

- No Nokia 8000, o `tvlauncher` tem prioridade HOME 2 e não pôde ser desabilitado: `set-home-activity` diz Success e nada muda. **Testar isso cedo**, antes de investir no resto.
- Botões do controle (Netflix, Guide, Live, TiVo) provavelmente passam por `com.nes.tvglobalkeyhandler`. Ler os códigos com `adb shell getevent -lt` e mapear com `app_keys` no launcher.
- Proteção de tela: se o `backdrop` sair, apontar `screensaver_components` para o relógio do launcher.

## Verificação

- [ ] Botão Home abre o launcher novo, inclusive depois de reboot
- [ ] Botões Netflix / TiVo / Guide / Live fazem algo útil
- [ ] Microfone (Assistente) funciona, se mantido
- [ ] Wi-Fi volta sozinho depois do reboot
