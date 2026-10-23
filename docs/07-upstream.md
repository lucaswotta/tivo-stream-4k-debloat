# 07 — Contribuição para os repositórios de referência

## cleanyourtv (Gathin23/cleanyourtv)

Enviados em 2026-10-22, com a conta do dono do projeto:

| O quê | Link | Conteúdo |
|---|---|---|
| Pull request | [#1061](https://github.com/Gathin23/cleanyourtv/pull/1061) | `examples/tivo-stream-4k/` (`debloat.txt` suspenso, `README.md` com apply e undo, `theme/config.json` só com o dock) e as duas linhas nas tabelas |
| Issue | [#1062](https://github.com/Gathin23/cleanyourtv/issues/1062) | o `com.nes.coreservice` desinstala, no boot, todo app não-sistema que declare HOME e uma lista de 53 pacotes; o que funcionou e o que não foi testado |

O texto de cada um está em `upstream/pr-1061-body.md` e `upstream/issue-1062-body.md`. O patch do PR (commit `f85f700` do branch `add-tivo-stream-4k` do fork `lucaswotta/cleanyourtv`, sobre o `30626a8` do upstream) está em [`upstream/`](upstream/).

O PR vai com a ressalva dita no corpo dele: o `CONTRIBUTING.md` pede pacotes usados por "alguns dias" e aqui foi um dia, com cerca de dez reboots; os mantenedores podem pausar até haver mais uso. Com ele aplicado, `python3 -m unittest discover -s tests` do cleanyourtv passa (540 testes, 3 pulados). O que o PR não leva: nada de `pm uninstall` (os apps que o dono já removera são comentários), e as escolhas pessoais (botões, animações, Assistente) ficam só neste repositório.

Regras do upstream que o PR segue (`CONTRIBUTING.md` e `AGENTS.md` deles): `examples/<marca>-<modelo>/debloat.txt` no formato do `xiaomi-mi-tv-4a`; cabeçalho com modelo, Android e build; uma linha em `examples/README.md` e uma na tabela de TVs do `README.md` com o mesmo texto; nada para desinstalar; sem scripts de instalação na pasta.

## free-my-tv (simbasjungles/free-my-tv)

Nada enviado. O `Adb.java` deles é a base do cliente ADB local do `bootclean`, com a licença MIT copiada em `bootclean/LICENSE-free-my-tv`. Uma nota possível, **não testada**: em aparelhos com o `com.nes.coreservice` da NES, o app deles declara HOME e provavelmente seria desinstalado no boot pela mesma lista.
