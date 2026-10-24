# TiVo Stream 4K Debloat

[English](README.md)

![TiVo Stream 4K, controle e cabo](docs/img/aparelho.jpg)

Scripts que deixam o TiVo Stream 4K (Android TV 12) com um launcher leve, a tecla Home funcionando e sem os serviços da TiVo e da NES em segundo plano. Sem root e sem apagar nada do sistema: tudo se desfaz com um comando.

| De fábrica | Depois do `apply-all.sh` |
|---|---|
| ![Home de fábrica](docs/img/home-original.jpg) | ![Home depois](docs/img/home-base.png) |

## O que muda

- A tela inicial do Android TV, com linhas de recomendação e aba Loja, dá lugar ao launcher do [cleanyourtv](https://github.com/Gathin23/cleanyourtv): só os seus apps, 22 MB de memória contra 64 MB do original.
- A tecla Home do controle abre o launcher novo. Neste firmware nenhum launcher instalado assume a Home pelo caminho normal; aqui um serviço de acessibilidade de 13 KB faz isso.
- O `com.nes.coreservice`, que consulta o status de atualização uma vez por segundo e desinstala launchers alternativos, fica suspenso e parado.
- 14 pacotes de telemetria, recomendações e serviços da TiVo e da NES ficam suspensos.
- Depois de cada boot, o `bootclean` (17 KB) para os 5 processos que o sistema religa mesmo suspensos.

A memória livre vai de 920 MB para 1014 a 1151 MB. O processador, o boot (48 s) e a abertura dos apps continuam iguais.

## Requisitos

- TiVo Stream 4K `IPA1104HDW` com Android 12, build `SC.1272` (Configurações, Preferências do dispositivo, Sobre). Em outro build o script avisa e pergunta antes de seguir.
- Depuração USB ligada: em Sobre, 7 toques em Build; depois Opções do desenvolvedor, Depuração USB. A porta 5555 abre pela rede, sem cabo.
- Computador Linux x86_64 na mesma rede, com `adb`, `curl`, `python3`, `unzip`, `tar` e `git`, e 1,5 GB livres. O script baixa sozinho o JDK 17 e o Android SDK, de fontes oficiais e com checksum, para compilar os APKs.

## Instalação

```bash
git clone https://github.com/lucaswotta/tivo-stream-4k-debloat && cd tivo-stream-4k-debloat
export TV_HOST=192.168.0.50          # IP do seu TiVo
adb connect $TV_HOST:5555            # aceite o aviso na TV com "Sempre permitir"

scripts/apply-all.sh --dry-run       # mostra o plano sem alterar nada
scripts/apply-all.sh                 # explica, pergunta, aplica e confere
```

Durante a instalação o `bootclean` pede a autorização de depuração USB na TV: marque "Sempre permitir" com a TV acordada. No fim, aperte Home no controle, reinicie e rode `scripts/status.sh` uns 6 minutos depois do boot, quando o `bootclean` já rodou. As mensagens dos scripts são em inglês.

## O que você aceita ao aplicar

- O `bootclean` fica com uma chave de depuração USB autorizada para sempre e roda comandos fixos a cada boot, então a depuração USB precisa continuar ligada. Detalhes em [docs/pt-BR/10-bootclean.md](docs/pt-BR/10-bootclean.md).
- A cada boot, o `coreservice` desinstala o Downloader e outros 52 apps de uma lista de fábrica, além de todo app que declare a categoria HOME. Sem root não dá para impedir. Para instalar APKs, use `scripts/install-apk.sh <arquivo ou link>`. Detalhes em [docs/pt-BR/03-coreservice.md](docs/pt-BR/03-coreservice.md).
- Uma atualização de firmware pode desfazer parte das mudanças.

## Desfazer

Se aplicou a camada pessoal (fim desta página), rode antes `scripts/personal.sh --undo`.

```bash
scripts/rollback.sh examples/tivo-stream-4k/debloat.txt    # reativa os pacotes suspensos
scripts/install-launcher.sh --remove                       # remove launcher, serviço da Home e bootclean
```

## Medições

Mediana de 3 rodadas de `scripts/bench.sh`. Método e todas as rodadas em [docs/pt-BR/06-benchmark.md](docs/pt-BR/06-benchmark.md).

| Métrica | De fábrica | Depois |
|---|---|---|
| Memória livre (`MemAvailable`) | 920 MB | 1014 a 1151 MB |
| Memória do launcher (PSS) | 64 MB | 22 MB |
| Consultas de atualização do `coreservice` em 180 s | 180 | 0 |
| Quadros travados navegando no launcher | não medido | 3 em ~650 |

A coluna "de fábrica" já tinha 10 pacotes suspensos, que sozinhos não mudaram a memória. A abertura dos apps varia 400 a 630 ms entre medições iguais, então não entra como ganho.

## Como funciona

| Parte | O que faz | Nota |
|---|---|---|
| `examples/tivo-stream-4k/debloat.txt` | lista dos pacotes, por grupo, com o motivo de cada um | [04](docs/pt-BR/04-debloat.md) |
| `launcher/base/` | patch de uma linha no cleanyourtv: tira a categoria HOME para o `coreservice` não apagar o launcher | [05](docs/pt-BR/05-launcher.md) |
| `homekey/` | serviço de acessibilidade que leva a tecla Home ao launcher novo | [05](docs/pt-BR/05-launcher.md) |
| `bootclean/` | app que, depois do boot, se conecta ao ADB da própria TV e para os processos religados | [10](docs/pt-BR/10-bootclean.md) |
| `scripts/` | `apply-all.sh` aplica tudo; `status.sh` confere sem alterar; `apply.sh` e `rollback.sh` agem por grupo (`--only`) | |

Outras notas: [hardware](docs/pt-BR/00-hardware.md), [preparação](docs/pt-BR/01-preparacao.md), [inventário](docs/pt-BR/02-inventario.md), [`coreservice`](docs/pt-BR/03-coreservice.md), [keycodes do controle](docs/pt-BR/08-controle.md), [contribuições ao upstream](docs/pt-BR/07-upstream.md), [referências](docs/pt-BR/09-referencias.md) e o [diário](docs/pt-BR/diario.md), com data, comando e resultado de cada etapa.

## Limitações

- Testado em uma unidade, por um dia de uso e vários reboots.
- Só o build `SC.1272`. O Nokia Streaming Box 8000 e o Dialog ViU usam o mesmo fabricante (SEI Robotics) e o mesmo middleware (NES) e provavelmente se comportam igual, mas não foram testados.
- O script de instalação roda só em Linux.

## Créditos

- Launcher e formato das listas: [cleanyourtv](https://github.com/Gathin23/cleanyourtv) (MIT). A lista deste aparelho entrou lá pelo [PR #1061](https://github.com/Gathin23/cleanyourtv/pull/1061), e o comportamento do `coreservice` está na [issue #1062](https://github.com/Gathin23/cleanyourtv/issues/1062).
- Cliente ADB local do `bootclean`: [free-my-tv](https://github.com/simbasjungles/free-my-tv) (MIT, `bootclean/LICENSE-free-my-tv`).

## Por trás do projeto

Uso um TiVo Stream 4K no Brasil, onde o serviço da TiVo não funciona. Sobrava um Android TV lento, cheio de recomendações, e um firmware que apagava qualquer launcher que eu instalasse. Investigar por que o launcher sumia levou ao `coreservice`, e o resto saiu daí.

Depois da base, ajustei o aparelho ao meu gosto numa camada separada, `scripts/personal.sh` (`--undo` volta à base):

![Home com a camada pessoal](docs/img/home-personal.png)

- o app em foco cresce 10% na hora, com o anel de foco de fábrica e um título grande acima da dock;
- o botão TiVo abre o YouTube, o Guide abre as Configurações, e o Live abre um app de TV ao vivo que mantenho fora do repositório;
- o botão do Assistente abre a Play Store, e o Assistente do Google fica desligado.

Os botões e apps ficam em `examples/tivo-stream-4k/theme-personal/config.json`, ou numa pasta de tema sua, indicada por `PERSONAL_THEME` ([docs/pt-BR/05-launcher.md](docs/pt-BR/05-launcher.md#temas)).

## Licença

MIT. Suspender o pacote errado pode quebrar recursos: leia a lista antes de rodar.
