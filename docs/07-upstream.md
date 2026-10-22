# 07 — Contribuição para o cleanyourtv

Regras do upstream (CONTRIBUTING.md do Gathin23/cleanyourtv):

1. `examples/<marca>-<modelo>/debloat.txt` no formato do `xiaomi-mi-tv-4a`.
2. Cabeçalho com modelo exato, versão do Android e build (`tools/tv.py --probe`).
3. Só pacotes realmente desabilitados e usados por **alguns dias**. Anotar o que quebrou.
4. Uma linha em `examples/README.md`.
5. Nunca listar pacotes para desinstalar.

## Plano de PRs

| # | Conteúdo | Pré-requisito |
|---|---|---|
| PR 1 | `examples/tivo-stream-4k/` + linha no README de exemplos | Fase 5 concluída, ≥ 3 dias de uso |
| Issue | Propor melhorias (ex.: nota de família SEI/NES ligando Nokia, Dialog e TiVo) | PR 1 aceito |
| PR 2+ | Uma melhoria por PR, só com sinal verde na issue | Issue aprovada |

Fluxo:

```bash
gh repo fork Gathin23/cleanyourtv --clone
cd cleanyourtv && git checkout -b add-tivo-stream-4k
mkdir -p examples/tivo-stream-4k
cp ../tivo-stream-4k-lean/examples/tivo-stream-4k/debloat.txt examples/tivo-stream-4k/
# editar examples/README.md
git commit -am "Add TiVo Stream 4K (SEI Robotics, NES)" && gh pr create
```
