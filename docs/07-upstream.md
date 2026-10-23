# 07 — Contribuição para os repositórios de referência

Nada abaixo foi publicado. São rascunhos para o dono do projeto revisar e enviar com a conta dele. Abrir PR ou issue em repositório de terceiros fala em nome de quem envia.

## cleanyourtv (Gathin23/cleanyourtv)

Regras do upstream (`CONTRIBUTING.md` e `AGENTS.md` deles): `examples/<marca>-<modelo>/debloat.txt` no formato do `xiaomi-mi-tv-4a`; cabeçalho com modelo exato, Android e build; só pacotes usados por alguns dias; **nenhum `pm uninstall` na lista**; sem scripts de instalação na pasta; uma linha em `examples/README.md` e uma na tabela de TVs do `README.md` (com o mesmo texto); `python3 -m unittest discover -s tests` passando; não editar `PROMPT.md`, os guardas de `disable.sh` nem `.github/workflows/`.

### Estado: pronto e testado localmente, **não enviado**

O PR 1 está montado como um patch sobre o commit `30626a8` do cleanyourtv: [`upstream/0001-examples-add-TiVo-Stream-4K-SEI-Robotics-Amlogic-S90.patch`](upstream/). Com ele aplicado, `python3 -m unittest discover -s tests` do cleanyourtv passa (540 testes, 3 pulados).

Por que ainda não foi enviado: o `CONTRIBUTING.md` deles pede "only list packages you have actually disabled and lived with for a few days". O uso aqui foi de **um dia**, em uma unidade, então o bot de revisão deles provavelmente marcaria como `hold`. Enviar antes gasta a atenção dos mantenedores. Sugestão: usar a TV por pelo menos 3 dias, anotar no README da pasta o que quebrou ou foi reativado e então enviar.

Para enviar depois:

```bash
gh repo fork Gathin23/cleanyourtv --clone && cd cleanyourtv
git checkout -b add-tivo-stream-4k
git am ../tivo-stream-4k-debloat/docs/upstream/0001-*.patch   # se o upstream avançou: git am -3
python3 -m unittest discover -s tests
git push -u origin add-tivo-stream-4k && gh pr create --fill
```

### PR 1: lista do aparelho

Título: `examples: add TiVo Stream 4K (SEI Robotics, Amlogic, NES), Android TV 12`

Corpo:

> TiVo Stream 4K `IPA1104HDW`, build `SC.1272`, Android 12 (SDK 31). Testado em uma unidade por um dia, com vários reboots.
>
> Mesma família SEI/NES do Nokia Streaming Box 8000: `pm disable-user` é recusado, então a lista é suspensa (`pm suspend` mais `appops`, como em `examples/nokia-streaming-box-8000/README.md`). O `README.md` da pasta traz o apply e o undo. Nenhum `pm uninstall` na lista; os apps que o dono já tinha removido ficam como comentário.
>
> Mantidos de propósito: `uei.uas.tivo` (liga a TV pelo controle), `sei.hdmi.services`, `nes.tivo.remote.*`, `mediashell`.
>
> Tested on: TiVo Stream 4K, Android 12, `SC.1272`.

Para enviar, adaptar `examples/tivo-stream-4k/debloat.txt` ao formato deles (comentar as linhas de "Already removed by the owner", tirar as variáveis `scripts/` do cabeçalho e apontar para os comandos do `README.md` da pasta) e acrescentar as linhas nas duas tabelas.

### Comentário ou issue: a lista de remoção da NES

Título: `NES firmware (TiVo Stream 4K, probably Nokia 8000 and Dialog ViU): com.nes.coreservice uninstalls every non-system app that declares HOME`

Corpo:

> On a TiVo Stream 4K (SEI/NES, Android 12), `com.nes.coreservice` runs `EvoBlackListAppsFun` at every start. It calls `AppUtil.uninstallAsUser` on every non-system app whose activity declares `android.intent.category.HOME`, and on a fixed list of 53 packages from `array/evo_black_list_to_uninstall_pkgs` in its `resources.arsc` (alternative launchers, Downloader, Magisk, IPTV "Magis TV" variants). The service starts from its `BootReceiver`, kicked by the persistent `com.nes.daemon`, even when the package is suspended or force-stopped.
>
> What worked: a launcher that does not declare HOME (one line out of `MainActivity`'s intent filter), opened by component from a small accessibility service on the Home key. The launcher survived 4 reboots with `coreservice` running. A package that does declare HOME was uninstalled twice at boot.
>
> Not tested by me on the Nokia 8000 or the Dialog ViU, and not tested with an unpatched cleanyourtv launcher; I infer from the shared middleware that they behave the same.
>
> Details, resource name and the log lines: https://github.com/lucaswotta/tivo-stream-4k-debloat/blob/main/docs/03-coreservice.md

## free-my-tv (simbasjungles/free-my-tv)

Nada para enviar. Uma nota possível, **não testada**: em aparelhos com o `com.nes.coreservice` da NES, o app declara HOME e provavelmente seria desinstalado no boot pela mesma lista. O `Adb.java` deles é a base do cliente ADB local do `bootclean`, com a licença MIT copiada em `bootclean/LICENSE-free-my-tv`.
