# 06 — Medições

[English](../06-benchmark.md)

Aparelho: TiVo Stream 4K, Android 12 build `SC.1272`, 2 GB de RAM. Medido em 2026-10-22, em uma unidade, com `scripts/bench.sh` (3 rodadas, mediana), salvo onde indicado. O bruto fica em `runs/`, fora do Git porque pode conter dados do aparelho; o [diário](diario.md) traz o comando e a hora de cada medição.

## Como ler os números

- Medidas com a TV em estados diferentes (recém-reiniciada ou ligada há horas) não são comparáveis. Cada linha diz o estado.
- A abertura a frio de um mesmo app varia muito entre medições idênticas: o launcher abriu entre 408 e 634 ms sem nenhuma mudança. Diferenças de 100 ms ou menos não significam nada.
- `MemAvailable` oscila uns 15 MB entre rodadas iguais.

## Memória e processos

| Estado | `MemAvailable` | Processos | PSS do launcher | YouTube | Netflix | Prime Video |
|---|---|---|---|---|---|---|
| Linha de base: de fábrica menos 7 apps que o dono já removera; ligada há horas, sem reboot | 976 MB | 314 | 104 MB | 507 ms | 529 ms | 785 ms |
| `sageservice` e `daemon` suspensos, sem reboot | 990 MB | 315 | 108 MB | 439 ms | 521 ms | 646 ms |
| 10 pacotes suspensos, `force-stop` em `coreservice` e `sageservice`, sem reboot | 1058 MB | 310 | 68 MB | 521 ms | 504 ms | 689 ms |
| Comparação limpa, 3 reboots, sem as suspensões | 905 MB | 332 | 60 MB | 668 ms | 694 ms | 1519 ms |
| Comparação limpa, 3 reboots, com as 10 suspensões | 920 MB | 330 | 64 MB | 673 ms | 775 ms | 1479 ms |
| Launcher do cleanyourtv, `post-boot.sh` | 1060 MB | 317 | 21 MB | 526 ms | 511 ms | 655 ms |
| + launcher original e Katniss parados | 1151 MB | 316 | 22 MB | 545 ms | 653 ms | 655 ms |
| Ciclo completo com `bootclean`, 6 min depois do boot | 1014 MB | n/d | n/d | n/d | n/d | n/d |
| Mesmo, benchmark logo depois | 1139 MB | 312 | 22 MB | 508 ms | 491 ms | 961 ms |

Leitura:

- Só suspender os 10 primeiros pacotes não deu ganho mensurável (905 contra 920 MB, na comparação limpa depois de reboot).
- A memória sobe quando o launcher original e `coreservice`, `sageservice`, `katniss` e `tvrecommendations` ficam parados: de ~920 MB para 1014 a 1151 MB, uns 100 a 200 MB.
- O PSS do launcher cai de 60 a 108 MB para 21 a 22 MB.
- A abertura a frio dos apps de streaming não melhorou de forma consistente. O 961 ms do Prime Video na última linha é a primeira abertura depois do boot.

## Atividade em segundo plano

| Medição | Antes | Depois |
|---|---|---|
| `ClearDataForGotaFun: getSystemUpdateStatus()` (consulta de atualização do `coreservice`) | 180 em 180 s | 0 em 90 s |
| Linhas de log por minuto do `com.nes.coreservice` | 61 | 0 |
| CPU em repouso | ~10% dos 4 núcleos | igual; sobram o serviço de áudio do fabricante (~26% de um núcleo, com o áudio em standby) e o `com.uei.uas.tivo` (~9%, QuickSet do controle, mantido porque liga a TV) |

## Interface

`dumpsys gfxinfo com.gathin.tvhome`, 24 toques de D-pad por passada, com 0,35 s entre eles:

| Condição | Quadros por passada | Quadros travados | p90 do quadro |
|---|---|---|---|
| Interface em 1080p | ~650 | 3 a 4 (0,46 a 0,61%) | 16 a 27 ms |
| Interface em 720p (`wm size 1280x720`, não aplicada) | ~650 | 0 | 11 ms |
| `reduced_motion` | ~125 | 0 a 5 | 15 a 23 ms |
| `reduced_motion` + `animations: false` + `focus_overshoot: false` + `module_cards: false` + `ambient_glow: false` | ~21 | 1 a 3 | 10 a 27 ms |

Os quadros travados ficam em ~3 por passada, nos movimentos verticais, e nenhuma opção de tema os remove. O estado final da camada pessoal (tema acima mais os 4 patches de `launcher/personal/`) não foi medido.

## O que o `scripts/bench.sh` mede

| Métrica | Como |
|---|---|
| Memória disponível | `MemAvailable` de `/proc/meminfo` |
| Processos | linhas de `ps -A` |
| Pacotes habilitados | `pm list packages -e` (suspender não desabilita, então não muda) |
| PSS do launcher | `dumpsys meminfo <launcher>` |
| Abertura a frio | `am force-stop` e `am start -W` (`TotalTime`) |
| Boot (`--boot`) | de `adb reboot` até `sys.boot_completed=1` |

```bash
scripts/bench.sh antes                       # 3 rodadas, sem reboot
scripts/bench.sh depois --boot               # reinicia a TV 3 vezes
HOME_CMD='am start -n com.gathin.tvhome/.MainActivity' HOME_PKG=com.gathin.tvhome scripts/bench.sh depois
```

Com o launcher novo, a tecla Home injetada por ADB ainda abre o original (só a tecla real passa pelo serviço), por isso `HOME_CMD` e `HOME_PKG`. O `force-stop` do launcher desliga os serviços de teclas: rode `scripts/push-theme.sh` depois.
