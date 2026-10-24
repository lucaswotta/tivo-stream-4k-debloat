# 07 — Contribuição para os repositórios de referência

[English](../07-upstream.md)

## cleanyourtv (Gathin23/cleanyourtv)

| O quê | Link | Conteúdo | Estado |
|---|---|---|---|
| Pull request | [#1061](https://github.com/Gathin23/cleanyourtv/pull/1061) | `examples/tivo-stream-4k/` (`debloat.txt`, `README.md` com aplicar e desfazer, `theme/config.json` só com a dock) e as linhas nas tabelas de aparelhos | enviado em 2026-10-22, mergeado em 2026-10-23 |
| Issue | [#1062](https://github.com/Gathin23/cleanyourtv/issues/1062) | o `com.nes.coreservice` desinstala no boot todo app não-sistema que declare HOME e uma lista de 53 pacotes | aberta |

No merge, o mantenedor comentou o grupo do launcher original no `debloat.txt` de lá, com uma nota: o launcher do cleanyourtv ainda não responde à tecla Home neste aparelho, e o README de lá manda descomentar o grupo só quando outro launcher responder. Na issue, o mantenedor pediu um PR que leve o achado às notas dos aparelhos TiVo/NES e ao README do Nokia 8000, marcado como "não testado lá". Esse PR ainda não foi feito.

O texto enviado está em [`../upstream/pr-1061-body.md`](../upstream/pr-1061-body.md) e [`../upstream/issue-1062-body.md`](../upstream/issue-1062-body.md). O patch do PR (commit `f85f700` da branch `add-tivo-stream-4k` do fork `lucaswotta/cleanyourtv`, sobre o `30626a8` do upstream) está em [`../upstream/`](../upstream/).

O PR foi enviado com uma ressalva no corpo: o `CONTRIBUTING.md` deles pede pacotes usados por "alguns dias", e aqui foi um dia com vários reboots. Com ele aplicado, `python3 -m unittest discover -s tests` do cleanyourtv passa (540 testes, 3 pulados). O PR não leva `pm uninstall` (os apps que o dono já removera ficam como comentários) nem as escolhas pessoais (botões, animações, Assistente).

Regras do upstream que o PR segue (`CONTRIBUTING.md` e `AGENTS.md`): `examples/<marca>-<modelo>/debloat.txt` no formato do `xiaomi-mi-tv-4a`; cabeçalho com modelo, Android e build; uma linha em `examples/README.md` e uma na tabela de TVs do `README.md`, com o mesmo texto; nada para desinstalar; sem scripts de instalação na pasta.

## free-my-tv (simbasjungles/free-my-tv)

Nada enviado. O `Adb.java` deles é a base do cliente ADB local do `bootclean`, com a licença MIT copiada em `bootclean/LICENSE-free-my-tv`. Uma nota possível, não testada: em aparelhos com o `com.nes.coreservice`, o app deles declara HOME e provavelmente seria desinstalado no boot pela mesma regra.
