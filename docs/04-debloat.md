# 04 — Debloat em lotes

A lista é `examples/tivo-stream-4k/debloat.txt`, no formato do cleanyourtv (um pacote por linha, `#` para comentários). Os grupos dela viram os lotes.

## Ordem dos lotes

| Lote | Grupo | Risco |
|---|---|---|
| 1 | Telemetria e feedback (`feedback`, `partnersetup`, Privacy Sandbox) | baixo |
| 2 | CoreService (ver [03](03-coreservice.md)) | médio |
| 3 | Recomendações, auto-instalação de parceiros, `skywayclient` | médio |
| 4 | Apps pré-instalados que você não usa (Play Movies, Play Games, TalkBack, print spooler) | baixo |
| 5 | Launcher original (só depois do [05](05-launcher.md)) | alto |

## Ciclo de cada lote

```bash
scripts/apply.sh examples/tivo-stream-4k/debloat.txt --only "<nome do grupo>"
# testar com o controle: Home, voltar, volume, botão Netflix, microfone, YouTube, Netflix, Prime
adb reboot
# testar de novo depois do boot e anotar no docs/diario.md
```

## Se o firmware recusar `pm disable-user`

No Nokia 8000 (mesma família) o firmware responde `This command is illegal!`. O `apply.sh` detecta isso e cai para o plano B, por pacote:

```bash
pm suspend --user 0 <pkg>
cmd appops set <pkg> RUN_ANY_IN_BACKGROUND ignore
am force-stop <pkg>
```

É mais fraco (um receiver de boot ainda pode acordar), mas sobrevive a reboot.

## Ajustes globais (só se o benchmark pedir)

- Escala de animação 0.5×: `settings put global window_animation_scale 0.5` (idem `transition_` e `animator_duration_scale`).
- Limite de processos em segundo plano: Opções do desenvolvedor. **Não** usar "Não manter atividades".
- Restrição de background por app: `cmd appops set <pkg> RUN_ANY_IN_BACKGROUND ignore`.

## Atenção

- Atualização de firmware: se o serviço de OTA estiver desabilitado, o aparelho para de atualizar. Reabilite antes de procurar atualização e rode a lista de novo depois.
- Reset de fábrica: rode o `rollback.sh` antes, senão o assistente de configuração pode não abrir.
